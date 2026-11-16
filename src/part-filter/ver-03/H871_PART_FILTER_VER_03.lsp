;; ============================================================================
;; H871 PART FILTER - VER-03
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Architecture:
;; - ONE standalone UICT Results window with INTERNAL tabs.
;; - One multi-column Display Table per Density pair page.
;; - Each unique Density Instance + Density Base pair owns one page.
;; - Repeating a pair refreshes that page; a no-match search leaves pages intact.
;;
;; ver-03.1 changes:
;; - Replaced concatenated List Control rows with real table columns:
;;   Part Name | Density Instance | Density Base | Assembly Path.
;; - Each table stores the actual Part object in a hidden logical-table column.
;; - Row multi-selection is provided by Display Table :multiple-rows.
;; - Select All / Clear Selection operate only on the page's table.
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

(defvar *h871-pf-v03-shell* "h871-pf-v03-results")
(defvar *h871-pf-v03-grid* "h871-pf-v03-results-grid")
(defvar *h871-pf-v03-tabs* "h871-pf-v03-tabs")

;; Native Apply bridge: temporary Graphical Browser objects are not shown.
(defvar *h871-pf-v03-apply-parts* nil)
(defvar *h871-pf-v03-apply-nodes* nil)
(defvar *h871-pf-v03-apply-browser* "h871-pf-v03-apply-bridge")
(defvar *h871-pf-v03-apply-tree* "h871-pf-v03-apply-tree")

;; Page entry:
;; (:instance n :base n :label string :page string :table string
;;  :logical-table string :status string :results (Part ...))

(defun h871-pf-v03-name (obj)
  (or (sd-inq-obj-basename obj) "<NO NAME>"))

(defun h871-pf-v03-path (obj)
  (or (sd-inq-obj-pathname obj) "<NO PATH>"))

(defun h871-pf-v03-as-number (value)
  (if (numberp value) value nil))

(defun h871-pf-v03-density-display-value (api-value)
  (when (numberp api-value)
    (/ api-value 1000.0)))

(defun h871-pf-v03-numeric-equal-p (actual requested)
  (let ((a (h871-pf-v03-as-number actual))
        (b (h871-pf-v03-as-number requested)))
    (and a b
         (<= (abs (- a b)) 0.0000001))))

(defun h871-pf-v03-collect (obj matches requested-instance requested-base)
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
              (h871-pf-v03-numeric-equal-p
                (h871-pf-v03-density-display-value actual-instance)
                requested-instance)
              (h871-pf-v03-numeric-equal-p
                (h871-pf-v03-density-display-value actual-base)
                requested-base))
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

(defun h871-pf-v03-pair-label (instance base)
  (format nil "~A-~A"
    (h871-pf-v03-material-label base)
    (h871-pf-v03-process-label instance)))

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
          part)
        rows))
    (nreverse rows)))

(defun h871-pf-v03-update-status (page-name)
  (let* ((entry (h871-pf-v03-page-by-name page-name))
         (table-name (getf entry :table))
         (selection (sd-get-display-table-selection table-name))
         (selected-rows (if selection (car selection) nil))
         (selected-count (if selected-rows (length selected-rows) 0))
         (total (length (getf entry :results))))
    (sd-set-text-control-value (getf entry :status)
      :text
        (format nil "~A Part(s) | ~A selected | Density Instance ~A / Base ~A"
          total selected-count
          (getf entry :instance) (getf entry :base)))))

(defun h871-pf-v03-table-selection-changed (table-name)
  (let ((entry (h871-pf-v03-page-by-table table-name)))
    (when entry
      (h871-pf-v03-update-status (getf entry :page)))))

(defun h871-pf-v03-tab-changed (page-name)
  (setf *h871-pf-v03-current-page* page-name)
  (h871-pf-v03-update-status page-name))

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

  ;; Mirror ver-02: make the bridge root's direct Part children the table rows.
  (sd-browser-exec-cmd *h871-pf-v03-apply-browser* :set-table-mode)
  (let ((root
          (sd-get-browsernode-struct *h871-pf-v03-apply-tree* :root)))
    (when root
      (sd-browser-exec-cmd
        *h871-pf-v03-apply-browser* :change-table-root root t)))

  ;; Programmatically select each real Part-backed BrowserNode.
  (dolist (node *h871-pf-v03-apply-nodes*)
    (sd-browser-exec-cmd
      *h871-pf-v03-apply-browser* :set-object-selection node t))

  ;; Native ver-02 hand-off: selected objects enter Modeling's select list.
  (unless
    (sd-browser-exec-cmd
      *h871-pf-v03-apply-browser* :select-and-execute)
    (sd-display-message
      "H871 Apply: No objects were handed to Modeling. Check the active command.")
    (return-from h871-pf-v03-native-apply nil))
  t)

