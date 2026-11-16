;; ============================================================================
;; H871 PART FILTER - VER-04 EXPERIMENT: UICT MANAGER + MULTIPLE NATIVE BROWSERS
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Architecture:
;; - UICT Display Table is a Results Manager only (one row per density pair).
;; - Each Density Instance + Density Base pair owns one native Graphical Browser.
;; - Browser/tree names are deterministic from numeric codes: ...-1-304.
;; - Re-filtering the same pair replaces that pair's browser/tree data.
;; - No-match searches never overwrite an existing pair.
;; - Part selection and Apply remain entirely native to Graphical Browser.
;;
;; IMPORTANT:
;; This is an isolated experiment. VER-02 and VER-03 are unchanged.
;; UICT signatures are based on the existing VER-03 source and still require
;; Modeling 18.1 runtime validation. Multiple simultaneous native browsers,
;; independent tree refresh, and repeated replacement are NOT yet confirmed.
;; ============================================================================

(in-package :oli)

(defvar *h871-pf-v04-manager* "H871-PF-V04-MANAGER")
(defvar *h871-pf-v04-grid* "H871-PF-V04-GRID")
(defvar *h871-pf-v04-table* "H871-PF-V04-DISPLAY-TABLE")
(defvar *h871-pf-v04-logical-table* "H871-PF-V04-LOGICAL-TABLE")
(defvar *h871-pf-v04-open-button* "H871-PF-V04-OPEN-BROWSER")
(defvar *h871-pf-v04-pairs* nil)
(defvar *h871-pf-v04-active-parts* nil)
(defvar *h871-pf-v04-active-instance* nil)
(defvar *h871-pf-v04-active-base* nil)
(defvar *h871-pf-v04-diagnostic-samples* nil)
(defvar *h871-pf-v04-visited-count* 0)

;; ---------------------------------------------------------------------------
;; Shared filter logic. Keep the exact Density Instance + Density Base rule.
;; ---------------------------------------------------------------------------

(defun h871-pf-v04-name (obj)
  (or (sd-inq-obj-basename obj) "<NO NAME>"))

(defun h871-pf-v04-path (obj)
  (or (sd-inq-obj-pathname obj) "<NO PATH>"))

(defun h871-pf-v04-density-display-value (api-value)
  (when (numberp api-value) (/ api-value 1000.0)))

(defun h871-pf-v04-numeric-equal-p (actual requested)
  (and (numberp actual) (numberp requested)
       (<= (abs (- actual requested)) 0.0000001)))

(defun h871-pf-v04-collect (obj matches requested-instance requested-base)
  (incf *h871-pf-v04-visited-count*)
  (when (sd-inq-part-p obj)
    (let ((actual-instance (sd-inq-part-density obj :instance))
          (actual-base (sd-inq-part-density obj :contents)))
      (when (< (length *h871-pf-v04-diagnostic-samples*) 30)
        (push (list (h871-pf-v04-name obj) (h871-pf-v04-path obj)
                    actual-instance (type-of actual-instance)
                    actual-base (type-of actual-base))
              *h871-pf-v04-diagnostic-samples*))
      (when (and actual-instance actual-base
                 (h871-pf-v04-numeric-equal-p
                   (h871-pf-v04-density-display-value actual-instance)
                   requested-instance)
                 (h871-pf-v04-numeric-equal-p
                   (h871-pf-v04-density-display-value actual-base)
                   requested-base))
        (push obj matches))))
  (dolist (child (sd-inq-obj-children obj))
    (setf matches
      (h871-pf-v04-collect child matches requested-instance requested-base)))
  matches)

