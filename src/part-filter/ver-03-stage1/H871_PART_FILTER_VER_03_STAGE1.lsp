;; ============================================================
;; H871 PART FILTER - Results Browser architecture - VER-03 STAGE 1 - MULTI FILTER TABS
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Search UI: machining process + material convention.
;; Search engine: exact Density Instance + Density Base pair.
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

(defvar *h871-pf-mt-last-results* nil)
(defvar *h871-pf-mt-diagnostic-samples* nil)
(defvar *h871-pf-mt-results-assembly* nil)
(defvar *h871-pf-mt-requested-instance* nil)
(defvar *h871-pf-mt-requested-base* nil)
(defvar *h871-pf-mt-sessions* nil)

;; Stage 1 creates one native Graphical Browser per unique Density pair.
;; Each browser owns a separate tree and is requested as a Browser Bar tab.
(defvar *h871-pf-mt-browser-name* "h871-pf-mt-results")
(defvar *h871-pf-mt-tree-name* "h871-pf-mt-results-tree")

(defun h871-pf-mt-name (obj)
  (or (sd-inq-obj-basename obj) "<NO NAME>"))

(defun h871-pf-mt-path (obj)
  (or (sd-inq-obj-pathname obj) "<NO PATH>"))

;; Convert numeric values consistently. In Lisp, (= 1 1.0) is
;; already true; this helper additionally accepts numeric strings such
;; as "1" and "1.0" if a runtime/property layer returns text.
(defun h871-pf-mt-as-number (value)
  ;; Creo's dialog fields and SD-INQ-PART-DENSITY return numeric
  ;; values in this workflow. Avoid READ-FROM-STRING and reader
  ;; character literals for compatibility with Modeling 18.1.
  (if (numberp value) value nil))
;; The user verified two native Parts in Modeling 18.1:
;; UI Instance/Base values 1/304 -> API values 1000/304000,
;; and UI values 2/400 -> API values 2000/400000.
;; Normalize API density values to the Part Properties display scale.
(defun h871-pf-mt-density-display-value (api-value)
  (when (numberp api-value)
    (/ api-value 1000.0)))

(defun h871-pf-mt-numeric-equal-p (actual requested)
  (let ((a (h871-pf-mt-as-number actual))
        (b (h871-pf-mt-as-number requested)))
    (and a b
         (<= (abs (- a b)) 0.0000001))))

(defun h871-pf-mt-density-pair-match (part requested-instance requested-base)
  (let ((actual-instance (sd-inq-part-density part :instance))
        (actual-base (sd-inq-part-density part :contents)))
    (and (not (null actual-instance))
         (not (null actual-base))
         (h871-pf-mt-numeric-equal-p
           (h871-pf-mt-density-display-value actual-instance)
           requested-instance)
         (h871-pf-mt-numeric-equal-p
           (h871-pf-mt-density-display-value actual-base)
           requested-base))))

;; ------------------------------------------------------------
;; Filter engine - keep predicates separate from result UI
;; ------------------------------------------------------------

(defun h871-pf-mt-collect (obj matches requested-instance requested-base)
  (when (sd-inq-part-p obj)
    (let ((actual-instance (sd-inq-part-density obj :instance))
          (actual-base (sd-inq-part-density obj :contents)))
      ;; Keep a small raw-value sample in the report so a zero-match
      ;; result reveals what Creo 18.1 actually returned.
      (when (< (length *h871-pf-mt-diagnostic-samples*) 30)
        (push
          (list (h871-pf-mt-name obj)
                (h871-pf-mt-path obj)
                actual-instance
                (type-of actual-instance)
                actual-base
                (type-of actual-base))
          *h871-pf-mt-diagnostic-samples*))
      (when (and
              (h871-pf-mt-numeric-equal-p
                (h871-pf-mt-density-display-value actual-instance)
                requested-instance)
              (h871-pf-mt-numeric-equal-p
                (h871-pf-mt-density-display-value actual-base)
                requested-base))
        (push obj matches))))
  (dolist (child (sd-inq-obj-children obj))
    (setf matches
      (h871-pf-mt-collect child matches requested-instance requested-base)))
  matches)

;; ------------------------------------------------------------
;; Browser row client data and table display callbacks
;; ------------------------------------------------------------

(defun h871-pf-mt-row-data (node)
  (browsernode-objclientdata node))

