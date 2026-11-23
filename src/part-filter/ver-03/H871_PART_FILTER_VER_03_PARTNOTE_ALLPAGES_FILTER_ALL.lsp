;; ============================================================================
;; H871 PART FILTER - VER-03 / FILTER ALL EXTENSION
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Architecture:
;; - ONE standalone UICT Results window with INTERNAL tabs.
;; - One multi-column Display Table per Density pair page.
;; - Each unique Density Instance + Density Base pair owns one page.
;; - Repeating a pair refreshes that page; a no-match search leaves pages intact.
;;
;; Filter All extension: adds ALL selectors for process/material and creates
;; result tabs only for mapped Density pairs that contain matching Parts.
;; The canonical Part Note / All Pages source remains unchanged.
;;
;; ver-03.1 changes:
;; - Replaced concatenated List Control rows with real table columns:
;;   Part Name | Density Instance | Density Base | Assembly Path.
;; - Each table stores the actual Part object in a hidden logical-table column.
;; - Row multi-selection is provided by Display Table :multiple-rows.
;; - Select All / Clear Selection operate only on the page's table.
;; - Added cross-page Select All / Clear All / Apply All Pages controls.
;; - Cross-page actions aggregate the real Part objects from every page table.
;; - Existing per-page Select All, Clear Selection, Apply and Edit Note remain.
;; - Added explicit Apply button; Apply uses the native Graphical Browser
;;   selection-and-execute hand-off pattern already used by ver-02.
;;
;; Compatibility boundary:
;; UICT Display Table APIs below are documented in PTC 20.7 manuals.
;; Exact availability/signatures in Modeling 18.1 remain unverified.
;; The Apply bridge deliberately reuses ver-02 Graphical Browser APIs which
;; are part of the user's known-good 18.1 workflow. The hidden bridge itself
;; still requires a runtime test in the user's 18.1 installation.
;; Do not modify ver-01/ver-02; they remain regression baselines.
;; ============================================================================

(in-package :oli)

(defvar *h871-pf-v03-pages* nil)
(defvar *h871-pf-v03-page-counter* 0)
(defvar *h871-pf-v03-current-page* nil)
(defvar *h871-pf-v03-assembly* nil)
(defvar *h871-pf-v03-diagnostic-samples* nil)
(defvar *h871-pf-v03-collect-visited-count* 0)

;; ========================================================================
;; MACHINE-SPECIFIC DENSITY API SCALE
;; Edit ONLY this value when moving the tool to another Modeling workstation.
;;
;; Part Properties / filter input values stay in the familiar form:
;;   Density Instance = 1, Density Base = 304
;;
;; In the previously tested workstation, the API returned values x1000:
;;   UI 1 / 304  -> API 1000 / 304000
;;   UI 2 / 400  -> API 2000 / 400000
;;
;; Therefore the default multiplier is 1000.0. If another workstation
;; returns the same values as Part Properties, set this to 1.0.
;; The same factor is applied to BOTH Instance and Base density values.
;; ========================================================================
(defparameter *h871-pf-v03-density-api-multiplier* 1000.0)

(defvar *h871-pf-v03-shell* "h871-pf-v03-results")
(defvar *h871-pf-v03-grid* "h871-pf-v03-results-grid")
(defvar *h871-pf-v03-tabs* "h871-pf-v03-tabs")

;; Native Apply bridge: temporary Graphical Browser objects are not shown.
(defvar *h871-pf-v03-apply-parts* nil)

;; Per-Part Note: instance-level UDA, isolated from Apply Bridge state.
(defvar *h871-pf-v03-note-edit-part* nil)
(defvar *h871-pf-v03-note-edit-page* nil)
(defvar *h871-pf-v03-note-attribute-name* "H871_PART_FILTER_NOTE")
(defvar *h871-pf-v03-apply-nodes* nil)
(defvar *h871-pf-v03-pending-apply-page* nil)
(defvar *h871-pf-v03-apply-browser* "h871-pf-v03-apply-bridge")
(defvar *h871-pf-v03-apply-tree* "h871-pf-v03-apply-tree")

;; Diagnostic trace uses the independently user-validated file-write method.
;; File errors are deliberately visible; never report false success.
(defun h871-pf-v03-trace-file ()
  (merge-pathnames
    "H871_PART_FILTER_VER_03_TRACE.txt"
    (user-homedir-pathname)))

(defun h871-pf-v03-trace-reset ()
  (with-open-file
    (stream (h871-pf-v03-trace-file)
      :direction :output :if-exists :supersede :if-does-not-exist :create)
    (format stream "H871 VER-03 TRACE START~%")
    (force-output stream))
  t)

(defun h871-pf-v03-trace (stage &optional detail)
  (with-open-file
    (stream (h871-pf-v03-trace-file)
      :direction :output :if-exists :append :if-does-not-exist :create)
    (format stream "~A | ~S~%" stage detail)
    (force-output stream))
  t)

;; Page entry:
;; (:instance n :base n :label string :page string :table string
;;  :logical-table string :status string :results (Part ...))


;; ---------------------------------------------------------------------------
;; Per-Part Note storage — instance-level UDA filed with the Modeling file.
;; This subsystem does not participate in the Apply Bridge selection hand-off.
;; ---------------------------------------------------------------------------

(defun h871-pf-v03-read-note (part)
  (or
    (sd-inq-item-attribute
      part
      *h871-pf-v03-note-attribute-name*
      :note
      :attachment :instance)
    ""))

