;; ============================================================
;; H871 PART FILTER - Results Browser architecture
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Search: exact Density Instance + Density Base pair.
;; Results: dedicated Graphical Browser with BOM-like table.
;; Row selection: native Graphical Browser selection state.
;; Select All / Clear Selection: browser commands.
;;
;; IMPORTANT:
;; Graphical Browser APIs are documented in later PTC Integration
;; Kit references. This source is a compatibility implementation
;; candidate and must be loaded/tested in Creo 18.1.
;; ============================================================

(in-package :oli)

(defvar *h871-pf-results* nil)
(defvar *h871-pf-diagnostic-samples* nil)
(defvar *h871-pf-results-assembly* nil)
(defvar *h871-pf-requested-instance* nil)
(defvar *h871-pf-requested-base* nil)

(defvar *h871-pf-browser-name* "h871-pf-results")
(defvar *h871-pf-tree-name* "h871-pf-results-tree")

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

(defun h871-pf-build-results-tree ()
  ;; Called by the Graphical Browser when its tree is built/refreshed.
  (let ((root
          (sd-create-browsernode
            :tree *h871-pf-tree-name*
            :parent nil
            :objPath "/H871_RESULTS"
            :objPname "H871 Part Filter Results"
            :objClientData (list :kind :root))))
    (dolist (part (reverse *h871-pf-results*))
      (let ((instance (sd-inq-part-density part :instance))
            (base (sd-inq-part-density part :contents))
            (path (h871-pf-path part)))
        (sd-create-browsernode
          :tree *h871-pf-tree-name*
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
    root))

(defun h871-pf-select-all ()
  (sd-browser-exec-cmd *h871-pf-browser-name* :select-all))

(defun h871-pf-clear-selection ()
  (sd-browser-exec-cmd *h871-pf-browser-name* :clear-select-list))

(defun h871-pf-selected-parts ()
  (let ((parts nil))
    (dolist (node
              (sd-query-browser
                *h871-pf-browser-name* :get-selected-objects))
      (let ((data (h871-pf-row-data node)))
        (when (eq (getf data :kind) :part)
          (push (getf data :part) parts))))
    (nreverse parts)))

(defun h871-pf-show-selection-summary ()
  (let ((parts (h871-pf-selected-parts)))
    (sd-browser-set-status-text
      *h871-pf-browser-name*
      :value (format nil "~A result row(s) selected." (length parts)))))

(defun h871-pf-open-results-browser ()
  ;; Recreate browser/tree so every search has a clean result set.
  (ignore-errors
    (sd-hide-graphical-browser *h871-pf-browser-name*))
  (ignore-errors
    (sd-destroy-graphical-browser *h871-pf-browser-name*))
  (ignore-errors
    (sd-destroy-browser-tree *h871-pf-tree-name*))

  (unless
    (sd-create-browser-tree
      *h871-pf-tree-name*
      :update-events oli:*SD-CHANGE-OBJECT-TREE-EVENT*
      :update-func 'h871-pf-build-results-tree)
    (sd-display-error "H871: Could not create the results data tree.")
    (return-from h871-pf-open-results-browser nil))

  (unless
    (sd-create-graphical-browser
      *h871-pf-browser-name*
      :tree *h871-pf-tree-name*
      :topLabel "H871 - PART FILTER RESULTS"
      :treeStatusBar
        (format nil "Matched ~A Part(s). Select rows; Ctrl-click adds/removes."
          (length *h871-pf-results*))
      :minHeight 280
      :maxWidth 900
      :maxHeight 760
      :buttonMenu
        '(("select-all"
           :label "Select All"
           :push (h871-pf-select-all))
          ("clear-selection"
           :label "Clear Selection"
           :push (h871-pf-clear-selection)))
      :buttonMenuOffObjectOnly nil
      :topMenu
        '(("selection"
           :label "Selection"
           :contents
             (("select-all"
               :label "Select All"
               :push (h871-pf-select-all))
              ("clear-selection"
               :label "Clear Selection"
               :push (h871-pf-clear-selection))
              ("selection-summary"
               :label "Update Selection Count"
               :push (h871-pf-show-selection-summary))))))
    (sd-display-error "H871: Could not create the results browser.")
    (return-from h871-pf-open-results-browser nil))

  (unless
    (sd-browser-define-table
      *h871-pf-browser-name*
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
    (sd-display-error "H871: Could not create the BOM result table.")
    (return-from h871-pf-open-results-browser nil))

  (sd-browser-set-active-table
    *h871-pf-browser-name* :table-name "h871-pf-bom")
  (sd-browser-exec-cmd *h871-pf-browser-name* :set-table-mode)
  (sd-show-graphical-browser *h871-pf-browser-name*)

  ;; Root node is the table root; the table displays all matching Parts.
  (let ((root (sd-get-browsernode-struct *h871-pf-tree-name* :root)))
    (when root
      (sd-browser-exec-cmd
        *h871-pf-browser-name* :change-table-root root t)))
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
  (setf *h871-pf-diagnostic-samples* nil)
  (setf *h871-pf-results-assembly* assembly)
  (setf *h871-pf-requested-instance* requested-instance)
  (setf *h871-pf-requested-base* requested-base)
  (setf *h871-pf-results*
    (h871-pf-collect
      assembly nil requested-instance requested-base))
  (let ((report
          (h871-pf-write-report
            assembly *h871-pf-results*
            requested-instance requested-base)))
    (if (null *h871-pf-results*)
        (sd-display-message
          (format nil
            "No Parts matched Density Instance ~A and Density Base ~A.~%Report: ~A"
            requested-instance requested-base (namestring report)))
      (progn
        (unless (h871-pf-open-results-browser)
          (return-from h871-pf-run nil))
        (sd-browser-set-status-text
          *h871-pf-browser-name*
          :value (format nil
            "~A matching Part(s). Select rows; use Select All/Clear Selection buttons."
            (length *h871-pf-results*)))))
    (values (length *h871-pf-results*) report)))

;; ------------------------------------------------------------
;; Dialog entry point
;; ------------------------------------------------------------

(sd-defdialog 'h871_part_filter
  :dialog-title "H871 - PART FILTER"
  :variables
  '(
    ("ASSEMBLY")
    (ASSEMBLY
      :value-type :assembly
      :title "Select Assembly"
      :prompt-text "Select assembly to scan.")

    ("DENSITY - EXACT MATCH")
    (DENSITY_INSTANCE
      :value-type :number
      :initial-value 1.0
      :title "Density Instance")

    (DENSITY_BASE
      :value-type :number
      :initial-value 304.0
      :title "Density Base")
  )
  :ok-action
  '(progn
     (h871-pf-run assembly density_instance density_base)
     ;; Keep the input dialog active so the user can change the
     ;; density pair and run another search without reopening it.
     (sd-return-from-ok-action)))

;; LOAD:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER.lsp")
;; COMMAND:
;; H871_PART_FILTER