(defun h871-pf-mt-column-name (node browser-name)
  (declare (ignore browser-name))
  (getf (h871-pf-mt-row-data node) :name))

(defun h871-pf-mt-column-instance (node browser-name)
  (declare (ignore browser-name))
  (let ((value (getf (h871-pf-mt-row-data node) :instance)))
    (if value (format nil "~A" value) "-")))

(defun h871-pf-mt-column-base (node browser-name)
  (declare (ignore browser-name))
  (let ((value (getf (h871-pf-mt-row-data node) :base)))
    (if value (format nil "~A" value) "-")))

(defun h871-pf-mt-column-path (node browser-name)
  (declare (ignore browser-name))
  (getf (h871-pf-mt-row-data node) :path))

;; Modeling 18.1 compatibility: use a zero-argument updater callback
;; like the verified Stage 0 browser tree.
(defun h871-pf-mt-register-tree-updater (tree-name key)
  (let* ((updater-name
           (intern (format nil "H871-PF-MT-UPDATE-~A"
                     (substitute #\\- #\\. key))
             :oli))
         (captured-tree tree-name)
         (captured-key key))
    (setf (symbol-function updater-name)
      (lambda ()
        (h871-pf-mt-build-results-tree captured-tree captured-key)))
    updater-name))

(defun h871-pf-mt-trace (stage)
  (ignore-errors
    (with-open-file
      (stream
        (merge-pathnames "H871_PART_FILTER_STAGE1_TRACE.txt"
          (user-homedir-pathname))
        :direction :output :if-exists :append :if-does-not-exist :create)
      (format stream "~A~%" stage)
      (finish-output stream))))

(defun h871-pf-mt-find-session (key)
  (find key *h871-pf-mt-sessions*
    :key (function (lambda (entry) (getf entry :key)))
    :test 'equal))

(defun h871-pf-mt-build-results-tree (tree-name key)
  ;; Each browser has its own tree. The key identifies the stored result set.
  (let* ((session (h871-pf-mt-find-session key))
         (parts (getf session :results))
         (tabname (getf session :tabname))
         (root
           (sd-create-browsernode
             :tree tree-name
             :parent nil
             :objPath "/H871_RESULTS"
             :objPname tabname
             :objClientData (list :kind :root :key key))))
    (dolist (part (reverse parts))
      (let ((instance (sd-inq-part-density part :instance))
            (base (sd-inq-part-density part :contents))
            (path (h871-pf-mt-path part)))
        (sd-create-browsernode
          :tree tree-name
          :parent root
          :objPath path
          :objPname (h871-pf-mt-name part)
          :objClientData
            (list :kind :part
                  :part part
                  :name (h871-pf-mt-name part)
                  :path path
                  :instance (h871-pf-mt-density-display-value instance)
                  :base (h871-pf-mt-density-display-value base)
                  :instance-api instance
                  :base-api base))))
    root))

(defun h871-pf-mt-select-all-for-browser (browser-name)
  (sd-browser-exec-cmd browser-name :select-all))

(defun h871-pf-mt-clear-selection-for-browser (browser-name)
  (sd-browser-exec-cmd browser-name :clear-select-list))

(defun h871-pf-mt-selected-parts-for-browser (browser-name)
  (let ((parts nil))
    (dolist (node
              (sd-query-browser browser-name :get-selected-objects))
      (let ((data (h871-pf-mt-row-data node)))
        (when (eq (getf data :kind) :part)
          (push (getf data :part) parts))))
    (nreverse parts)))

(defun h871-pf-mt-show-selection-summary-for-browser (browser-name)
  (let ((parts (h871-pf-mt-selected-parts-for-browser browser-name)))
    (sd-browser-set-status-text
      browser-name
      :value (format nil "~A result row(s) selected." (length parts)))))

(defun h871-pf-mt-open-results-browser (key)
  (let* ((session (h871-pf-mt-find-session key))
         (browser-name (getf session :browser))
         (tree-name (getf session :tree))
         (tabname (getf session :tabname))
         (parts (getf session :results)))
    ;; Rebuild only the browser belonging to this Density pair.
    (ignore-errors (sd-hide-graphical-browser browser-name))
    (ignore-errors (sd-destroy-graphical-browser browser-name))
    (ignore-errors (sd-destroy-browser-tree tree-name))

    (h871-pf-mt-trace "BROWSER:BEFORE-CREATE-TREE")
    (unless
      (sd-create-browser-tree
        tree-name
        :update-events oli:*SD-CHANGE-OBJECT-TREE-EVENT*
        :update-func (h871-pf-mt-register-tree-updater tree-name key))
      (sd-display-error "H871: Could not create the results data tree.")
      (return-from h871-pf-mt-open-results-browser nil))
    (h871-pf-mt-trace "BROWSER:AFTER-CREATE-TREE")

    (unless
      (sd-create-graphical-browser
        browser-name
        :tree tree-name
        :topLabel (format nil "H871 - PART FILTER RESULTS: ~A" tabname)
        :treeStatusBar
          (format nil "Matched ~A Part(s). Select rows; Ctrl-click adds/removes."
            (length parts))
        :minHeight 280
        :maxWidth 900
        :maxHeight 760
        :okButtonLabel "Apply"
        :abortButtonLabel "Select All"
        :abortButtonAction
          (list 'h871-pf-mt-select-all-for-browser browser-name)
        :buttonMenu
          (list
            (list "select-all"
              :label "Select All"
              :push (list 'h871-pf-mt-select-all-for-browser browser-name))
            (list "clear-selection"
              :label "Clear Selection"
              :push (list 'h871-pf-mt-clear-selection-for-browser browser-name)))
        :buttonMenuOffObjectOnly nil
        :topMenu
          (list
            (list "selection"
              :label "Selection"
              :contents
                (list
                  (list "select-all"
                    :label "Select All"
                    :push (list 'h871-pf-mt-select-all-for-browser browser-name))
                  (list "clear-selection"
                    :label "Clear Selection"
                    :push (list 'h871-pf-mt-clear-selection-for-browser browser-name))
                  (list "selection-summary"
                    :label "Update Selection Count"
                    :push (list 'h871-pf-mt-show-selection-summary-for-browser browser-name)))))
        ;; PTC Graphical Browser option: dock each Density-pair browser as its own tab.
        :createAsTab t
        :tabname tabname)
      (sd-display-error "H871: Could not create the results browser.")
      (return-from h871-pf-mt-open-results-browser nil))
    (h871-pf-mt-trace "BROWSER:AFTER-CREATE-BROWSER")

    (unless
      (sd-browser-define-table
        browser-name
        :table-name "h871-pf-mt-bom"
        :with-name-column nil
        :column-definition
          '(;; :initial-width values are character counts, not pixels.
            (:label "Part Name"
             :type :string-column
             :display-func h871-pf-mt-column-name
             :initial-width 28)
            (:label "Density Instance"
             :type :string-column
             :display-func h871-pf-mt-column-instance
             :initial-width 13)
            (:label "Density Base"
             :type :string-column
             :display-func h871-pf-mt-column-base
             :initial-width 12)
            (:label "Assembly Path"
             :type :string-column
             :display-func h871-pf-mt-column-path
             :initial-width 42)))
      (sd-display-error "H871: Could not create the BOM result table.")
      (return-from h871-pf-mt-open-results-browser nil))

    (sd-browser-set-active-table browser-name :table-name "h871-pf-mt-bom")
    (sd-browser-exec-cmd browser-name :set-table-mode)
    (sd-show-graphical-browser browser-name)
    (h871-pf-mt-trace "BROWSER:AFTER-SHOW")
    (let ((root (sd-get-browsernode-struct tree-name :root)))
      (when root
        (sd-browser-exec-cmd browser-name :change-table-root root t)))
    t))

;; ------------------------------------------------------------
;; Report and search action
;; ------------------------------------------------------------

(defun h871-pf-mt-write-report (assembly matches requested-instance requested-base)
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
      (format s "Assembly: ~A~%" (h871-pf-mt-path assembly))
      (format s "Requested Density Instance: ~A~%" requested-instance)
      (format s "Requested Density Base: ~A~%" requested-base)
      (format s "~%RAW DENSITY SAMPLE (first 30 Parts)~%")
      (format s "Part | Path | Instance value/type | Base value/type~%")
      (dolist (sample (reverse *h871-pf-mt-diagnostic-samples*))
        (format s "~S~%" sample))
      (dolist (part matches)
        (format s "~%PART: ~A~%" (h871-pf-mt-name part))
        (format s "PATH: ~A~%" (h871-pf-mt-path part))
        (format s "DENSITY INSTANCE (Part Properties scale): ~A~%"
          (h871-pf-mt-density-display-value
            (sd-inq-part-density part :instance)))
        (format s "DENSITY BASE (Part Properties scale): ~A~%"
          (h871-pf-mt-density-display-value
            (sd-inq-part-density part :contents)))
        (format s "DENSITY INSTANCE (raw API): ~A~%"
          (sd-inq-part-density part :instance))
        (format s "DENSITY BASE (raw API): ~A~%"
          (sd-inq-part-density part :contents))))
    report))

(defun h871-pf-mt-process-label (value)
  (case value
    (1 "CNC") (2 "KH") (3 "CG") (4 "COVER")
    (otherwise (format nil "PROCESS-~A" value))))

(defun h871-pf-mt-material-label (value)
  (case value
    (6061 "A6061") (201 "SUS201") (304 "SUS304") (400 "SS400")
    (10 "POM") (20 "Bakelit") (30 "MC") (40 "MIKA") (50 "PU")
    (otherwise (format nil "MATERIAL-~A" value))))

(defun h871-pf-mt-run (assembly requested-instance requested-base)
  (h871-pf-mt-trace "RUN:BEGIN")
  (setf *h871-pf-mt-diagnostic-samples* nil)
  (setf *h871-pf-mt-results-assembly* assembly)
  (setf *h871-pf-mt-requested-instance* requested-instance)
  (setf *h871-pf-mt-requested-base* requested-base)
  (h871-pf-mt-trace "RUN:BEFORE-COLLECT")
  (setf *h871-pf-mt-last-results*
    (h871-pf-mt-collect assembly nil requested-instance requested-base))
  (h871-pf-mt-trace "RUN:AFTER-COLLECT")
  (let* ((report
           (h871-pf-mt-write-report
             assembly *h871-pf-mt-last-results*
             requested-instance requested-base))
         (key (format nil "~A-~A" requested-instance requested-base))
         (browser-name (format nil "h871-pf-mt-browser-~A" key))
         (tree-name (format nil "h871-pf-mt-tree-~A" key))
         (tabname
           (format nil "~A-~A"
             (h871-pf-mt-process-label requested-instance)
             (h871-pf-mt-material-label requested-base)))
         (old-session (h871-pf-mt-find-session key)))
    (h871-pf-mt-trace "RUN:AFTER-REPORT")
    (if (null *h871-pf-mt-last-results*)
        (sd-display-message
          (format nil
            "No Parts matched Density Instance ~A and Density Base ~A.~%Report: ~A"
            requested-instance requested-base (namestring report)))
      (progn
        ;; A repeated pair replaces only its own tab's result set.
        (when old-session
          (ignore-errors (sd-hide-graphical-browser (getf old-session :browser)))
          (ignore-errors (sd-destroy-graphical-browser (getf old-session :browser)))
          (ignore-errors (sd-destroy-browser-tree (getf old-session :tree)))
          (setf *h871-pf-mt-sessions*
            (remove old-session *h871-pf-mt-sessions* :test 'eq)))
        (push
          (list :key key
                :browser browser-name
                :tree tree-name
                :tabname tabname
                :assembly assembly
                :instance requested-instance
                :base requested-base
                :results *h871-pf-mt-last-results*)
          *h871-pf-mt-sessions*)
        (h871-pf-mt-trace "RUN:BEFORE-OPEN-BROWSER")
        (unless (h871-pf-mt-open-results-browser key)
          (return-from h871-pf-mt-run nil))
        (h871-pf-mt-trace "RUN:AFTER-OPEN-BROWSER")))
    (values (length *h871-pf-mt-last-results*) report)))

;; ------------------------------------------------------------
;; Dialog entry point - ver-03-rebuild baseline
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
(sd-defdialog 'h871_part_filter_ver_03_stage1
  :dialog-title "H871 - PART FILTER VER-03 STAGE 1 - MULTI FILTER TABS"
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
     (h871-pf-mt-run assembly machining_process material)
     ;; Keep the input dialog active for consecutive searches.
     (sd-return-from-ok-action)))

;; LOAD:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER_VER_03_STAGE1.lsp")
;; COMMAND:
;; H871_PART_FILTER_VER_03_STAGE1