(defun h871-pf-v03-apply (page-name)
  (let* ((entry (h871-pf-v03-page-by-name page-name))
         (selection (sd-get-display-table-selection (getf entry :table)))
         (columns (if selection (cadr selection) nil))
         (parts (if columns (getf columns :part-object) nil)))
    (if (null parts)
        (sd-display-message
          "H871: No Part rows selected. Select rows or use Select All, then press Apply.")
      (progn
        (h871-pf-v03-native-apply parts)
        (h871-pf-v03-update-status page-name)))))

;; ---------------------------------------------------------------------------
;; Results window and internal tabs
;; ---------------------------------------------------------------------------

(defun h871-pf-v03-create-shell ()
  (unless (sd-dialog-shell-p *h871-pf-v03-shell*)
    (unless
      (sd-create-dialog-shell
        *h871-pf-v03-shell*
        :title "H871 - PART FILTER RESULTS VER-03"
        :bottomLine :none
        :closeAction
          (list 'sd-hide-dialog-shell *h871-pf-v03-shell* :ignorePin t)
        :margin 4)
      (sd-display-error "H871 ver-03: Could not create the Results window.")
      (return-from h871-pf-v03-create-shell nil))

    (unless
      (sd-append-grid-area
        *h871-pf-v03-grid* (concatenate 'string *h871-pf-v03-shell* "-AA")
        :width 920 :height 560 :cellSize 10,10 :margin 4 :spacing 2)
      (sd-display-error "H871 ver-03: Could not create the Results layout.")
      (return-from h871-pf-v03-create-shell nil))

    (unless
      (sd-create-tab-control
        *h871-pf-v03-tabs* *h871-pf-v03-grid*
        :x 0 :y 0 :width 90 :height 53
        :tabChangedAction 'h871-pf-v03-tab-changed)
      (sd-display-error "H871 ver-03: Could not create the internal tab control.")
      (return-from h871-pf-v03-create-shell nil)))
  t)

(defun h871-pf-v03-create-logical-table (logical-table)
  (sd-create-logical-table
    logical-table
    :secured nil
    :columns '(:row-id :part-name :density-instance :density-base
               :assembly-path :part-object)
    :columnNames '("Row ID" "Part Name" "Density Instance" "Density Base"
                   "Assembly Path" "Part Object")
    :keyColumns '(:row-id)
    :types '(:number :string :number :number :string nil)
    :contents nil))

(defun h871-pf-v03-create-page (instance base)
  (let* ((label (h871-pf-v03-pair-label instance base))
         (page-name
           (format nil "H871-PF-V03-PAGE-~A"
             (incf *h871-pf-v03-page-counter*)))
         (table-name (h871-pf-v03-table-name page-name))
         (logical-table (h871-pf-v03-logical-table-name page-name))
         (status-name (h871-pf-v03-status-name page-name))
         (tab-grid (concatenate 'string page-name "-TAB-GA")))

    (unless
      (sd-insert-tab-control-page
        page-name *h871-pf-v03-tabs*
        :tabTitle label :cellSize 10,10 :margin 3 :spacing 1)
      (sd-display-error "H871 ver-03: Could not add an internal results tab.")
      (return-from h871-pf-v03-create-page nil))

    (unless (h871-pf-v03-create-logical-table logical-table)
      (sd-display-error "H871 ver-03: Could not create the page's logical table.")
      (return-from h871-pf-v03-create-page nil))

    (sd-create-text-control
      status-name tab-grid
      :x 0 :y 0 :width 86 :height 2
      :editable nil :showModified nil)

    (unless
      (sd-create-display-table-control
        table-name tab-grid
        :x 0 :y 2 :width 86 :height 42
        :logicalTable logical-table
        :columns '(:part-name :density-instance :density-base :assembly-path)
        :entryAlignment '(:left :right :right :left)
        :selectionMode :multiple-rows
        :selectionAction 'h871-pf-v03-table-selection-changed)
      (sd-display-error "H871 ver-03: Could not create the multi-column results table.")
      (return-from h871-pf-v03-create-page nil))

    (sd-create-pushbutton-control
      (concatenate 'string page-name "-SELECT-ALL-PB")
      tab-grid
      :x 0 :y 45 :width 14 :height 3
      :title "Select All"
      :pushAction (list 'h871-pf-v03-select-all page-name))

    (sd-create-pushbutton-control
      (concatenate 'string page-name "-CLEAR-PB")
      tab-grid
      :x 15 :y 45 :width 16 :height 3
      :title "Clear Selection"
      :pushAction (list 'h871-pf-v03-clear-selection page-name))

    (sd-create-pushbutton-control
      (concatenate 'string page-name "-APPLY-PB")
      tab-grid
      :x 32 :y 45 :width 12 :height 3
      :title "Apply"
      :pushAction (list 'h871-pf-v03-apply page-name))

    (push
      (list :instance instance :base base :label label
            :page page-name :table table-name
            :logical-table logical-table :status status-name
            :results nil)
      *h871-pf-v03-pages*)

    (setf *h871-pf-v03-current-page* page-name)
    (sd-set-current-tab-control-page *h871-pf-v03-tabs* :page page-name)
    (h871-pf-v03-update-status page-name)
    (h871-pf-v03-page-by-name page-name)))

(defun h871-pf-v03-refresh-page (entry parts)
  (let* ((page-name (getf entry :page))
         ;; Pages can survive a LISP reload because these globals are not reset.
         ;; Older in-memory page records may therefore lack :logical-table.
         ;; Always recover the deterministic name from the page identifier.
         (logical-table
           (or (getf entry :logical-table)
               (and page-name
                    (h871-pf-v03-logical-table-name page-name))))
         (table-name (getf entry :table))
         (contents (h871-pf-v03-table-contents parts)))
    (unless (and (stringp logical-table)
                 (> (length logical-table) 0))
      (sd-display-error
        "H871 ver-03: Invalid logical table name for this Results tab.")
      (return-from h871-pf-v03-refresh-page nil))

    ;; Recover a missing logical table instead of passing NIL/"" to the API.
    ;; This specifically handles stale page metadata retained across LISP reloads.
    (unless (sd-logical-table-p logical-table)
      (unless (h871-pf-v03-create-logical-table logical-table)
        (sd-display-error
          (format nil
            "H871 ver-03: Could not recreate logical table ~A."
            logical-table))
        (return-from h871-pf-v03-refresh-page nil)))

    ;; Keep the recovered name in the live page record for subsequent refreshes.
    (setf (getf entry :logical-table) logical-table)

    ;; Verify that the Display Table is still bound to this page's logical table.
    ;; A stale control bound to an empty/different name must be recreated.
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
          :columns '(:part-name :density-instance :density-base :assembly-path)
          :entryAlignment '(:left :right :right :left)
          :selectionMode :multiple-rows
          :selectionAction 'h871-pf-v03-table-selection-changed)
        (sd-display-error
          "H871 ver-03: Could not restore the result table control.")
        (return-from h871-pf-v03-refresh-page nil)))

    ;; Replacing logical-table contents refreshes its Display Table in place.
    ;; Selection is cleared so stale object references are never applied.
    (unless
      (sd-change-logical-table-contents
        logical-table :contents contents)
      (sd-display-error
        (format nil
          "H871 ver-03: Could not refresh logical table ~A."
          logical-table))
      (return-from h871-pf-v03-refresh-page nil))
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
      (format s "H871 PART FILTER VER-03 - EXACT DENSITY PAIR~%")
      (format s "Assembly: ~A~%" (h871-pf-v03-path assembly))
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
  (let ((matches nil)
        (entry nil)
        (report nil))
    (setf *h871-pf-v03-diagnostic-samples* nil)
    (setf *h871-pf-v03-assembly* assembly)
    (setf matches
      (h871-pf-v03-collect assembly nil requested-instance requested-base))
    (setf report
      (h871-pf-v03-write-report assembly matches requested-instance requested-base))

    ;; No-match must not modify or replace any existing tab.
    (when (null matches)
      (sd-display-message
        (format nil
          "No Parts matched Density Instance ~A and Density Base ~A.~%Existing Results tabs were kept unchanged.~%Report: ~A"
          requested-instance requested-base (namestring report)))
      (return-from h871-pf-v03-run (values 0 report)))

    (unless (h871-pf-v03-create-shell)
      (return-from h871-pf-v03-run nil))

    (setf entry (h871-pf-v03-find-page requested-instance requested-base))
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
     (h871-pf-v03-run assembly machining_process material)
     (sd-return-from-ok-action)))

;; LOAD:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER_VER_03.lsp")
;; COMMAND:
;; H871_PART_FILTER_VER_03
;;
;; RUNTIME TEST:
;; 1. Search CNC + SUS304; expect a multi-column table in SUS304-CNC tab.
;; 2. Search KH + A6061; expect a second tab in the same Results window.
;; 3. Repeat CNC + SUS304; expect that page to refresh without duplication.
;; 4. Click individual rows and Ctrl/Shift-select multiple rows.
;; 5. Select All selects every row in the active tab only.
;; 6. Clear Selection clears only the active tab.
;; 7. Apply transfers only selected real Parts from the active tab.
;; 8. Switch tabs and verify each page's selection remains independent.
;; 9. Refresh a pair; selection is intentionally cleared to avoid stale Parts.
;;
;; COMPATIBILITY NOTE:
;; The Display Table and logical-table APIs are documented in PTC 20.7.
;; Modeling 18.1 runtime compatibility and the hidden Apply bridge must be
;; tested before treating this revision as production-ready.