(defun h871-pf-v04-process-label (value)
  (or (cadr (assoc value
        '((1 "CNC") (2 "KH") (3 "CG") (4 "COVER"))))
      (format nil "P~A" value)))

(defun h871-pf-v04-material-label (value)
  (or (cadr (assoc value
        '((6061 "A6061") (201 "SUS201") (304 "SUS304") (400 "SS400")
          (10 "POM") (20 "Bakelit") (30 "MC") (40 "MIKA") (50 "PU"))))
      (format nil "M~A" value)))

(defun h871-pf-v04-pair-label (instance base)
  (format nil "~A-~A"
    (h871-pf-v04-process-label instance)
    (h871-pf-v04-material-label base)))

(defun h871-pf-v04-browser-name (instance base)
  (format nil "H871-PF-BROWSER-~A-~A" instance base))

(defun h871-pf-v04-tree-name (instance base)
  (format nil "H871-PF-TREE-~A-~A" instance base))

(defun h871-pf-v04-find-pair (instance base)
  (find-if (lambda (entry)
             (and (= (getf entry :instance) instance)
                  (= (getf entry :base) base)))
           *h871-pf-v04-pairs*))

;; ---------------------------------------------------------------------------
;; UICT Results Manager. It never stores Part objects and never performs Apply.
;; ---------------------------------------------------------------------------

(defun h871-pf-v04-manager-contents ()
  (let ((rows nil) (n 0))
    (dolist (entry (reverse *h871-pf-v04-pairs*))
      (push
        (list (incf n)
              (h871-pf-v04-pair-label
                (getf entry :instance) (getf entry :base))
              (h871-pf-v04-process-label (getf entry :instance))
              (h871-pf-v04-material-label (getf entry :base))
              (getf entry :count)
              (getf entry :browser)
              (getf entry :instance)
              (getf entry :base))
        rows))
    (nreverse rows)))

(defun h871-pf-v04-refresh-manager ()
  (when (sd-logical-table-p *h871-pf-v04-logical-table*)
    (sd-change-logical-table-contents
      *h871-pf-v04-logical-table*
      :contents (h871-pf-v04-manager-contents)))
  t)

(defun h871-pf-v04-create-manager ()
  (unless (sd-dialog-shell-p *h871-pf-v04-manager*)
    (unless
      (sd-create-dialog-shell
        *h871-pf-v04-manager*
        :title "H871 - RESULTS MANAGER VER-04"
        :bottomLine :none
        :closeAction
          (list 'sd-hide-dialog-shell *h871-pf-v04-manager* :ignorePin t)
        :margin 4)
      (sd-display-error "H871 VER-04: Cannot create Results Manager.")
      (return-from h871-pf-v04-create-manager nil)))
  (unless (sd-control-p *h871-pf-v04-grid*)
    (unless
      (sd-append-grid-area
        *h871-pf-v04-grid*
        (concatenate 'string *h871-pf-v04-manager* "-AA")
        :width 105 :height 54 :cellSize 10,10 :margin 4 :spacing 2)
      (sd-display-error "H871 VER-04: Cannot create manager layout.")
      (return-from h871-pf-v04-create-manager nil)))
  (unless (sd-logical-table-p *h871-pf-v04-logical-table*)
    (unless
      (sd-create-logical-table
        *h871-pf-v04-logical-table*
        :secured nil
        :columns '(:row-id :pair-label :process :material :part-count
                   :browser-name :instance :base)
        :columnNames '("ID" "Density Pair" "Process" "Material"
                       "Part Count" "Browser" "Instance Code" "Base Code")
        :keyColumns '(:row-id)
        :types '(:number :string :string :string :number :string :number :number)
        :contents nil)
      (sd-display-error "H871 VER-04: Cannot create manager data table.")
      (return-from h871-pf-v04-create-manager nil)))
  (unless (sd-display-table-p *h871-pf-v04-table*)
    (unless
      (sd-create-display-table-control
        *h871-pf-v04-table* *h871-pf-v04-grid*
        :x 0 :y 0 :width 100 :height 45
        :logicalTable *h871-pf-v04-logical-table*
        :columns '(:pair-label :process :material :part-count :browser-name)
        :entryAlignment '(:left :left :left :right :left)
        :selectionMode :single-row)
      (sd-display-error "H871 VER-04: Cannot create manager Display Table.")
      (return-from h871-pf-v04-create-manager nil)))
  (unless (sd-control-p *h871-pf-v04-open-button*)
    (sd-create-pushbutton-control
      *h871-pf-v04-open-button* *h871-pf-v04-grid*
      :x 0 :y 47 :width 22 :height 4
      :title "Open Selected Browser"
      :pushAction '(h871-pf-v04-open-selected)))
  (h871-pf-v04-refresh-manager)
  (unless (sd-dialog-shell-visible-p *h871-pf-v04-manager*)
    (sd-show-dialog-shell *h871-pf-v04-manager*))
  t)

(defun h871-pf-v04-open-selected ()
  (let* ((selection
           (sd-get-display-table-selection *h871-pf-v04-table*))
         (columns (if selection (cadr selection) nil))
         (instances (if columns (getf columns :instance) nil))
         (bases (if columns (getf columns :base) nil)))
    (if (and instances bases)
        (h871-pf-v04-show-pair (car instances) (car bases))
      (sd-display-message
        "H871 VER-04: Select one Density Pair row, then press Open Selected Browser."))))

;; ---------------------------------------------------------------------------
;; Native Graphical Browser callbacks. These read only BrowserNode client data.
;; ---------------------------------------------------------------------------

(defun h871-pf-v04-row-data (node)
  (browsernode-objclientdata node))

(defun h871-pf-v04-column-name (node browser-name)
  (declare (ignore browser-name))
  (getf (h871-pf-v04-row-data node) :name))

(defun h871-pf-v04-column-instance (node browser-name)
  (declare (ignore browser-name))
  (let ((value (getf (h871-pf-v04-row-data node) :instance)))
    (if value (format nil "~A" value) "-")))

(defun h871-pf-v04-column-base (node browser-name)
  (declare (ignore browser-name))
  (let ((value (getf (h871-pf-v04-row-data node) :base)))
    (if value (format nil "~A" value) "-")))

(defun h871-pf-v04-column-path (node browser-name)
  (declare (ignore browser-name))
  (getf (h871-pf-v04-row-data node) :path))

(defun h871-pf-v04-build-results-tree ()
  ;; The active pair context is set immediately before its tree is created.
  ;; BrowserNodes retain actual Part objects; native Graphical Browser owns Apply.
  (let* ((instance *h871-pf-v04-active-instance*)
         (base *h871-pf-v04-active-base*)
         (tree (h871-pf-v04-tree-name instance base))
         (root
           (sd-create-browsernode
             :tree tree :parent nil
             :objPath (format nil "/H871_RESULTS_~A_~A" instance base)
             :objPname (format nil "H871 ~A" (h871-pf-v04-pair-label instance base))
             :objClientData (list :kind :root))))
    (dolist (part (reverse *h871-pf-v04-active-parts*))
      (let ((instance-api (sd-inq-part-density part :instance))
            (base-api (sd-inq-part-density part :contents))
            (path (h871-pf-v04-path part)))
        (sd-create-browsernode
          :tree tree :parent root
          :objPath path
          :objPname (h871-pf-v04-name part)
          :objClientData
            (list :kind :part :part part
                  :name (h871-pf-v04-name part) :path path
                  :instance (h871-pf-v04-density-display-value instance-api)
                  :base (h871-pf-v04-density-display-value base-api)))))
    root))

(defun h871-pf-v04-select-all (browser-name)
  (sd-browser-exec-cmd browser-name :select-all))

(defun h871-pf-v04-clear-selection (browser-name)
  (sd-browser-exec-cmd browser-name :clear-select-list))

(defun h871-pf-v04-selected-parts (browser-name)
  (let ((parts nil))
    (dolist (node (sd-query-browser browser-name :get-selected-objects))
      (let ((data (h871-pf-v04-row-data node)))
        (when (eq (getf data :kind) :part)
          (push (getf data :part) parts))))
    (nreverse parts)))

(defun h871-pf-v04-show-selection-summary (browser-name)
  (sd-browser-set-status-text browser-name
    :value
      (format nil "~A result row(s) selected."
        (length (h871-pf-v04-selected-parts browser-name)))))

(defun h871-pf-v04-create-browser (instance base parts)
  (let* ((browser (h871-pf-v04-browser-name instance base))
         (tree (h871-pf-v04-tree-name instance base))
         (label (h871-pf-v04-pair-label instance base)))
    ;; Replacing the same pair is intentional. Different pairs have distinct
    ;; Browser and Tree names and are not destroyed by this operation.
    (ignore-errors (sd-hide-graphical-browser browser))
    (ignore-errors (sd-destroy-graphical-browser browser))
    (ignore-errors (sd-destroy-browser-tree tree))
    (setf *h871-pf-v04-active-parts* parts)
    (setf *h871-pf-v04-active-instance* instance)
    (setf *h871-pf-v04-active-base* base)

    (unless
      (sd-create-browser-tree
        tree
        ;; Snapshot-style results: do not subscribe this tree to global model
        ;; changes, which could otherwise rebuild it using another pair context.
        :update-events nil
        :update-func 'h871-pf-v04-build-results-tree)
      (sd-display-error
        (format nil "H871 VER-04: Cannot create Browser Tree ~A." tree))
      (return-from h871-pf-v04-create-browser nil))

    (unless
      (sd-create-graphical-browser
        browser :tree tree
        :topLabel (format nil "H871 - ~A" label)
        :treeStatusBar
          (format nil "~A matching Part(s). Select rows and press Apply."
            (length parts))
        :minHeight 280 :maxWidth 900 :maxHeight 760
        :okButtonLabel "Apply"
        :abortButtonLabel "Select All"
        :abortButtonAction (list 'h871-pf-v04-select-all browser)
        :buttonMenu
          (list
            (list "select-all" :label "Select All"
                  :push (list 'h871-pf-v04-select-all browser))
            (list "clear-selection" :label "Clear Selection"
                  :push (list 'h871-pf-v04-clear-selection browser)))
        :buttonMenuOffObjectOnly nil
        :topMenu
          (list
            (list "selection" :label "Selection"
              :contents
                (list
                  (list "select-all" :label "Select All"
                    :push (list 'h871-pf-v04-select-all browser))
                  (list "clear-selection" :label "Clear Selection"
                    :push (list 'h871-pf-v04-clear-selection browser))
                  (list "selection-summary" :label "Update Selection Count"
                    :push (list 'h871-pf-v04-show-selection-summary browser))))))
      (sd-display-error
        (format nil "H871 VER-04: Cannot create Graphical Browser ~A." browser))
      (return-from h871-pf-v04-create-browser nil))

    (unless
      (sd-browser-define-table
        browser :table-name "h871-pf-v04-bom"
        :with-name-column nil
        :column-definition
          '((:label "Part Name" :type :string-column
             :display-func h871-pf-v04-column-name :initial-width 28)
            (:label "Density Instance" :type :string-column
             :display-func h871-pf-v04-column-instance :initial-width 13)
            (:label "Density Base" :type :string-column
             :display-func h871-pf-v04-column-base :initial-width 12)
            (:label "Assembly Path" :type :string-column
             :display-func h871-pf-v04-column-path :initial-width 42)))
      (sd-display-error
        (format nil "H871 VER-04: Cannot define Browser table ~A." browser))
      (return-from h871-pf-v04-create-browser nil))

    (sd-browser-set-active-table browser :table-name "h871-pf-v04-bom")
    (sd-browser-exec-cmd browser :set-table-mode)
    (sd-show-graphical-browser browser)
    (let ((root (sd-get-browsernode-struct tree :root)))
      (unless root
        (sd-display-error
          (format nil "H871 VER-04: Browser Tree ~A has no root node." tree))
        (return-from h871-pf-v04-create-browser nil))
      (sd-browser-exec-cmd browser :change-table-root root t))
    t))

(defun h871-pf-v04-show-pair (instance base)
  (let ((entry (h871-pf-v04-find-pair instance base)))
    (if entry
        (progn
          (sd-show-graphical-browser (getf entry :browser))
          t)
      (sd-display-message
        (format nil "H871 VER-04: No saved result Browser for ~A."
          (h871-pf-v04-pair-label instance base)))
      nil)))

;; ---------------------------------------------------------------------------
;; Reports and filter entry point.
;; ---------------------------------------------------------------------------

(defun h871-pf-v04-write-report (assembly matches instance base)
  (let ((report
          (merge-pathnames
            "H871_PART_FILTER_VER_04_RESULT.txt"
            (user-homedir-pathname))))
    (with-open-file
      (stream report :direction :output :if-exists :supersede
              :if-does-not-exist :create)
      (format stream "H871 PART FILTER VER-04~%")
      (format stream "Assembly: ~A~%" (h871-pf-v04-path assembly))
      (format stream "Density Instance: ~A~%" instance)
      (format stream "Density Base: ~A~%" base)
      (format stream "Visited objects: ~A~%" *h871-pf-v04-visited-count*)
      (format stream "~%RAW DENSITY SAMPLES~%")
      (dolist (sample (reverse *h871-pf-v04-diagnostic-samples*))
        (format stream "~S~%" sample))
      (dolist (part matches)
        (format stream "~%PART: ~A~%PATH: ~A~%"
          (h871-pf-v04-name part) (h871-pf-v04-path part))))
    report))

(defun h871-pf-v04-run (assembly requested-instance requested-base)
  (unless (and (numberp requested-instance) (numberp requested-base))
    (sd-display-error "H871 VER-04: Density filter values must be numeric codes.")
    (return-from h871-pf-v04-run nil))
  (setf *h871-pf-v04-diagnostic-samples* nil)
  (setf *h871-pf-v04-visited-count* 0)
  (let* ((matches
           (h871-pf-v04-collect assembly nil
             requested-instance requested-base))
         (report
           (h871-pf-v04-write-report
             assembly matches requested-instance requested-base))
         (entry (h871-pf-v04-find-pair requested-instance requested-base))
         (browser (h871-pf-v04-browser-name requested-instance requested-base))
         (tree (h871-pf-v04-tree-name requested-instance requested-base)))
    (if (null matches)
        (progn
          (sd-display-message
            (format nil
              "No Parts matched ~A. Existing Browser data was not changed.~%Report: ~A"
              (h871-pf-v04-pair-label requested-instance requested-base)
              (namestring report)))
          (values 0 report))
      (progn
        (unless (h871-pf-v04-create-manager)
          (return-from h871-pf-v04-run nil))
        (unless (h871-pf-v04-create-browser
                  requested-instance requested-base matches)
          (return-from h871-pf-v04-run nil))
        (if entry
            (setf (getf entry :count) (length matches)
                  (getf entry :browser) browser
                  (getf entry :tree) tree
                  (getf entry :assembly) (h871-pf-v04-path assembly))
          (push
            (list :instance requested-instance :base requested-base
                  :count (length matches) :browser browser :tree tree
                  :assembly (h871-pf-v04-path assembly))
            *h871-pf-v04-pairs*))
        (h871-pf-v04-refresh-manager)
        (values (length matches) report)))))

;; ---------------------------------------------------------------------------
;; Dialog entry point. Mappings intentionally match VER-02 / VER-03.
;; ---------------------------------------------------------------------------

(sd-defdialog 'h871_part_filter_ver_04
  :dialog-title "H871 - PART FILTER VER-04 MULTI-BROWSER"
  :variables
  '(
    ("ASSEMBLY")
    (ASSEMBLY
      :value-type :assembly
      :title "Select Assembly"
      :prompt-text "Select assembly to scan.")
    ("MACHINING PROCESS")
    (MACHINING_PROCESS
      :range ((1 :label "CNC") (2 :label "KH")
              (3 :label "CG") (4 :label "COVER"))
      :initial-value 1
      :title "Machining Process")
    ("MATERIAL")
    (MATERIAL
      :range ((6061 :label "A6061") (201 :label "SUS201")
              (304 :label "SUS304") (400 :label "SS400")
              (10 :label "POM") (20 :label "Bakelit")
              (30 :label "MC") (40 :label "MIKA") (50 :label "PU"))
      :initial-value 304
      :title "Material"))
  :ok-action
  '(progn
     (h871-pf-v04-run assembly machining_process material)
     (sd-return-from-ok-action)))

;; LOAD:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER_VER_04_MULTI_BROWSER.lsp")
;; COMMAND:
;; H871_PART_FILTER_VER_04
;;
;; RUNTIME TEST CHECKLIST:
;; 1. Filter CNC + SUS304 (1-304): manager row + native browser must appear.
;; 2. Filter KH + A6061 (2-6061): second independent browser must appear.
;; 3. Keep both browsers open; verify each has its own correct Parts.
;; 4. Re-filter CNC + SUS304 from a different Assembly: only 1-304 browser
;;    should be replaced; 2-6061 browser must remain unchanged.
;; 5. Select rows and press native Apply in each browser; verify 3D viewport.
;; 6. Re-open a browser from the manager table.
;; 7. Test no-match: previous browser and manager row must remain unchanged.
;;
;; IMPORTANT RUNTIME QUESTIONS:
;; - Does Modeling 18.1 accept :update-events nil for snapshot Browser Trees?
;; - Does the tree update callback run during sd-create-browser-tree or show?
;; - Does UICT single-row selection return hidden :instance/:base columns?
;; - Can multiple named Graphical Browsers remain open simultaneously?
;; - Does repeated destroy/recreate of one pair leave other browsers untouched?
