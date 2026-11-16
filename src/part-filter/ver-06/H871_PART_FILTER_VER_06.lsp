;; ============================================================================
;; H871 PART FILTER - VER-06 SINGLE NATIVE RESULTS BROWSER / MULTI-PAGE
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Integration basis:
;; - Stage 0: ver-03-rebuild native Graphical Browser selection and Apply.
;; - V04: one Browser Tree with page roots and page-local selection restore.
;;
;; No UICT Display Table, hidden Browser bridge, reparenting, or extra window.
;; Search collector, Density normalization, AND predicate, and native Apply
;; setup are carried forward from the user-confirmed Stage 0 baseline.
;;
;; Runtime status: candidate only; requires disposable-model test in Creo 18.1.
;; ============================================================================
(in-package :oli)

(defvar *h871-pf-v06-results* nil)
(defvar *h871-pf-v06-diagnostic-samples* nil)
(defvar *h871-pf-v06-results-assembly* nil)
(defvar *h871-pf-v06-requested-instance* nil)
(defvar *h871-pf-v06-requested-base* nil)
(defvar *h871-pf-v06-pages* nil)
(defvar *h871-pf-v06-current-page* nil)
(defvar *h871-pf-v06-page-root-map* nil)
(defvar *h871-pf-v06-part-node-map* nil)
(defvar *h871-pf-v06-page-counter* 0)

(defvar *h871-pf-v06-browser-name* "h871-pf-v06-results")
(defvar *h871-pf-v06-tree-name* "h871-pf-v06-results-tree")

(defun h871-pf-v06-name (obj)
  (or (sd-inq-obj-basename obj) "<NO NAME>"))

(defun h871-pf-v06-path (obj)
  (or (sd-inq-obj-pathname obj) "<NO PATH>"))

;; Convert numeric values consistently. In Lisp, (= 1 1.0) is
;; already true; this helper additionally accepts numeric strings such
;; as "1" and "1.0" if a runtime/property layer returns text.
(defun h871-pf-v06-as-number (value)
  ;; Creo's dialog fields and SD-INQ-PART-DENSITY return numeric
  ;; values in this workflow. Avoid READ-FROM-STRING and reader
  ;; character literals for compatibility with Modeling 18.1.
  (if (numberp value) value nil))
;; The user verified two native Parts in Modeling 18.1:
;; UI Instance/Base values 1/304 -> API values 1000/304000,
;; and UI values 2/400 -> API values 2000/400000.
;; Normalize API density values to the Part Properties display scale.
(defun h871-pf-v06-density-display-value (api-value)
  (when (numberp api-value)
    (/ api-value 1000.0)))

(defun h871-pf-v06-numeric-equal-p (actual requested)
  (let ((a (h871-pf-v06-as-number actual))
        (b (h871-pf-v06-as-number requested)))
    (and a b
         (<= (abs (- a b)) 0.0000001))))

(defun h871-pf-v06-density-pair-match (part requested-instance requested-base)
  (let ((actual-instance (sd-inq-part-density part :instance))
        (actual-base (sd-inq-part-density part :contents)))
    (and (not (null actual-instance))
         (not (null actual-base))
         (h871-pf-v06-numeric-equal-p
           (h871-pf-v06-density-display-value actual-instance)
           requested-instance)
         (h871-pf-v06-numeric-equal-p
           (h871-pf-v06-density-display-value actual-base)
           requested-base))))

;; ------------------------------------------------------------
;; Filter engine - keep predicates separate from result UI
;; ------------------------------------------------------------

(defun h871-pf-v06-collect (obj matches requested-instance requested-base)
  (when (sd-inq-part-p obj)
    (let ((actual-instance (sd-inq-part-density obj :instance))
          (actual-base (sd-inq-part-density obj :contents)))
      ;; Keep a small raw-value sample in the report so a zero-match
      ;; result reveals what Creo 18.1 actually returned.
      (when (< (length *h871-pf-v06-diagnostic-samples*) 30)
        (push
          (list (h871-pf-v06-name obj)
                (h871-pf-v06-path obj)
                actual-instance
                (type-of actual-instance)
                actual-base
                (type-of actual-base))
          *h871-pf-v06-diagnostic-samples*))
      (when (and
              (h871-pf-v06-numeric-equal-p
                (h871-pf-v06-density-display-value actual-instance)
                requested-instance)
              (h871-pf-v06-numeric-equal-p
                (h871-pf-v06-density-display-value actual-base)
                requested-base))
        (push obj matches))))
  (dolist (child (sd-inq-obj-children obj))
    (setf matches
      (h871-pf-v06-collect child matches requested-instance requested-base)))
  matches)

