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
(defvar *h871-pf-results-assembly* nil)
(defvar *h871-pf-requested-instance* nil)
(defvar *h871-pf-requested-base* nil)

(defvar *h871-pf-browser-name* "h871-pf-results")
(defvar *h871-pf-tree-name* "h871-pf-results-tree")

(defun h871-pf-name (obj)
  (or (sd-inq-obj-basename obj) "<NO NAME>"))

(defun h871-pf-path (obj)
  (or (sd-inq-obj-pathname obj) "<NO PATH>"))

(defun h871-pf-density-pair-match (part requested-instance requested-base)
  (let ((actual-instance (sd-inq-part-density part :instance))
        (actual-base (sd-inq-part-density part :contents)))
    (and (numberp actual-instance)
         (numberp actual-base)
         (= actual-instance requested-instance)
         (= actual-base requested-base))))

;; ------------------------------------------------------------
;; Filter engine - keep predicates separate from result UI
;; ------------------------------------------------------------

(defun h871-pf-collect (obj matches requested-instance requested-base)
  (when (sd-inq-part-p obj)
    (when (h871-pf-density-pair-match
            obj requested-instance requested-base)
      (push obj matches)))
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
                  :instance instance
                  :base base))))
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
      (format nil "~A result row(s) selected." (length parts)))))

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
      :maxWidth 1150
      :maxHeight 760
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
               :push (h871-pf-show-selection-summary)))))
    (sd-display-error "H871: Could not create the results browser.")
    (return-from h871-pf-open-results-browser nil))

  (unless
    (sd-browser-define-table
      *h871-pf-browser-name*
      :table-name "h871-pf-bom"
      :with-name-column nil
      :column-definition
        '((:label "Part Name"
           :type :string-column
           :display-func h871-pf-column-name
           :initial-width 190)
          (:label "Density Instance"
           :type :string-column
           :display-func h871-pf-column-instance
           :initial-width 110)
          (:label "Density Base"
           :type :string-column
           :display-func h871-pf-column-base
           :initial-width 100)
          (:label "Assembly Path"
           :type :string-column
           :display-func h871-pf-column-path
           :initial-width 360)))
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
      (dolist (part matches)
        (format s "~%PART: ~A~%" (h871-pf-name part))
        (format s "PATH: ~A~%" (h871-pf-path part))
        (format s "DENSITY INSTANCE: ~A~%"
          (sd-inq-part-density part :instance))
        (format s "DENSITY BASE: ~A~%"
          (sd-inq-part-density part :contents))))
    report))

(defun h871-pf-run (assembly requested-instance requested-base)
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
          (format nil
            "~A matching Part(s). Select rows; use Selection menu for Select All/Clear Selection."
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
  '(h871-pf-run assembly density_instance density_base))

;; LOAD:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER.lsp")
;; COMMAND:
;; H871_PART_FILTER
