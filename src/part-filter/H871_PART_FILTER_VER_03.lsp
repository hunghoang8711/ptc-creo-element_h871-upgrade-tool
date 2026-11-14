;; ============================================================
;; H871 PART FILTER - Independent Results Browser Sessions - VER-03
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Search UI: machining process + material convention.
;; Each search owns a unique result session, Browser and Browser Tree.
;; Browser sessions are requested as docked tabs with unique tab labels.
;; Native row selection and Apply are preserved per Browser.
;;
;; IMPORTANT:
;; Graphical Browser APIs are documented in later PTC Integration
;; Kit references. This source is a compatibility implementation
;; candidate and must be loaded/tested in Creo 18.1.
;; ============================================================

(in-package :oli)

(defvar *h871-pf-diagnostic-samples* nil)
(defvar *h871-pf-session-list* nil)
(defvar *h871-pf-session-counter* 0)

;; Session registry entry:
;; (browser-name :tree tree-name :label label :results parts
;;               :assembly assembly :instance instance :base base
;;               :samples diagnostic-samples)

(defun h871-pf-session (browser-name)
  (let ((entry (assoc browser-name *h871-pf-session-list* :test #'equal)))
    (when entry (cdr entry))))

(defun h871-pf-store-session (browser-name data)
  (let ((entry (assoc browser-name *h871-pf-session-list* :test #'equal)))
    (if entry
        (setf (cdr entry) data)
      (push (cons browser-name data) *h871-pf-session-list*))
    data))

(defun h871-pf-next-session-id ()
  (incf *h871-pf-session-counter*))

(defun h871-pf-choice-label (value mapping fallback)
  (or (cadr (assoc value mapping)) fallback))

(defun h871-pf-session-label (process material)
  (let ((process-label
          (h871-pf-choice-label process
            '((1 "CNC") (2 "KH") (3 "CG") (4 "COVER"))
            (format nil "P~A" process)))
        (material-label
          (h871-pf-choice-label material
            '((6061 "A6061") (201 "SUS201") (304 "SUS304")
              (400 "SS400") (10 "POM") (20 "Bakelit")
              (30 "MC") (40 "MIKA") (50 "PU"))
            (format nil "M~A" material))))
    (format nil "~A-~A" material-label process-label)))

(defun h871-pf-name (obj)
  (or (sd-inq-obj-basename obj) "<NO NAME>"))

(defun h871-pf-path (obj)
  (or (sd-inq-obj-pathname obj) "<NO PATH>"))

;; Convert numeric values consistently. In Lisp, (= 1 1.0) is
;; already true; this helper additionally accepts numeric strings such
;; as "1" and "1.0" if a runtime/property layer returns text.
(defun h871-pf-as-number (value)
  ;; Creo's dialog fields and SD-INQ-PART-DENSITY return numeric
  ;; values in this workflow. Avoid READ-FROM-STRING and reader
  ;; character literals for compatibility with Modeling 18.1.
  (if (numberp value) value nil))
;; The user verified two native Parts in Modeling 18.1:
;; UI Instance/Base values 1/304 -> API values 1000/304000,
;; and UI values 2/400 -> API values 2000/400000.
;; Normalize API density values to the Part Properties display scale.
(defun h871-pf-density-display-value (api-value)
  (when (numberp api-value)
    (/ api-value 1000.0)))

(defun h871-pf-numeric-equal-p (actual requested)
  (let ((a (h871-pf-as-number actual))
        (b (h871-pf-as-number requested)))
    (and a b
         (<= (abs (- a b)) 0.0000001))))

(defun h871-pf-density-pair-match (part requested-instance requested-base)
  (let ((actual-instance (sd-inq-part-density part :instance))
        (actual-base (sd-inq-part-density part :contents)))
    (and (not (null actual-instance))
         (not (null actual-base))
         (h871-pf-numeric-equal-p
           (h871-pf-density-display-value actual-instance)
           requested-instance)
         (h871-pf-numeric-equal-p
           (h871-pf-density-display-value actual-base)
           requested-base))))

;; ------------------------------------------------------------
;; Filter engine - keep predicates separate from result UI
;; ------------------------------------------------------------

(defun h871-pf-collect (obj matches requested-instance requested-base)
  (when (sd-inq-part-p obj)
    (let ((actual-instance (sd-inq-part-density obj :instance))
          (actual-base (sd-inq-part-density obj :contents)))
      ;; Keep a small raw-value sample in the report so a zero-match
      ;; result reveals what Creo 18.1 actually returned.
      (when (< (length *h871-pf-diagnostic-samples*) 30)
        (push
          (list (h871-pf-name obj)
                (h871-pf-path obj)
                actual-instance
                (type-of actual-instance)
                actual-base
                (type-of actual-base))
          *h871-pf-diagnostic-samples*))
      (when (and
              (h871-pf-numeric-equal-p
                (h871-pf-density-display-value actual-instance)
                requested-instance)
              (h871-pf-numeric-equal-p
                (h871-pf-density-display-value actual-base)
                requested-base))
        (push obj matches))))
  (dolist (child (sd-inq-obj-children obj))
    (setf matches
      (h871-pf-collect child matches requested-instance requested-base)))
  matches)

;; ------------------------------------------------------------
;; Browser row client data and table display callbacks
;; ------------------------------------------------------------

(defun h871-pf-row-data (node)
  (browsernode-objclientdata node))

(defun h871-pf-column-name (node browser-name)
  (declare (ignore browser-name))
  (getf (h871-pf-row-data node) :name))

(defun h871-pf-column-instance (node browser-name)
  (declare (ignore browser-name))
  (let ((value (getf (h871-pf-row-data node) :instance)))
    (if value (format nil "~A" value) "-")))

(defun h871-pf-column-base (node browser-name)
  (declare (ignore browser-name))
  (let ((value (getf (h871-pf-row-data node) :base)))
    (if value (format nil "~A" value) "-")))

(defun h871-pf-column-path (node browser-name)
  (declare (ignore browser-name))
  (getf (h871-pf-row-data node) :path))

(defun h871-pf-build-results-tree (browser-name)
  ;; The update-args value supplied when the tree is registered routes
  ;; this callback to the correct independent session.
  (let* ((session (h871-pf-session browser-name))
         (tree-name (getf session :tree))
         (results (getf session :results)))
    (when session
      (let ((root
              (sd-create-browsernode
                :tree tree-name
                :parent nil
                :objPath "/H871_RESULTS"
                :objPname (getf session :label)
                :objClientData (list :kind :root))))
        (dolist (part (reverse results))
          (let ((instance (sd-inq-part-density part :instance))
                (base (sd-inq-part-density part :contents))
                (path (h871-pf-path part)))
            (sd-create-browsernode
              :tree tree-name
              :parent root
              :objPath path
              :objPname (h871-pf-name part)
              :objClientData
                (list :kind :part
                      :part part
                      :name (h871-pf-name part)
                      :path path
                      :instance (h871-pf-density-display-value instance)
                      :base (h871-pf-density-display-value base)
                      :instance-api instance
                      :base-api base))))
        root))))

(defun h871-pf-select-all-for-browser (browser-name)
  (sd-browser-exec-cmd browser-name :select-all))

(defun h871-pf-clear-selection-for-browser (browser-name)
  (sd-browser-exec-cmd browser-name :clear-select-list))

(defun h871-pf-selected-parts-for-browser (browser-name)
  (let ((parts nil))
    (dolist (node
              (sd-query-browser browser-name :get-selected-objects))
      (let ((data (h871-pf-row-data node)))
        (when (eq (getf data :kind) :part)
          (push (getf data :part) parts))))
    (nreverse parts)))

(defun h871-pf-show-selection-summary-for-browser (browser-name)
  (let ((parts (h871-pf-selected-parts-for-browser browser-name)))
    (sd-browser-set-status-text
      browser-name
      :value (format nil "~A result row(s) selected." (length parts)))))

(defun h871-pf-open-results-browser (browser-name tree-name label result-count)
  (unless
    (sd-create-browser-tree
      tree-name
      :update-events oli:*SD-CHANGE-OBJECT-TREE-EVENT*
      :update-func 'h871-pf-build-results-tree
      :update-args (list browser-name))
    (sd-display-error "H871: Could not create this search session's data tree.")
    (return-from h871-pf-open-results-browser nil))

  (unless
    (sd-create-graphical-browser
      browser-name
      :tree tree-name
      :topLabel (format nil "H871 - ~A" label)
      :treeStatusBar
        (format nil "Matched ~A Part(s). Select rows; Ctrl-click adds/removes."
          result-count)
      :minHeight 280
      :maxWidth 900
      :maxHeight 760
      ;; Ask Creo to create this browser as an independent Browser Bar tab.
      :createAsTab t
      :tabname label
      ;; Keep native Apply: do not provide :okButtonAction.
      :okButtonLabel "Apply"
      :abortButtonLabel "Select All"
      :abortButtonAction (list 'h871-pf-select-all-for-browser browser-name)
      :buttonMenu
        (list
          (list "select-all" :label "Select All"
                :push (list 'h871-pf-select-all-for-browser browser-name))
          (list "clear-selection" :label "Clear Selection"
                :push (list 'h871-pf-clear-selection-for-browser browser-name)))
      :buttonMenuOffObjectOnly nil
      :topMenu
        (list
          (list "selection" :label "Selection"
            :contents
              (list
                (list "select-all" :label "Select All"
                      :push (list 'h871-pf-select-all-for-browser browser-name))
                (list "clear-selection" :label "Clear Selection"
                      :push (list 'h871-pf-clear-selection-for-browser browser-name))
                (list "selection-summary" :label "Update Selection Count"
                      :push (list 'h871-pf-show-selection-summary-for-browser browser-name))))))
    (sd-display-error "H871: Could not create this search Results Browser.")
    (return-from h871-pf-open-results-browser nil))

  (unless
    (sd-browser-define-table
      browser-name
      :table-name "h871-pf-bom"
      :with-name-column nil
      :column-definition
        '(;; :initial-width values below are character counts, not pixels.
          (:label "Part Name"
           :type :string-column
           :display-func h871-pf-column-name
           :initial-width 28)
          (:label "Density Instance"
           :type :string-column
           :display-func h871-pf-column-instance
           :initial-width 13)
          (:label "Density Base"
           :type :string-column
           :display-func h871-pf-column-base
           :initial-width 12)
          (:label "Assembly Path"
           :type :string-column
           :display-func h871-pf-column-path
           :initial-width 42)))
    (sd-display-error "H871: Could not create this session's BOM result table.")
    (return-from h871-pf-open-results-browser nil))

  (sd-browser-set-active-table browser-name :table-name "h871-pf-bom")
  (sd-browser-exec-cmd browser-name :set-table-mode)
  (sd-show-graphical-browser browser-name)

  ;; Each Browser is attached to its own Tree; set the table root locally.
  (let ((root (sd-get-browsernode-struct tree-name :root)))
    (when root
      (sd-browser-exec-cmd browser-name :change-table-root root t)))
  t)

;; ------------------------------------------------------------
;; Report and search action
;; ------------------------------------------------------------

(defun h871-pf-write-report (assembly matches requested-instance requested-base)
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
      (format s "Assembly: ~A~%" (h871-pf-path assembly))
      (format s "Requested Density Instance: ~A~%" requested-instance)
      (format s "Requested Density Base: ~A~%" requested-base)
      (format s "~%RAW DENSITY SAMPLE (first 30 Parts)~%")
      (format s "Part | Path | Instance value/type | Base value/type~%")
      (dolist (sample (reverse *h871-pf-diagnostic-samples*))
        (format s "~S~%" sample))
      (dolist (part matches)
        (format s "~%PART: ~A~%" (h871-pf-name part))
        (format s "PATH: ~A~%" (h871-pf-path part))
        (format s "DENSITY INSTANCE (Part Properties scale): ~A~%"
          (h871-pf-density-display-value
            (sd-inq-part-density part :instance)))
        (format s "DENSITY BASE (Part Properties scale): ~A~%"
          (h871-pf-density-display-value
            (sd-inq-part-density part :contents)))
        (format s "DENSITY INSTANCE (raw API): ~A~%"
          (sd-inq-part-density part :instance))
        (format s "DENSITY BASE (raw API): ~A~%"
          (sd-inq-part-density part :contents))))
    report))

(defun h871-pf-run (assembly requested-instance requested-base)
  (let* ((session-id (h871-pf-next-session-id))
         (browser-name (format nil "h871-pf-results-~A" session-id))
         (tree-name (format nil "h871-pf-results-tree-~A" session-id))
         (base-label (h871-pf-session-label requested-instance requested-base))
         (label (if (some
                      (lambda (entry)
                        (equal (getf (cdr entry) :label) base-label))
                      *h871-pf-session-list*)
                   (format nil "~A-~A" base-label session-id)
                 base-label))
         (matches nil)
         (samples nil)
         (report nil))
    ;; Collection diagnostics are captured into this session before the
    ;; next search resets the working sample list.
    (setf *h871-pf-diagnostic-samples* nil)
    (setf matches
      (h871-pf-collect assembly nil requested-instance requested-base))
    (setf samples (reverse *h871-pf-diagnostic-samples*))
    (setf report
      (h871-pf-write-report assembly matches requested-instance requested-base))
    (if (null matches)
        (sd-display-message
          (format nil
            "No Parts matched Density Instance ~A and Density Base ~A.~%Report: ~A"
            requested-instance requested-base (namestring report)))
      (progn
        (h871-pf-store-session browser-name
          (list :tree tree-name
                :label label
                :results matches
                :assembly assembly
                :instance requested-instance
                :base requested-base
                :samples samples))
        (unless
          (h871-pf-open-results-browser
            browser-name tree-name label (length matches))
          (setf *h871-pf-session-list*
            (remove browser-name *h871-pf-session-list*
                    :key #'car :test #'equal))
          (return-from h871-pf-run nil))
        (sd-browser-set-status-text
          browser-name
          :value (format nil
            "~A matching Part(s) | ~A | Select rows, then Apply."
            (length matches) label))))
    (values (length matches) report)))

;; ------------------------------------------------------------
;; Dialog entry point - ver-03 Multi-Session
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
(sd-defdialog 'h871_part_filter_ver_03
  :dialog-title "H871 - PART FILTER VER-03"
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
     (h871-pf-run assembly machining_process material)
     ;; Keep the input dialog active for consecutive searches.
     (sd-return-from-ok-action)))

;; LOAD:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER_VER_03.lsp")
;; COMMAND:
;; H871_PART_FILTER_VER_03