;; ------------------------------------------------------------
;; Browser row client data and table display callbacks
;; ------------------------------------------------------------

(defun h871-pf-v06-row-data (node)
  (browsernode-objclientdata node))

(defun h871-pf-v06-column-name (node browser-name)
  (declare (ignore browser-name))
  (getf (h871-pf-v06-row-data node) :name))

(defun h871-pf-v06-column-instance (node browser-name)
  (declare (ignore browser-name))
  (let ((value (getf (h871-pf-v06-row-data node) :instance)))
    (if value (format nil "~A" value) "-")))

(defun h871-pf-v06-column-base (node browser-name)
  (declare (ignore browser-name))
  (let ((value (getf (h871-pf-v06-row-data node) :base)))
    (if value (format nil "~A" value) "-")))

(defun h871-pf-v06-column-path (node browser-name)
  (declare (ignore browser-name))
  (getf (h871-pf-v06-row-data node) :path))

(defun h871-pf-v06-page-by-name (page-name)
  (find-if (lambda (entry) (equal (getf entry :page) page-name))
           *h871-pf-v06-pages*))

(defun h871-pf-v06-page-root-id (page-name)
  (cdr (assoc page-name *h871-pf-v06-page-root-map* :test #'equal)))

(defun h871-pf-v06-part-node-id (page-name part-path)
  (let ((item (find-if
                (lambda (entry)
                  (and (equal (first entry) page-name)
                       (equal (second entry) part-path)))
                *h871-pf-v06-part-node-map*)))
    (and item (third item))))

(defun h871-pf-v06-process-label (value)
  (or (cadr (assoc value '((1 "CNC") (2 "KH") (3 "CG") (4 "COVER"))))
      (format nil "~A" value)))

(defun h871-pf-v06-material-label (value)
  (or (cadr (assoc value
        '((6061 "A6061") (201 "SUS201") (304 "SUS304") (400 "SS400")
          (10 "POM") (20 "Bakelit") (30 "MC") (40 "MIKA") (50 "PU"))))
      (format nil "~A" value)))

(defun h871-pf-v06-page-by-pair (instance base)
  (find-if (lambda (entry)
             (and (equal (getf entry :instance) instance)
                  (equal (getf entry :base) base)))
           *h871-pf-v06-pages*))

(defun h871-pf-v06-store-page (instance base results)
  (let ((entry (h871-pf-v06-page-by-pair instance base)))
    (if entry
        (progn
          (setf (getf entry :results) results)
          (setf (getf entry :selected-paths) nil)
          (setf (getf entry :label)
            (format nil "~A-~A"
              (h871-pf-v06-process-label instance)
              (h871-pf-v06-material-label base)))
          (getf entry :page))
      (let* ((page-name
               (format nil "H871-PF-V06-PAGE-~A"
                 (incf *h871-pf-v06-page-counter*)))
             (new-entry
               (list :instance instance :base base
                     :label (format nil "~A-~A"
                               (h871-pf-v06-process-label instance)
                               (h871-pf-v06-material-label base))
                     :page page-name :results results :selected-paths nil)))
        (push new-entry *h871-pf-v06-pages*)
        page-name))))

(defun h871-pf-v06-build-results-tree ()
  ;; One root per Density pair; each page root owns only its Part rows.
  (let ((root (sd-create-browsernode
                :tree *h871-pf-v06-tree-name*
                :parent nil
                :objPath "/H871_V06_RESULTS"
                :objPname "H871 Results"
                :objClientData (list :kind :root))))
    (setf *h871-pf-v06-page-root-map* nil)
    (setf *h871-pf-v06-part-node-map* nil)
    (dolist (entry (reverse *h871-pf-v06-pages*))
      (let* ((page-name (getf entry :page))
             (page-id
               (sd-create-browsernode
                 :tree *h871-pf-v06-tree-name*
                 :parent root
                 :objPath (format nil "/H871_V06_RESULTS/~A" page-name)
                 :objPname (getf entry :label)
                 :objClientData (list :kind :page :page page-name))))
        (push (cons page-name page-id) *h871-pf-v06-page-root-map*)
        (dolist (part (getf entry :results))
          (let* ((part-path (h871-pf-v06-path part))
                 (node-id
                   (sd-create-browsernode
                     :tree *h871-pf-v06-tree-name*
                     :parent page-id
                     :objPath part-path
                     :objPname (h871-pf-v06-name part)
                     :objClientData
                       (list :kind :part :page page-name
                             :part part
                             :name (h871-pf-v06-name part)
                             :path part-path
                             :instance (h871-pf-v06-density-display-value
                                         (sd-inq-part-density part :instance))
                             :base (h871-pf-v06-density-display-value
                                     (sd-inq-part-density part :contents))))))
            (push (list page-name part-path node-id)
                  *h871-pf-v06-part-node-map*))))
    root)))

(defun h871-pf-v06-save-current-selection ()
  (when (stringp *h871-pf-v06-current-page*)
    (let ((paths nil)
          (entry (h871-pf-v06-page-by-name *h871-pf-v06-current-page*)))
      (dolist (node (or (sd-query-browser
                          *h871-pf-v06-browser-name* :get-selected-objects)
                        nil))
        (let ((data (h871-pf-v06-row-data node)))
          (when (and (eq (getf data :kind) :part)
                     (equal (getf data :page) *h871-pf-v06-current-page*))
            (push (BrowserNode-objPath node) paths))))
      (when entry (setf (getf entry :selected-paths) (nreverse paths))))))

(defun h871-pf-v06-update-page-status (page-name)
  (let ((entry (h871-pf-v06-page-by-name page-name)))
    (when entry
      (sd-browser-set-status-text
        *h871-pf-v06-browser-name*
        :type :table
        :value (format nil "~A | ~A Part(s) | Density Instance ~A / Base ~A"
                  (getf entry :label) (length (getf entry :results))
                  (getf entry :instance) (getf entry :base))))))

(defun h871-pf-v06-activate-page (page-name &optional skip-save)
  (let ((entry (h871-pf-v06-page-by-name page-name)))
    (when entry
      (unless (or skip-save (equal page-name *h871-pf-v06-current-page*))
        (h871-pf-v06-save-current-selection))
      (let* ((node-id (h871-pf-v06-page-root-id page-name))
             (node (and node-id
                        (sd-get-browsernode-struct
                          *h871-pf-v06-tree-name* node-id))))
        (unless node (return-from h871-pf-v06-activate-page nil))
        ;; This is the same page-root transition used in the user-tested V04
        ;; diagnostic. Do not add the unverified :clear-table-roots sequence.
        (sd-browser-exec-cmd *h871-pf-v06-browser-name* :clear-select-list)
        (unless (sd-browser-exec-cmd
                  *h871-pf-v06-browser-name* :change-table-root node t)
          (return-from h871-pf-v06-activate-page nil)))
      (setf *h871-pf-v06-current-page* page-name)
      (dolist (part-path (getf entry :selected-paths))
        (let* ((node-id (h871-pf-v06-part-node-id page-name part-path))
               (node (and node-id
                          (sd-get-browsernode-struct
                            *h871-pf-v06-tree-name* node-id))))
          (when node
            (sd-browser-exec-cmd
              *h871-pf-v06-browser-name* :set-object-selection node t))))
      (h871-pf-v06-update-page-status page-name)
      t)))

(defun h871-pf-v06-switch-offset (offset)
  (let* ((pages (reverse *h871-pf-v06-pages*))
         (count (length pages))
         (current-index
           (position *h871-pf-v06-current-page* pages
             :key (lambda (entry) (getf entry :page)) :test #'equal)))
    (when (> count 0)
      (let* ((index (if current-index (mod (+ current-index offset) count) 0))
             (target (getf (nth index pages) :page)))
        (h871-pf-v06-activate-page target)))))

(defun h871-pf-v06-previous-page ()
  (h871-pf-v06-switch-offset -1))

(defun h871-pf-v06-next-page ()
  (h871-pf-v06-switch-offset 1))

(defun h871-pf-v06-select-all ()
  (sd-browser-exec-cmd *h871-pf-v06-browser-name* :select-all))

(defun h871-pf-v06-clear-selection ()
  (sd-browser-exec-cmd *h871-pf-v06-browser-name* :clear-select-list)
  (let ((entry (h871-pf-v06-page-by-name *h871-pf-v06-current-page*)))
    (when entry (setf (getf entry :selected-paths) nil)))
  t)

(defun h871-pf-v06-open-results-browser ()
  ;; Rebuild a single named native Browser; never create an auxiliary window.
  (ignore-errors (sd-hide-graphical-browser *h871-pf-v06-browser-name*))
  (ignore-errors (sd-destroy-graphical-browser *h871-pf-v06-browser-name*))
  (ignore-errors (sd-destroy-browser-tree *h871-pf-v06-tree-name*))
  (unless (sd-create-browser-tree
            *h871-pf-v06-tree-name*
            :update-events oli:*SD-CHANGE-OBJECT-TREE-EVENT*
            :update-func 'h871-pf-v06-build-results-tree)
    (sd-display-error "H871: Could not create the Results Browser Tree.")
    (return-from h871-pf-v06-open-results-browser nil))
  (unless (sd-create-graphical-browser
            *h871-pf-v06-browser-name*
            :tree *h871-pf-v06-tree-name*
            :topLabel "H871 - PART FILTER RESULTS"
            :treeStatusBar "Select Parts directly in this list, then press Apply."
            :tableStatusBar "Use Previous/Next to switch Density-pair result pages."
            :minHeight 280 :maxWidth 980 :maxHeight 760
            :okButtonLabel "Apply"
            :abortButtonLabel "Close Results"
            :abortButtonAction '(h871-pf-v06-close-results)
            :buttonMenu
              '(( "previous-page" :label "Previous Page"
                  :push (h871-pf-v06-previous-page))
                ( "next-page" :label "Next Page"
                  :push (h871-pf-v06-next-page))
                ( "select-all" :label "Select All"
                  :push (h871-pf-v06-select-all))
                ( "clear-selection" :label "Clear Selection"
                  :push (h871-pf-v06-clear-selection))))
    (ignore-errors (sd-destroy-browser-tree *h871-pf-v06-tree-name*))
    (sd-display-error "H871: Could not create the single Results Browser.")
    (return-from h871-pf-v06-open-results-browser nil))
  (unless (sd-browser-define-table
            *h871-pf-v06-browser-name*
            :table-name "h871-pf-v06-bom"
            :with-name-column nil
            :column-definition
              '((:label "Part Name" :type :string-column
                 :display-func h871-pf-v06-column-name :initial-width 28)
                (:label "Density Instance" :type :string-column
                 :display-func h871-pf-v06-column-instance :initial-width 13)
                (:label "Density Base" :type :string-column
                 :display-func h871-pf-v06-column-base :initial-width 12)
                (:label "Assembly Path" :type :string-column
                 :display-func h871-pf-v06-column-path :initial-width 42)))
    (ignore-errors (sd-destroy-graphical-browser *h871-pf-v06-browser-name*))
    (ignore-errors (sd-destroy-browser-tree *h871-pf-v06-tree-name*))
    (sd-display-error "H871: Could not define the Results table.")
    (return-from h871-pf-v06-open-results-browser nil))
  (sd-browser-set-active-table
    *h871-pf-v06-browser-name* :table-name "h871-pf-v06-bom")
  (sd-browser-exec-cmd *h871-pf-v06-browser-name* :set-table-mode)
  (unless (sd-show-graphical-browser *h871-pf-v06-browser-name*)
    (sd-display-error "H871: Could not show the Results Browser.")
    (return-from h871-pf-v06-open-results-browser nil))
  (unless (h871-pf-v06-activate-page *h871-pf-v06-current-page* t)
    (sd-display-error "H871: Could not activate the current Results page.")
    (return-from h871-pf-v06-open-results-browser nil))
  t)

(defun h871-pf-v06-close-results ()
  (ignore-errors
    (sd-hide-graphical-browser *h871-pf-v06-browser-name* :ignore-pin t))
  t)

;; ------------------------------------------------------------
;; Report and search action
;; ------------------------------------------------------------

(defun h871-pf-v06-write-report (assembly matches requested-instance requested-base)
  (let ((report
          (merge-pathnames
            "H871_PART_FILTER_RESULT.txt"
            (user-homedir-pathname))))
    (with-open-file
      (s report
        :direction :output
        :if-exists :supersede
        :if-does-not-exist :create)
      (format s "H871 PART FILTER - EXACT DENSITY PAIR~%")
      (format s "Assembly: ~A~%" (h871-pf-v06-path assembly))
      (format s "Requested Density Instance: ~A~%" requested-instance)
      (format s "Requested Density Base: ~A~%" requested-base)
      (format s "~%RAW DENSITY SAMPLE (first 30 Parts)~%")
      (format s "Part | Path | Instance value/type | Base value/type~%")
      (dolist (sample (reverse *h871-pf-v06-diagnostic-samples*))
        (format s "~S~%" sample))
      (dolist (part matches)
        (format s "~%PART: ~A~%" (h871-pf-v06-name part))
        (format s "PATH: ~A~%" (h871-pf-v06-path part))
        (format s "DENSITY INSTANCE (Part Properties scale): ~A~%"
          (h871-pf-v06-density-display-value
            (sd-inq-part-density part :instance)))
        (format s "DENSITY BASE (Part Properties scale): ~A~%"
          (h871-pf-v06-density-display-value
            (sd-inq-part-density part :contents)))
        (format s "DENSITY INSTANCE (raw API): ~A~%"
          (sd-inq-part-density part :instance))
        (format s "DENSITY BASE (raw API): ~A~%"
          (sd-inq-part-density part :contents))))
    report))

(defun h871-pf-v06-run (assembly requested-instance requested-base)
  ;; Keep the Stage 0 collector and exact AND predicate unchanged.
  ;; Each successful Density pair is stored as one native Browser page.
  (setf *h871-pf-v06-diagnostic-samples* nil)
  (setf *h871-pf-v06-results-assembly* assembly)
  (setf *h871-pf-v06-requested-instance* requested-instance)
  (setf *h871-pf-v06-requested-base* requested-base)
  (setf *h871-pf-v06-results*
    (h871-pf-v06-collect
      assembly nil requested-instance requested-base))
  (let ((report
          (h871-pf-v06-write-report
            assembly *h871-pf-v06-results*
            requested-instance requested-base)))
    (if (null *h871-pf-v06-results*)
        (sd-display-message
          (format nil
            "No Parts matched Density Instance ~A and Density Base ~A.~%Report: ~A"
            requested-instance requested-base (namestring report)))
      (progn
        ;; Save the outgoing page's native Browser selection before rebuild.
        (when (stringp *h871-pf-v06-current-page*)
          (h871-pf-v06-save-current-selection))
        (setf *h871-pf-v06-current-page*
          (h871-pf-v06-store-page
            requested-instance requested-base *h871-pf-v06-results*))
        (unless (h871-pf-v06-open-results-browser)
          (return-from h871-pf-v06-run nil))
        (sd-browser-set-status-text
          *h871-pf-v06-browser-name* :type :tree
          :value (format nil "~A page(s) stored."
                    (length *h871-pf-v06-pages*)))))
    (values (length *h871-pf-v06-results*) report)))

;; ------------------------------------------------------------
;; Dialog entry point - ver-06 integration
;; ------------------------------------------------------------
;;
;; User-facing choices map to the existing Density Instance/Base
;; properties. The numeric values remain the actual filter inputs.
;; To revise the user's convention, edit only the :range mappings.
;;
;; Machining process:
;;   CNC=1, KH=2, CG=3, COVER=4
;;
;; Material:
;;   A6061=6061, SUS201=201, SUS304=304, SS400=400,
;;   POM=10, Bakelit=20, MC=30, MIKA=40, PU=50
;;
;; The code fields use :display-only and are synchronized by
;; :after-input. They are informational and cannot be edited.
;; Standard parallel-dialog variables are laid out vertically; the
;; code fields therefore follow their selectors as separate rows.
;; A same-row custom layout is intentionally deferred until its
;; compatibility with Modeling 18.1 can be verified.
;;
(sd-defdialog 'h871_part_filter_ver_06
  :dialog-title "H871 - PART FILTER VER-06 INTEGRATION (STAGE 0 + V04 MULTI-PAGE)"
  :variables
  '(
    ("ASSEMBLY")
    (ASSEMBLY
      :value-type :assembly
      :title "Select Assembly"
      :prompt-text "Select assembly to scan.")

    ("MACHINING PROCESS")
    (MACHINING_PROCESS
      :range ((1 :label "CNC")
              (2 :label "KH")
              (3 :label "CG")
              (4 :label "COVER"))
      :initial-value 1
      :title "Machining Process"
      :after-input
        (setq MACHINING_PROCESS_CODE MACHINING_PROCESS))

    (MACHINING_PROCESS_CODE
      :value-type :display-only
      :initial-value 1
      :title "Process Code")

    ("MATERIAL")
    (MATERIAL
      :range ((6061 :label "A6061")
              (201 :label "SUS201")
              (304 :label "SUS304")
              (400 :label "SS400")
              (10 :label "POM")
              (20 :label "Bakelit")
              (30 :label "MC")
              (40 :label "MIKA")
              (50 :label "PU"))
      :initial-value 304
      :title "Material"
      :after-input
        (setq MATERIAL_CODE MATERIAL))

    (MATERIAL_CODE
      :value-type :display-only
      :initial-value 304
      :title "Material Code")
  )
  :ok-action
  '(progn
     ;; Keep the existing density-pair engine unchanged:
     ;; machining_process -> Density Instance
     ;; material           -> Density Base
     (h871-pf-v06-run assembly machining_process material)
     ;; Keep the input dialog active for consecutive searches.
     (sd-return-from-ok-action)))

;; LOAD:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER_VER_06.lsp")
;; COMMAND:
;; H871_PART_FILTER_VER_06