(defun h871-pf-v03-write-note (part note)
  (let ((attached
          (member
            *h871-pf-v03-note-attribute-name*
            (sd-inq-item-attributes part :attachment :instance)
            :test #'string=)))
    (if attached
        (sd-mod-item-attribute
          part
          *h871-pf-v03-note-attribute-name*
          :attachment :instance
          :filing :sd-file
          :values (list :note note))
      (sd-attach-item-attribute
        part
        *h871-pf-v03-note-attribute-name*
        :attachment :instance
        :filing :sd-file
        :values (list :note note)))
    (equal note (h871-pf-v03-read-note part))))

(defun h871-pf-v03-name (obj)
  (or (sd-inq-obj-basename obj) "<NO NAME>"))

(defun h871-pf-v03-path (obj)
  (or (sd-inq-obj-pathname obj) "<NO PATH>"))

(defun h871-pf-v03-as-number (value)
  (if (numberp value) value nil))

;; Convert a Part Properties/filter value into the scale returned by Creo API.
(defun h871-pf-v03-density-api-value (display-value)
  (when (numberp display-value)
    (* display-value *h871-pf-v03-density-api-multiplier*)))

;; Convert a raw Creo API value back to the familiar Part Properties scale.
(defun h871-pf-v03-density-display-value (api-value)
  (when (and (numberp api-value)
             (numberp *h871-pf-v03-density-api-multiplier*)
             (> *h871-pf-v03-density-api-multiplier* 0))
    (/ api-value *h871-pf-v03-density-api-multiplier*)))

(defun h871-pf-v03-numeric-equal-p (actual requested)
  (let ((a (h871-pf-v03-as-number actual))
        (b (h871-pf-v03-as-number requested)))
    (and a b
         (<= (abs (- a b)) 0.0000001))))

(defun h871-pf-v03-collect (obj matches requested-instance requested-base)
  ;; Progress checkpoints expose the last completed traversal depth/volume if
  ;; Modeling terminates during recursive assembly traversal. Filter semantics
  ;; and traversal order are unchanged.
  (incf *h871-pf-v03-collect-visited-count*)
  (when (= (mod *h871-pf-v03-collect-visited-count* 100) 0)
    (h871-pf-v03-trace
      "COLLECT/PROGRESS"
      *h871-pf-v03-collect-visited-count*))
  ;; Keep the ver-02 exact-pair semantics. Scale the user-facing numeric inputs
  ;; into the raw API scale using the one machine-specific multiplier above.
  (when (sd-inq-part-p obj)
    (let ((actual-instance (sd-inq-part-density obj :instance))
          (actual-base (sd-inq-part-density obj :contents)))
      (when (< (length *h871-pf-v03-diagnostic-samples*) 30)
        (push
          (list (h871-pf-v03-name obj)
                (h871-pf-v03-path obj)
                actual-instance (type-of actual-instance)
                actual-base (type-of actual-base))
          *h871-pf-v03-diagnostic-samples*))
      (when (and
              (not (null actual-instance))
              (not (null actual-base))
              (h871-pf-v03-numeric-equal-p
                (h871-pf-v03-density-api-value requested-instance)
                actual-instance)
              (h871-pf-v03-numeric-equal-p
                (h871-pf-v03-density-api-value requested-base)
                actual-base))
        (push obj matches))))
  (dolist (child (sd-inq-obj-children obj))
    (setf matches
      (h871-pf-v03-collect child matches requested-instance requested-base)))
  matches)

(defun h871-pf-v03-choice-label (value mapping fallback)
  (or (cadr (assoc value mapping)) fallback))

(defun h871-pf-v03-process-label (process)
  (h871-pf-v03-choice-label process
    '((1 "CNC") (2 "KH") (3 "CG") (4 "COVER"))
    (format nil "P~A" process)))

(defun h871-pf-v03-material-label (material)
  (h871-pf-v03-choice-label material
    '((6061 "A6061") (201 "SUS201") (304 "SUS304")
      (400 "SS400") (10 "POM") (20 "Bakelit")
      (30 "MC") (40 "MIKA") (50 "PU"))
    (format nil "M~A" material)))

;; The label is presentation only. Search always uses numeric Density values:
;; Density Instance = process code (e.g. 1), Density Base = material code (e.g. 304).
;; Display convention is PROCESS-MATERIAL, e.g. CNC-SUS304.
(defun h871-pf-v03-pair-label (instance base)
  (format nil "~A-~A"
    (h871-pf-v03-process-label instance)
    (h871-pf-v03-material-label base)))

;; ---------------------------------------------------------------------------
;; Filter All support
;; -1 is reserved as the dialog sentinel for ALL; it is not a valid process
;; or material code in the established convention table.
;; ---------------------------------------------------------------------------

(defun h871-pf-v03-process-codes ()
  '(1 2 3 4))

(defun h871-pf-v03-material-codes ()
  '(6061 201 304 400 10 20 30 40 50))

(defun h871-pf-v03-filter-values (selected all-values)
  (if (and (numberp selected) (= selected -1))
      all-values
    (list selected)))

(defun h871-pf-v03-build-filter-pairs (selected-process selected-material)
  (let ((processes
          (h871-pf-v03-filter-values
            selected-process (h871-pf-v03-process-codes)))
        (materials
          (h871-pf-v03-filter-values
            selected-material (h871-pf-v03-material-codes))))
    (mapcan
      (lambda (process)
        (mapcar
          (lambda (material) (list process material))
          materials))
      processes)))

;; Traverse the assembly once and bucket Parts by the exact mapped density pair.
;; This avoids rescanning the complete assembly once for each of up to 36 pairs.
(defun h871-pf-v03-collect-filter-pairs (obj grouped pairs)
  (incf *h871-pf-v03-collect-visited-count*)
  (when (= (mod *h871-pf-v03-collect-visited-count* 100) 0)
    (h871-pf-v03-trace
      "COLLECT-ALL/PROGRESS"
      *h871-pf-v03-collect-visited-count*))
  (when (sd-inq-part-p obj)
    (let ((actual-instance (sd-inq-part-density obj :instance))
          (actual-base (sd-inq-part-density obj :contents)))
      (when (< (length *h871-pf-v03-diagnostic-samples*) 30)
        (push
          (list (h871-pf-v03-name obj)
                (h871-pf-v03-path obj)
                actual-instance (type-of actual-instance)
                actual-base (type-of actual-base))
          *h871-pf-v03-diagnostic-samples*))
      (let ((matched-pair
              (find-if
                (lambda (pair)
                  (and
                    (not (null actual-instance))
                    (not (null actual-base))
                    (h871-pf-v03-numeric-equal-p
                      (h871-pf-v03-density-api-value (car pair))
                      actual-instance)
                    (h871-pf-v03-numeric-equal-p
                      (h871-pf-v03-density-api-value (cadr pair))
                      actual-base)))
                pairs)))
        (when matched-pair
          (let ((bucket (assoc matched-pair grouped :test #'equal)))
            (if bucket
                (setf (cdr bucket) (cons obj (cdr bucket)))
              (push (cons matched-pair (list obj)) grouped)))))))
  (dolist (child (sd-inq-obj-children obj))
    (setf grouped
      (h871-pf-v03-collect-filter-pairs child grouped pairs)))
  grouped)

(defun h871-pf-v03-write-filter-all-report
    (assembly grouped selected-process selected-material)
  (let ((report
          (merge-pathnames
            "H871_PART_FILTER_VER_03_FILTER_ALL_RESULT.txt"
            (user-homedir-pathname)))
        (total 0))
    (with-open-file
      (stream report
        :direction :output :if-exists :supersede :if-does-not-exist :create)
      (format stream "H871 PART FILTER VER-03 - FILTER ALL~%")
      (format stream "Assembly: ~A~%" (h871-pf-v03-path assembly))
      (format stream "Density API multiplier: ~A~%"
        *h871-pf-v03-density-api-multiplier*)
      (format stream "Selected process: ~A~%" selected-process)
      (format stream "Selected material: ~A~%" selected-material)
      (format stream "~%MATCHED DENSITY PAIRS~%")
      (dolist (bucket grouped)
        (let* ((pair (car bucket))
               (parts (reverse (cdr bucket))))
          (incf total (length parts))
          (format stream "~%~A | Instance=~A | Base=~A | Parts=~A~%"
            (h871-pf-v03-pair-label (car pair) (cadr pair))
            (car pair) (cadr pair) (length parts))
          (dolist (part parts)
            (format stream "PART: ~A~%PATH: ~A~%"
              (h871-pf-v03-name part) (h871-pf-v03-path part)))))
      (format stream "~%TOTAL PARTS: ~A~%" total)
      (format stream "MATCHED PAIR COUNT: ~A~%" (length grouped)))
    report))

(defun h871-pf-v03-run-filter-all
    (assembly selected-process selected-material)
  (h871-pf-v03-trace-reset)
  (h871-pf-v03-trace "RUN/FILTER-ALL-BEGIN"
    (list (type-of assembly) selected-process selected-material))
  (unless
    (and
      (or (and (numberp selected-process) (= selected-process -1))
          (member selected-process (h871-pf-v03-process-codes)))
      (or (and (numberp selected-material) (= selected-material -1))
          (member selected-material (h871-pf-v03-material-codes)))
      (numberp *h871-pf-v03-density-api-multiplier*)
      (> *h871-pf-v03-density-api-multiplier* 0))
    (sd-display-error
      "H871 ver-03: Invalid Filter All settings or Density API multiplier.")
    (return-from h871-pf-v03-run-filter-all nil))
  (let* ((pairs
           (h871-pf-v03-build-filter-pairs
             selected-process selected-material))
         (grouped nil)
         (report nil)
         (total 0)
         (page-count 0))
    (setf *h871-pf-v03-diagnostic-samples* nil)
    (setf *h871-pf-v03-collect-visited-count* 0)
    (setf *h871-pf-v03-assembly* assembly)
    (h871-pf-v03-trace "COLLECT-ALL/BEGIN"
      (list (h871-pf-v03-path assembly) (length pairs)))
    (setf grouped
      (h871-pf-v03-collect-filter-pairs assembly nil pairs))
    (setf report
      (h871-pf-v03-write-filter-all-report
        assembly grouped selected-process selected-material))
    (h871-pf-v03-trace "COLLECT-ALL/DONE"
      (list (length grouped) report))
    ;; Buckets exist only for pairs that actually contain Parts. No empty
    ;; Results tabs are created; existing tabs remain untouched on no-match.
    (when (null grouped)
      (sd-display-message
        (format nil
          "No Parts matched the selected Filter All range.~%Existing Results tabs were kept unchanged.~%Report: ~A"
          (namestring report)))
      (return-from h871-pf-v03-run-filter-all (values 0 report)))
    (h871-pf-v03-trace "RUN/FILTER-ALL/CREATE-SHELL" nil)
    (unless (h871-pf-v03-create-shell)
      (return-from h871-pf-v03-run-filter-all nil))
    ;; Process in the convention-table order, not the traversal/discovery order.
    (dolist (pair pairs)
      (let ((bucket (assoc pair grouped :test #'equal)))
        (when bucket
          (let* ((parts (nreverse (cdr bucket)))
                 (entry
                   (h871-pf-v03-find-page (car pair) (cadr pair))))
            (incf total (length parts))
            (unless entry
              (setf entry
                (h871-pf-v03-create-page (car pair) (cadr pair))))
            (unless entry
              (return-from h871-pf-v03-run-filter-all nil))
            (unless (h871-pf-v03-refresh-page entry parts)
              (return-from h871-pf-v03-run-filter-all nil))
            (incf page-count)
            (h871-pf-v03-trace "RUN/FILTER-ALL/PAGE-DONE"
              (list pair (length parts) (getf entry :page)))))))
    (unless (sd-dialog-shell-visible-p *h871-pf-v03-shell*)
      (sd-show-dialog-shell *h871-pf-v03-shell*))
    (sd-display-message
      (format nil
        "Filter completed: ~A Part(s) across ~A result page(s)."
        total page-count))
    (values total report)))

(defun h871-pf-v03-run-filter
    (assembly selected-process selected-material)
  (if (or
        (and (numberp selected-process) (= selected-process -1))
        (and (numberp selected-material) (= selected-material -1)))
      (h871-pf-v03-run-filter-all
        assembly selected-process selected-material)
    (h871-pf-v03-run assembly selected-process selected-material)))

(defun h871-pf-v03-find-page (instance base)
  (find-if
    (lambda (entry)
      (and (= (getf entry :instance) instance)
           (= (getf entry :base) base)))
    *h871-pf-v03-pages*))

(defun h871-pf-v03-page-by-name (page-name)
  (find-if
    (lambda (entry) (equal (getf entry :page) page-name))
    *h871-pf-v03-pages*))

(defun h871-pf-v03-page-by-table (table-name)
  (find-if
    (lambda (entry) (equal (getf entry :table) table-name))
    *h871-pf-v03-pages*))

(defun h871-pf-v03-table-name (page-name)
  (concatenate 'string page-name "-DISPLAY-TABLE"))

(defun h871-pf-v03-logical-table-name (page-name)
  (concatenate 'string page-name "-LOGICAL-TABLE"))

(defun h871-pf-v03-status-name (page-name)
  (concatenate 'string page-name "-STATUS-TX"))

(defun h871-pf-v03-table-contents (parts)
  (let ((rows nil)
        (row-id 0))
    (dolist (part parts)
      (push
        (list
          (incf row-id)
          (h871-pf-v03-name part)
          (h871-pf-v03-density-display-value
            (sd-inq-part-density part :instance))
          (h871-pf-v03-density-display-value
            (sd-inq-part-density part :contents))
          (h871-pf-v03-path part)
          (h871-pf-v03-read-note part)
          part)
        rows))
    (nreverse rows)))

(defun h871-pf-v03-update-status (page-name)
  ;; A tab-change callback can fire while sd-insert-tab-control-page is
  ;; creating the page, before its page record/table/status controls exist.
  ;; Never pass NIL to a UICT API that requires a STRING handle.
  (let ((entry (and (stringp page-name)
                    (h871-pf-v03-page-by-name page-name))))
    (when entry
      (let ((table-name (getf entry :table))
            (status-name (getf entry :status)))
        (when (and (stringp table-name)
                   (> (length table-name) 0)
                   (stringp status-name)
                   (> (length status-name) 0))
          (let* ((selection (sd-get-display-table-selection table-name))
                 (selected-rows (if selection (car selection) nil))
                 (selected-count
                   (if selected-rows (length selected-rows) 0))
                 (total (length (getf entry :results))))
            (sd-set-text-control-value status-name
              :text
                (format nil
                  "~A Part(s) | ~A selected | Density Instance ~A / Base ~A"
                  total selected-count
                  (getf entry :instance) (getf entry :base)))))))))

(defun h871-pf-v03-table-selection-changed (table-name)
  (when (stringp table-name)
    (let ((entry (h871-pf-v03-page-by-table table-name)))
      (when entry
        (h871-pf-v03-update-status (getf entry :page))))))

(defun h871-pf-v03-tab-changed (page-name)
  (when (stringp page-name)
    (setf *h871-pf-v03-current-page* page-name)
    ;; During initial page insertion the page registry may not exist yet.
    ;; update-status safely becomes a no-op until create-page registers it.
    (h871-pf-v03-update-status page-name)))

(defun h871-pf-v03-select-all (page-name)
  (let* ((entry (h871-pf-v03-page-by-name page-name))
         (table-name (getf entry :table))
         (count (length (getf entry :results))))
    (when entry
      (when (> count 0)
        (do ((row 0 (+ row 1)))
            ((>= row count))
          (sd-set-display-table-selection
            table-name
            :mode (if (= row 0) :replace :add)
            :row row
            :callAction nil)))
      (h871-pf-v03-update-status page-name))))

(defun h871-pf-v03-clear-selection (page-name)
  (let ((entry (h871-pf-v03-page-by-name page-name)))
    (when entry
      (sd-reset-display-table-selection
        (getf entry :table) :row t)
      (h871-pf-v03-update-status page-name))))

;; Cross-page selection actions deliberately operate on each existing table
;; independently. They do not switch tabs or rebuild/refresh any result page.
(defun h871-pf-v03-select-all-pages (&optional callback-arg)
  (h871-pf-v03-trace "SELECT-ALL-PAGES/CALLBACK-ENTER" callback-arg)
  (dolist (entry *h871-pf-v03-pages*)
    (h871-pf-v03-select-all (getf entry :page)))
  (sd-display-message
    (format nil "H871: Select All Pages completed across ~A page(s)."
      (length *h871-pf-v03-pages*)))
  t)

(defun h871-pf-v03-clear-all-pages (&optional callback-arg)
  (h871-pf-v03-trace "CLEAR-ALL-PAGES/CALLBACK-ENTER" callback-arg)
  (dolist (entry *h871-pf-v03-pages*)
    (h871-pf-v03-clear-selection (getf entry :page)))
  (sd-display-message
    (format nil "H871: Selection cleared across ~A page(s)."
      (length *h871-pf-v03-pages*)))
  t)

(defun h871-pf-v03-collect-selected-parts-all-pages ()
  (let ((parts nil))
    (dolist (entry *h871-pf-v03-pages*)
      (let* ((selection
               (sd-get-display-table-selection (getf entry :table)))
             (columns (if selection (cadr selection) nil))
             (page-parts (if columns (getf columns :part-object) nil)))
        (dolist (part page-parts)
          ;; A Part should normally belong to one Density-pair page only.
          ;; EQ de-duplication prevents duplicate native selection if stale or
          ;; overlapping page data ever exposes the same object more than once.
          (unless (member part parts :test #'eq)
            (push part parts)))))
    (nreverse parts)))

(defun h871-pf-v03-edit-note (page-name)
  (let* ((entry (h871-pf-v03-page-by-name page-name))
         (selection (and entry
                         (sd-get-display-table-selection (getf entry :table))))
         (columns (if selection (cadr selection) nil))
         (parts (if columns (getf columns :part-object) nil)))
    (cond
      ((null parts)
       (sd-display-message "H871: Select one Part row before choosing Edit Note."))
      ((cdr parts)
       (sd-display-message "H871: Edit Note supports one Part at a time. Select exactly one Part row."))
      (t
       (setf *h871-pf-v03-note-edit-part* (car parts))
       (setf *h871-pf-v03-note-edit-page* page-name)
       ;; The editor is interactive; queue it after the UICT callback returns.
       (sd-put-buffer "h871_pf_v03_note_editor")))))

;; ---------------------------------------------------------------------------
;; Apply bridge
;;
;; The selected Display Table rows return the hidden :part-object column.
;; Those real Part objects are represented as BrowserNodes using their actual
;; Modeling object path. The same native :set-object-selection and
;; :select-and-execute commands used by ver-02 then hand the selected objects
;; to the active Modeling command/selection context.
;; ---------------------------------------------------------------------------

(defun h871-pf-v03-build-apply-tree ()
  (let ((root
          (sd-create-browsernode
            :tree *h871-pf-v03-apply-tree*
            :parent nil
            :objPath "/H871_V03_APPLY"
            :objPname "H871 Apply Selection"
            :objClientData (list :kind :root))))
    (setf *h871-pf-v03-apply-nodes* nil)
    (dolist (part *h871-pf-v03-apply-parts*)
      (push
        (sd-create-browsernode
          :tree *h871-pf-v03-apply-tree*
          :parent root
          :objPath (h871-pf-v03-path part)
          :objPname (h871-pf-v03-name part)
          :objClientData (list :kind :part :part part))
        *h871-pf-v03-apply-nodes*))
    root))

(defun h871-pf-v03-native-apply (parts)
  (h871-pf-v03-trace "APPLY/NATIVE-BEGIN"
    (list (length parts) (mapcar #'type-of parts)))
  (when (null parts)
    (sd-display-message "H871: Select one or more Part rows before Apply.")
    (return-from h871-pf-v03-native-apply nil))

  (setf *h871-pf-v03-apply-parts* parts)
  (setf *h871-pf-v03-apply-nodes* nil)

  ;; Rebuild the temporary bridge from the active page's selected Parts only.
  (ignore-errors
    (sd-hide-graphical-browser *h871-pf-v03-apply-browser*))
  (ignore-errors
    (sd-destroy-graphical-browser *h871-pf-v03-apply-browser*))
  (ignore-errors
    (sd-destroy-browser-tree *h871-pf-v03-apply-tree*))

  (unless
    (sd-create-browser-tree
      *h871-pf-v03-apply-tree*
      :update-events oli:*SD-CHANGE-OBJECT-TREE-EVENT*
      :update-func 'h871-pf-v03-build-apply-tree)
    (sd-display-error "H871 Apply: Could not create the native selection bridge tree.")
    (return-from h871-pf-v03-native-apply nil))

  (unless
    (sd-create-graphical-browser
      *h871-pf-v03-apply-browser*
      :tree *h871-pf-v03-apply-tree*
      :topLabel "H871 - Native Apply Bridge"
      :minHeight 160
      :maxWidth 480
      :maxHeight 240
      :okButtonLabel "Apply")
    (sd-display-error "H871 Apply: Could not create the native selection bridge.")
    (return-from h871-pf-v03-native-apply nil))

  ;; Force construction of the bridge nodes even when its browser is not shown.
  ;; The browser update callback may also rebuild them when the browser opens.
  (unless (sd-get-browsernode-struct *h871-pf-v03-apply-tree* :root)
    (h871-pf-v03-build-apply-tree))
  (h871-pf-v03-trace "APPLY/NODES-BUILT"
    (list (length *h871-pf-v03-apply-nodes*)
          (mapcar #'type-of *h871-pf-v03-apply-nodes*)))

  ;; Mirror ver-02: make the bridge root's direct Part children the table rows.
  (h871-pf-v03-trace "APPLY/SET-TABLE-MODE"
    (sd-browser-exec-cmd *h871-pf-v03-apply-browser* :set-table-mode))
  (let ((root
          (sd-get-browsernode-struct *h871-pf-v03-apply-tree* :root)))
    (h871-pf-v03-trace "APPLY/ROOT-STRUCT" (type-of root))
    (when root
      (h871-pf-v03-trace "APPLY/CHANGE-TABLE-ROOT"
        (sd-browser-exec-cmd
          *h871-pf-v03-apply-browser* :change-table-root root t))))

  ;; DIAGNOSTIC EXPERIMENT:
  ;; Show the bridge before querying displayed-state and before native hand-off.
  ;; Earlier traces showed DISPLAYED=NIL for every resolved BrowserNode.
  ;; This isolates whether the hidden bridge is the reason Modeling does not
  ;; transfer the selected Parts into the active 3D selection.
  (let ((shown
          (sd-show-graphical-browser *h871-pf-v03-apply-browser*)))
    (h871-pf-v03-trace "APPLY/SHOW-BRIDGE-RETURN" shown))

  ;; Resolve each symbolic ID to a BrowserNode structure, then record whether
  ;; Modeling considers it displayed and whether it enters the browser selection.
  (dolist (node-id *h871-pf-v03-apply-nodes*)
    (let* ((node-struct
             (sd-get-browsernode-struct *h871-pf-v03-apply-tree* node-id))
           (displayed
             (and node-struct
                  (sd-query-browser
                    *h871-pf-v03-apply-browser* :is-object-displayed node-struct)))
           (selected
             (and node-struct
                  (sd-browser-exec-cmd
                    *h871-pf-v03-apply-browser*
                    :set-object-selection node-struct t))))
      (h871-pf-v03-trace "APPLY/NODE-STATE"
        (list node-id (type-of node-struct) displayed selected))))
  (h871-pf-v03-trace "APPLY/SELECTED-COUNT"
    (sd-query-browser *h871-pf-v03-apply-browser* :number-of-selected-objects))
  (h871-pf-v03-trace "APPLY/SELECTED-NODES"
    (mapcar #'type-of
      (or (sd-query-browser
            *h871-pf-v03-apply-browser* :get-selected-objects)
          nil)))

  ;; This function is now called by the dedicated no-input Modeling
  ;; User Action below. Its sd-call-cmds call therefore runs in a valid
  ;; action context, unlike a direct UICT :pushAction callback.
  (let ((handoff
          (sd-call-cmds
            (sd-browser-exec-cmd
              *h871-pf-v03-apply-browser* :select-and-execute)
            :success
              (progn
                (h871-pf-v03-trace
                  "APPLY/SELECT-AND-EXECUTE-SUCCESS-CONTEXT"
                  *sd-action-result*)
                :success)
            :failure
              (progn
                (h871-pf-v03-trace
                  "APPLY/SELECT-AND-EXECUTE-ACTION-ERROR"
                  (sd-inq-error-obj :all))
                :error))))
    ;; A NIL browser-command result is not itself an error. The explicit
    ;; sd-call-cmds success/failure branch distinguishes execution failure
    ;; from a command that completed without a meaningful return value.
    (h871-pf-v03-trace "APPLY/SELECT-AND-EXECUTE-STATUS" handoff)
    (when (eq handoff :error)
      (sd-display-message
        "H871 Apply: Modeling rejected the native hand-off. See the trace file.")
      (return-from h871-pf-v03-native-apply nil)))
  t)

;; A zero-input sequential Dialog Generator command runs its :ok-action
;; immediately, without opening a second dialog. UICT callbacks are not
;; Modeling User Actions, so they must queue this command through the
;; Modeling command line using sd-put-buffer. The :ok-action then provides
;; the real User Action context required by sd-call-cmds.
(sd-defdialog 'h871_pf_v03_apply_action
  :dialog-title "H871 Apply Selection"
  :dialog-control :sequential
  :variables '()
  :ok-action
    '(progn
       (h871-pf-v03-trace "APPLY/USER-ACTION-ENTER"
         (list (length *h871-pf-v03-apply-parts*)
               *h871-pf-v03-pending-apply-page*))
       (let ((result
               (h871-pf-v03-native-apply
                 *h871-pf-v03-apply-parts*)))
         (h871-pf-v03-trace "APPLY/USER-ACTION-RESULT" result)
         (when result
           (if *h871-pf-v03-pending-apply-page*
               (h871-pf-v03-update-status
                 *h871-pf-v03-pending-apply-page*)
             (dolist (entry *h871-pf-v03-pages*)
               (h871-pf-v03-update-status (getf entry :page)))))
         result)))

;; Display Table double-click callback. UICT passes the table name;
;; route the action to the owning page so only that page's selected Part(s)
;; are handed to Modeling.
(defun h871-pf-v03-double-click (table-name)
  (h871-pf-v03-trace "APPLY/DOUBLE-CLICK-CALLBACK" table-name)
  (let ((entry (h871-pf-v03-page-by-table table-name)))
    (h871-pf-v03-trace "APPLY/DOUBLE-CLICK-PAGE"
      (and entry (getf entry :page)))
    (when entry
      (h871-pf-v03-apply (getf entry :page)))))

(defun h871-pf-v03-apply-all-pages (&optional callback-arg)
  (h871-pf-v03-trace "APPLY-ALL-PAGES/CALLBACK-ENTER" callback-arg)
  (let ((parts (h871-pf-v03-collect-selected-parts-all-pages)))
    (h871-pf-v03-trace "APPLY/ALL-PAGES-SELECTION"
      (list (length *h871-pf-v03-pages*) (length parts)))
    (if (null parts)
        (sd-display-message
          "H871: No Part rows selected in any page. Select rows or use Select All Pages, then press Apply All Pages.")
      (progn
        (setf *h871-pf-v03-apply-parts* parts)
        ;; NIL marks a cross-page operation; the queued action refreshes every
        ;; page status after the native hand-off succeeds.
        (setf *h871-pf-v03-pending-apply-page* nil)
        (h871-pf-v03-trace "APPLY/ALL-PAGES-QUEUE"
          (list (length parts) (mapcar #'type-of parts)))
        (let ((queued
                (sd-put-buffer "H871_PF_V03_APPLY_ACTION")))
          (h871-pf-v03-trace "APPLY/ALL-PAGES-QUEUE-RETURN" queued)
          (unless queued
            (sd-display-message
              "H871 Apply All Pages: Could not queue the Modeling Apply action.")))))))

(defun h871-pf-v03-apply (page-name)
  (let* ((entry (h871-pf-v03-page-by-name page-name))
         (selection (and entry
                         (sd-get-display-table-selection (getf entry :table))))
         (columns (if selection (cadr selection) nil))
         (parts (if columns (getf columns :part-object) nil)))
    (h871-pf-v03-trace "APPLY/UICT-SELECTION"
      (list page-name (and entry (getf entry :table))
            (and selection (type-of selection))
            (and columns (type-of columns))
            (and parts (length parts))
            (and parts (mapcar #'type-of parts))))
    (if (null parts)
        (sd-display-message
          "H871: No Part rows selected. Select rows or use Select All, then press Apply.")
      (progn
        ;; Preserve the active page's real Part objects, then queue a
        ;; dedicated no-input Modeling User Action. Do not call
        ;; sd-call-cmds from this UICT callback: it is not an action context.
        (setf *h871-pf-v03-apply-parts* parts)
        (setf *h871-pf-v03-pending-apply-page* page-name)
        (h871-pf-v03-trace "APPLY/QUEUE-USER-ACTION"
          (list page-name (length parts)))
        (let ((queued
                (sd-put-buffer "H871_PF_V03_APPLY_ACTION")))
          (h871-pf-v03-trace "APPLY/QUEUE-USER-ACTION-RETURN" queued)
          (unless queued
            (sd-display-message
              "H871 Apply: Could not queue the Modeling Apply action.")))))))

;; ---------------------------------------------------------------------------
;; Results window and internal tabs
;; ---------------------------------------------------------------------------

(defun h871-pf-v03-create-shell ()
  (h871-pf-v03-trace "CREATE-SHELL/BEGIN" nil)
  ;; Recover each UICT layer independently. A previous failed attempt can
  ;; leave the dialog shell alive while its grid or tab control was never
  ;; created. Checking only sd-dialog-shell-p would then skip the missing
  ;; child controls and the next search would fail during page insertion.
  (h871-pf-v03-trace "CREATE-SHELL/CHECK-DIALOG" *h871-pf-v03-shell*)
  (unless (sd-dialog-shell-p *h871-pf-v03-shell*)
    (unless
      (sd-create-dialog-shell
        *h871-pf-v03-shell*
        :title "H871 - PART FILTER RESULTS VER-03-PARTNOTE"
        :bottomLine :none
        :closeAction
          (list 'sd-hide-dialog-shell *h871-pf-v03-shell* :ignorePin t)
        :margin 4)
      (h871-pf-v03-trace "CREATE-SHELL/DIALOG-CREATE-FAILED" *h871-pf-v03-shell*)
      (sd-display-error "H871 ver-03: Could not create the Results window.")
      (return-from h871-pf-v03-create-shell nil)))

  (h871-pf-v03-trace "CREATE-SHELL/CHECK-GRID" *h871-pf-v03-grid*)
  ;; sd-control-p accepts UICT control/area handles and lets us recover
  ;; partially-created shells without destroying a valid Results window.
  (unless (sd-control-p *h871-pf-v03-grid*)
    (unless
      (sd-append-grid-area
        *h871-pf-v03-grid* (concatenate 'string *h871-pf-v03-shell* "-AA")
        :width 920 :height 560 :cellSize 10,10 :margin 4 :spacing 2)
      (h871-pf-v03-trace "CREATE-SHELL/GRID-CREATE-FAILED" *h871-pf-v03-grid*)
      (sd-display-error "H871 ver-03: Could not create the Results layout.")
      (return-from h871-pf-v03-create-shell nil)))

  (h871-pf-v03-trace "CREATE-SHELL/CHECK-TABS" *h871-pf-v03-tabs*)
  (unless (sd-control-p *h871-pf-v03-tabs*)
    (unless
      (sd-create-tab-control
        *h871-pf-v03-tabs* *h871-pf-v03-grid*
        :x 0 :y 0 :width 90 :height 56
        ;; Match PTC's UICT tab examples: pass a function object.
        :tabChangedAction #'h871-pf-v03-tab-changed)
      (h871-pf-v03-trace "CREATE-SHELL/TAB-CREATE-FAILED" *h871-pf-v03-tabs*)
      (sd-display-error "H871 ver-03: Could not create the internal tab control.")
      (return-from h871-pf-v03-create-shell nil)))
  (h871-pf-v03-trace "CREATE-SHELL/OK" nil)
  t)

(defun h871-pf-v03-create-logical-table (logical-table)
  (sd-create-logical-table
    logical-table
    :secured nil
    :columns '(:row-id :part-name :density-instance :density-base
               :assembly-path :part-note :part-object)
    :columnNames '("Row ID" "Part Name" "Density Instance" "Density Base"
                   "Assembly Path" "Part Note" "Part Object")
    :keyColumns '(:row-id)
    :types '(:number :string :number :number :string :string nil)
    :contents nil))

(defun h871-pf-v03-create-page (instance base)
  (h871-pf-v03-trace "CREATE-PAGE/BEGIN" (list instance base))
  (let* ((label (h871-pf-v03-pair-label instance base))
         (page-name
           (format nil "H871-PF-V03-PAGE-~A"
             (incf *h871-pf-v03-page-counter*)))
         (table-name (h871-pf-v03-table-name page-name))
         (logical-table (h871-pf-v03-logical-table-name page-name))
         (status-name (h871-pf-v03-status-name page-name))
         (tab-grid (concatenate 'string page-name "-TAB-GA")))

    (h871-pf-v03-trace "CREATE-PAGE/INSERT-TAB/BEGIN" (list page-name *h871-pf-v03-tabs*))
    (unless
      (sd-insert-tab-control-page
        page-name *h871-pf-v03-tabs*
        :tabTitle label :cellSize 10,10 :margin 3 :spacing 1)
      (sd-display-error "H871 ver-03: Could not add an internal results tab.")
      (return-from h871-pf-v03-create-page nil))

    (h871-pf-v03-trace "CREATE-PAGE/LOGICAL-TABLE/BEGIN" logical-table)
    (unless (h871-pf-v03-create-logical-table logical-table)
      (sd-display-error "H871 ver-03: Could not create the page's logical table.")
      (return-from h871-pf-v03-create-page nil))

    (h871-pf-v03-trace "CREATE-PAGE/TEXT-CONTROL/BEGIN" (list status-name tab-grid))
    (sd-create-text-control
      status-name tab-grid
      :x 0 :y 0 :width 86 :height 2
      :editable nil :showModified nil)

    (h871-pf-v03-trace "CREATE-PAGE/DISPLAY-TABLE/BEGIN" (list table-name tab-grid logical-table))
    (unless
      (sd-create-display-table-control
        table-name tab-grid
        :x 0 :y 2 :width 86 :height 42
        :logicalTable logical-table
        :columns '(:part-name :density-instance :density-base :assembly-path :part-note)
        :entryAlignment '(:left :right :right :left :left)
        :selectionMode :multiple-rows
        :selectionAction 'h871-pf-v03-table-selection-changed
        :doubleClickAction 'h871-pf-v03-double-click)
      (sd-display-error "H871 ver-03: Could not create the multi-column results table.")
      (return-from h871-pf-v03-create-page nil))

    (h871-pf-v03-trace "CREATE-PAGE/SELECT-ALL-BUTTON/BEGIN" page-name)
    (sd-create-pushbutton-control
      (concatenate 'string page-name "-SELECT-ALL-PB")
      tab-grid
      :x 0 :y 45 :width 14 :height 3
      :title "Select All"
      :pushAction (list 'h871-pf-v03-select-all page-name))

    (h871-pf-v03-trace "CREATE-PAGE/CLEAR-BUTTON/BEGIN" page-name)
    (sd-create-pushbutton-control
      (concatenate 'string page-name "-CLEAR-PB")
      tab-grid
      :x 15 :y 45 :width 16 :height 3
      :title "Clear Selection"
      :pushAction (list 'h871-pf-v03-clear-selection page-name))

    (h871-pf-v03-trace "CREATE-PAGE/APPLY-BUTTON/BEGIN" page-name)
    (sd-create-pushbutton-control
      (concatenate 'string page-name "-APPLY-PB")
      tab-grid
      :x 32 :y 45 :width 12 :height 3
      :title "Apply"
      :pushAction (list 'h871-pf-v03-apply page-name))

    (sd-create-pushbutton-control
      (concatenate 'string page-name "-EDIT-NOTE-PB")
      tab-grid
      :x 45 :y 45 :width 14 :height 3
      :title "Edit Note"
      :pushAction (list 'h871-pf-v03-edit-note page-name))

    ;; Cross-page controls occupy a second button row. The existing page-local
    ;; controls above retain their positions and callbacks.
    (sd-create-pushbutton-control
      (concatenate 'string page-name "-SELECT-ALL-PAGES-PB")
      tab-grid
      :x 0 :y 49 :width 27 :height 3
      :title "Select All Pages"
      :pushAction (list 'h871-pf-v03-select-all-pages nil))

    (sd-create-pushbutton-control
      (concatenate 'string page-name "-CLEAR-ALL-PAGES-PB")
      tab-grid
      :x 28 :y 49 :width 27 :height 3
      :title "Clear All Pages"
      :pushAction (list 'h871-pf-v03-clear-all-pages nil))

    (sd-create-pushbutton-control
      (concatenate 'string page-name "-APPLY-ALL-PAGES-PB")
      tab-grid
      :x 56 :y 49 :width 30 :height 3
      :title "Apply All Pages"
      :pushAction (list 'h871-pf-v03-apply-all-pages nil))

    (push
      (list :instance instance :base base :label label
            :page page-name :table table-name
            :logical-table logical-table :status status-name
            :results nil)
      *h871-pf-v03-pages*)

    (h871-pf-v03-trace "CREATE-PAGE/SET-CURRENT-TAB/BEGIN" (list *h871-pf-v03-tabs* page-name))
    (setf *h871-pf-v03-current-page* page-name)
    (sd-set-current-tab-control-page *h871-pf-v03-tabs* :page page-name)
    (h871-pf-v03-update-status page-name)
    (h871-pf-v03-page-by-name page-name)))

(defun h871-pf-v03-refresh-page (entry parts)
  (h871-pf-v03-trace "REFRESH/BEGIN" (list (getf entry :page) (getf entry :table) (getf entry :logical-table)))
  (let* ((page-name (getf entry :page))
         ;; Pages can survive a LISP reload because these globals are not reset.
         ;; Older in-memory page records may therefore lack :logical-table.
         ;; Always recover the deterministic name from the page identifier.
         (logical-table
           (let ((stored-name (getf entry :logical-table)))
             ;; In Common Lisp, "" is truthy. Do not use OR alone here:
             ;; old page records can contain an explicitly empty table name.
             (if (and (stringp stored-name)
                      (> (length stored-name) 0))
                 stored-name
               (and (stringp page-name)
                    (> (length page-name) 0)
                    (h871-pf-v03-logical-table-name page-name)))))
         (table-name (getf entry :table))
         (contents (h871-pf-v03-table-contents parts)))
    (unless (and (stringp logical-table)
                 (> (length logical-table) 0))
      (sd-display-error
        "H871 ver-03: Invalid logical table name for this Results tab.")
      (return-from h871-pf-v03-refresh-page nil))

    ;; Recover a missing logical table instead of passing NIL/"" to the API.
    ;; This specifically handles stale page metadata retained across LISP reloads.
    (h871-pf-v03-trace "REFRESH/CHECK-LOGICAL-TABLE/BEGIN" logical-table)
    (unless (sd-logical-table-p logical-table)
      (unless (h871-pf-v03-create-logical-table logical-table)
        (sd-display-error
          (format nil
            "H871 ver-03: Could not recreate logical table ~A."
            logical-table))
        (return-from h871-pf-v03-refresh-page nil)))

    ;; Keep the recovered name in the live page record for subsequent refreshes.
    (setf (getf entry :logical-table) logical-table)
    ;; Also repair a stale/blank page identifier before future lookups.
    (unless (and (stringp (getf entry :page))
                 (> (length (getf entry :page)) 0))
      (sd-display-error
        "H871 ver-03: Results tab has no valid page identifier.")
      (return-from h871-pf-v03-refresh-page nil))

    ;; Verify that the Display Table is still bound to this page's logical table.
    ;; A stale control bound to an empty/different name must be recreated.
    (h871-pf-v03-trace "REFRESH/CHECK-DISPLAY-TABLE/BEGIN" table-name)
    (when (and (sd-display-table-p table-name)
               (not (equal
                      (sd-get-display-table-logical-table table-name)
                      logical-table)))
      (sd-destroy-display-table table-name))

    (unless (sd-display-table-p table-name)
      (unless
        (sd-create-display-table-control
          table-name (concatenate 'string page-name "-TAB-GA")
          :x 0 :y 2 :width 86 :height 42
          :logicalTable logical-table
          :columns '(:part-name :density-instance :density-base :assembly-path :part-note)
          :entryAlignment '(:left :right :right :left :left)
          :selectionMode :multiple-rows
          :selectionAction 'h871-pf-v03-table-selection-changed
        :doubleClickAction 'h871-pf-v03-double-click)
        (sd-display-error
          "H871 ver-03: Could not restore the result table control.")
        (return-from h871-pf-v03-refresh-page nil)))

    ;; Capture the row shape before calling the 18.1 logical-table API.
    ;; This is diagnostic only: no row values, filter semantics or UI layout
    ;; are changed. Each row must contain one value for each of the 6 columns.
    (h871-pf-v03-trace
      "REFRESH/CONTENTS-SHAPE"
      (list (length contents)
            (mapcar #'length contents)
            (mapcar (lambda (row) (mapcar #'type-of row)) contents)))

    ;; Replacing logical-table contents refreshes its Display Table in place.
    ;; Selection is cleared so stale object references are never applied.
    (h871-pf-v03-trace "REFRESH/CHANGE-CONTENTS/BEGIN" (list logical-table (length contents)))
    (let ((change-result
            (sd-change-logical-table-contents
              logical-table :contents contents)))
      (h871-pf-v03-trace "REFRESH/CHANGE-CONTENTS/RETURN" change-result)
      (unless change-result
        (sd-display-error
          (format nil
            "H871 ver-03: Could not refresh logical table ~A."
            logical-table))
        (return-from h871-pf-v03-refresh-page nil)))
    (sd-reset-display-table-selection table-name :row t)
    (setf (getf entry :results) parts)
    (setf *h871-pf-v03-current-page* page-name)
    (sd-set-current-tab-control-page *h871-pf-v03-tabs* :page page-name)
    (h871-pf-v03-update-status page-name)
    t))

(defun h871-pf-v03-write-report (assembly matches requested-instance requested-base)
  (let ((report
          (merge-pathnames
            "H871_PART_FILTER_VER_03_RESULT.txt"
            (user-homedir-pathname))))
    (with-open-file
      (s report :direction :output :if-exists :supersede :if-does-not-exist :create)
      (format s "H871 PART FILTER VER-03-PARTNOTE - EXACT DENSITY PAIR~%")
      (format s "Assembly: ~A~%" (h871-pf-v03-path assembly))
      (format s "Density API multiplier: ~A~%" *h871-pf-v03-density-api-multiplier*)
      (format s "Expected raw API Instance: ~A~%" (h871-pf-v03-density-api-value requested-instance))
      (format s "Expected raw API Base: ~A~%" (h871-pf-v03-density-api-value requested-base))
      (format s "Requested Density Instance: ~A~%" requested-instance)
      (format s "Requested Density Base: ~A~%" requested-base)
      (format s "~%RAW DENSITY SAMPLE (first 30 Parts)~%")
      (dolist (sample (reverse *h871-pf-v03-diagnostic-samples*))
        (format s "~S~%" sample))
      (dolist (part matches)
        (format s "~%PART: ~A~%PATH: ~A~%"
          (h871-pf-v03-name part) (h871-pf-v03-path part))))
    report))

(defun h871-pf-v03-run (assembly requested-instance requested-base)
  (h871-pf-v03-trace-reset)
  (h871-pf-v03-trace "RUN/BEGIN" (list (type-of assembly) requested-instance requested-base))
  (h871-pf-v03-trace "DENSITY/API-MULTIPLIER" *h871-pf-v03-density-api-multiplier*)
  ;; Never use display labels as search criteria. Reject missing/non-numeric
  ;; dialog values before touching the assembly or creating any UI.
  (unless (and (numberp requested-instance)
               (numberp requested-base)
               (numberp *h871-pf-v03-density-api-multiplier*)
               (> *h871-pf-v03-density-api-multiplier* 0))
    (sd-display-error
      (format nil
        "H871 ver-03: Invalid density settings. Instance=~S; Base=~S; API multiplier=~S. Filter values must be numeric and API multiplier must be greater than zero."
        requested-instance requested-base
        *h871-pf-v03-density-api-multiplier*))
    (return-from h871-pf-v03-run nil))
  (let ((matches nil)
        (entry nil)
        (report nil))
    (setf *h871-pf-v03-diagnostic-samples* nil)
    (setf *h871-pf-v03-collect-visited-count* 0)
    (setf *h871-pf-v03-assembly* assembly)
    (h871-pf-v03-trace "COLLECT/BEGIN" (h871-pf-v03-path assembly))
    (setf matches
      (h871-pf-v03-collect assembly nil requested-instance requested-base))
    (h871-pf-v03-trace "RUN/COLLECT-DONE" (length matches))
    (setf report
      (h871-pf-v03-write-report assembly matches requested-instance requested-base))
    (h871-pf-v03-trace "RUN/REPORT-DONE" report)

    ;; No-match must not modify or replace any existing tab.
    (when (null matches)
      (sd-display-message
        (format nil
          "No Parts matched Density Instance ~A and Density Base ~A.~%Existing Results tabs were kept unchanged.~%Report: ~A"
          requested-instance requested-base (namestring report)))
      (return-from h871-pf-v03-run (values 0 report)))

    (h871-pf-v03-trace "RUN/CREATE-SHELL/BEGIN" nil)
    (unless (h871-pf-v03-create-shell)
      (return-from h871-pf-v03-run nil))

    (h871-pf-v03-trace "RUN/FIND-PAGE/BEGIN" (list requested-instance requested-base))
    (setf entry (h871-pf-v03-find-page requested-instance requested-base))
    (h871-pf-v03-trace "RUN/FIND-PAGE/DONE" (list (getf entry :page) (getf entry :table) (getf entry :logical-table)))
    (unless entry
      (setf entry (h871-pf-v03-create-page requested-instance requested-base)))
    (unless entry
      (return-from h871-pf-v03-run nil))

    (unless (h871-pf-v03-refresh-page entry matches)
      (return-from h871-pf-v03-run nil))

    (unless (sd-dialog-shell-visible-p *h871-pf-v03-shell*)
      (sd-show-dialog-shell *h871-pf-v03-shell*))

    (values (length matches) report)))

;; ---------------------------------------------------------------------------
;; Search dialog - mappings are identical to ver-02.
;; ---------------------------------------------------------------------------

(sd-defdialog 'h871_part_filter_ver_03
  :dialog-title "H871 - PART FILTER VER-03-PARTNOTE"
  :variables
  '(
    ("ASSEMBLY")
    (ASSEMBLY
      :value-type :assembly
      :title "Select Assembly"
      :prompt-text "Select assembly to scan.")

    ("MACHINING PROCESS")
    (MACHINING_PROCESS
      :range ((-1 :label "ALL")
              (1 :label "CNC")
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
      :range ((-1 :label "ALL")
              (6061 :label "A6061")
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
     (h871-pf-v03-run-filter assembly machining_process material)
     (sd-return-from-ok-action)))


;; ---------------------------------------------------------------------------
;; Per-Part Note editor
;; ---------------------------------------------------------------------------
;; The selected real Part object is captured from the active UICT result row.
;; sd-put-buffer launches this interactive dialog after the UICT callback
;; returns; do not wrap this dialog in sd-call-cmds.
;; ---------------------------------------------------------------------------

(sd-defdialog 'h871_pf_v03_note_editor
  :dialog-title "H871 - EDIT PART NOTE (VER-03)"
  :after-initialization
    '(setq NOTE
       (h871-pf-v03-read-note *h871-pf-v03-note-edit-part*))
  :variables
  '((NOTE
      :value-type :string
      :title "Part Note"
      :initial-value ""))
  :ok-action
  '(progn
     (if (and *h871-pf-v03-note-edit-part*
              (h871-pf-v03-write-note *h871-pf-v03-note-edit-part* NOTE))
         (progn
           (sd-display-message "Part Note saved.")
           ;; Rebuild the active page rows so the Part Note column redraws.
           ;; This uses the existing VER-03 refresh path; Apply logic is untouched.
           (let ((entry
                   (h871-pf-v03-page-by-name *h871-pf-v03-note-edit-page*)))
             (when entry
               (h871-pf-v03-refresh-page entry (getf entry :results)))))
       (sd-display-error "H871: Could not save the Part Note."))))

;; LOAD:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER_VER_03_PARTNOTE_ALLPAGES.lsp")
;; COMMAND:
;; H871_PART_FILTER_VER_03
;;
;; RUNTIME TEST:
;; 1. Search CNC + SUS304; expect a multi-column table in CNC-SUS304 tab.
;; 1a. Search ALL + SUS304; expect only populated process/SUS304 tabs.
;; 1b. Search CNC + ALL; expect only populated CNC/material tabs.
;; 1c. Search ALL + ALL; expect only populated tabs from the 36 mapped pairs.
;; 2. Search KH + A6061; expect a second tab in the same Results window.
;; 3. Repeat CNC + SUS304; expect that page to refresh without duplication.
;; 4. Click individual rows and Ctrl/Shift-select multiple rows.
;; 5. Select All selects every row in the active tab only.
;; 6. Select All Pages selects every row across all existing tabs.
;; 7. Clear Selection clears only the active tab; Clear All Pages clears all.
;; 8. Apply transfers selected Parts from the active tab only.
;; 9. Apply All Pages transfers the union of selected Parts from all tabs.
;; 10. Switch tabs and verify each page's selection remains independent.
;; 11. Refresh a pair; that page's selection is cleared to avoid stale Parts.
;;
;; COMPATIBILITY NOTE:
;; The Display Table and logical-table APIs are documented in PTC 20.7.
;; Modeling 18.1 runtime compatibility and the hidden Apply bridge must be
;; tested before treating this revision as production-ready.