;; ============================================================================
;; H871 PART FILTER - VER-05
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Architecture:
;; - ONE standalone UICT Results window with INTERNAL tabs.
;; - One multi-column Display Table per Density pair page.
;; - Each unique Density Instance + Density Base pair owns one page.
;; - Repeating a pair refreshes that page; a no-match search leaves pages intact.
;;
;; ver-05.1 changes:
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

(defvar *h871-pf-v05-pairs* nil)
(defvar *h871-pf-v05-browser-counter* 0)
(defvar *h871-pf-v05-manager* "h871-pf-v05-manager")
(defvar *h871-pf-v05-manager-grid* "h871-pf-v05-manager-grid")
(defvar *h871-pf-v05-manager-header* "h871-pf-v05-manager-header")
(defvar *h871-pf-v05-manager-row-counter* 0)
(defvar *h871-pf-v05-diagnostic-samples* nil)
(defvar *h871-pf-v05-collect-visited-count* 0)
;; Diagnostic trace uses the independently user-validated file-write method.
;; File errors are deliberately visible; never report false success.
(defun h871-pf-v05-trace-file ()
  (merge-pathnames
    "H871_PART_FILTER_VER_05_TRACE.txt"
    (user-homedir-pathname)))

(defun h871-pf-v05-trace-reset ()
  (with-open-file
    (stream (h871-pf-v05-trace-file)
      :direction :output :if-exists :supersede :if-does-not-exist :create)
    (format stream "H871 VER-05 TRACE START~%")
    (force-output stream))
  t)

(defun h871-pf-v05-trace (stage &optional detail)
  (with-open-file
    (stream (h871-pf-v05-trace-file)
      :direction :output :if-exists :append :if-does-not-exist :create)
    (format stream "~A | ~S~%" stage detail)
    (force-output stream))
  t)

;; ---------------------------------------------------------------------------
;; Pair registry and manager window
;; The manager uses only a dialog shell, text controls and pushbuttons.
;; No UICT logical table or Display Table is created anywhere in VER-05.
;; ---------------------------------------------------------------------------

(defun h871-pf-v05-find-pair (instance base)
  (find-if
    (lambda (entry)
      (and (= (getf entry :instance) instance)
           (= (getf entry :base) base)))
    *h871-pf-v05-pairs*))

(defun h871-pf-v05-browser-name (instance base generation)
  (format nil "H871-PF-V05-BROWSER-~A-~A-~A" instance base generation))

(defun h871-pf-v05-tree-name (instance base generation)
  (format nil "H871-PF-V05-TREE-~A-~A-~A" instance base generation))

(defun h871-pf-v05-manager-row-text-name (instance base)
  (format nil "H871-PF-V05-ROW-~A-~A-TEXT" instance base))

(defun h871-pf-v05-manager-row-button-name (instance base)
  (format nil "H871-PF-V05-ROW-~A-~A-OPEN" instance base))

(defun h871-pf-v05-manager-row-label (entry)
  (format nil "~A    |    ~A Part(s)    |    ~A"
    (getf entry :label)
    (getf entry :count)
    (getf entry :assembly)))

(defun h871-pf-v05-create-manager ()
  (unless (sd-dialog-shell-p *h871-pf-v05-manager*)
    (unless
      (sd-create-dialog-shell
        *h871-pf-v05-manager*
        :title "H871 - GRAPHICAL BROWSER MANAGER VER-05"
        :bottomLine :none
        :closeAction
          (list 'sd-hide-dialog-shell *h871-pf-v05-manager* :ignorePin t)
        :margin 4)
      (sd-display-error "H871 VER-05: Cannot create the Browser Manager window.")
      (return-from h871-pf-v05-create-manager nil)))
  (unless (sd-control-p *h871-pf-v05-manager-grid*)
    (unless
      (sd-append-grid-area
        *h871-pf-v05-manager-grid*
        (concatenate 'string *h871-pf-v05-manager* "-AA")
        :width 112 :height 82 :cellSize 10,10 :margin 4 :spacing 2)
      (sd-display-error "H871 VER-05: Cannot create Browser Manager layout.")
      (return-from h871-pf-v05-create-manager nil)))
  (unless (sd-control-p *h871-pf-v05-manager-header*)
    (sd-create-text-control
      *h871-pf-v05-manager-header* *h871-pf-v05-manager-grid*
      :x 0 :y 0 :width 108 :height 3
      :editable nil :showModified nil)
    (sd-set-text-control-value *h871-pf-v05-manager-header*
      :text "FILTER PAIR                         RESULT COUNT / SOURCE ASSEMBLY                         ACTION"))
  (unless (sd-dialog-shell-visible-p *h871-pf-v05-manager*)
    (sd-show-dialog-shell *h871-pf-v05-manager*))
  t)

(defun h871-pf-v05-show-pair (instance base)
  (let ((entry (h871-pf-v05-find-pair instance base)))
    (if (and entry (stringp (getf entry :browser)))
        (progn
          (h871-pf-v05-trace "MANAGER/OPEN-BROWSER"
            (list instance base (getf entry :browser)))
          (sd-show-graphical-browser (getf entry :browser))
          t)
      (sd-display-message
        (format nil "H871 VER-05: No active Browser exists for ~A."
          (h871-pf-v05-pair-label instance base)))
      nil)))

(defun h871-pf-v05-refresh-manager ()
  (dolist (entry *h871-pf-v05-pairs*)
    (let* ((instance (getf entry :instance))
           (base (getf entry :base))
           (text-name (h871-pf-v05-manager-row-text-name instance base))
           (button-name (h871-pf-v05-manager-row-button-name instance base))
           (row-index (getf entry :row-index))
           (y (+ 4 (* row-index 4))))
      (unless (sd-control-p text-name)
        (sd-create-text-control
          text-name *h871-pf-v05-manager-grid*
          :x 0 :y y :width 82 :height 3
          :editable nil :showModified nil))
      (sd-set-text-control-value text-name
        :text (h871-pf-v05-manager-row-label entry))
      (unless (sd-control-p button-name)
        (sd-create-pushbutton-control
          button-name *h871-pf-v05-manager-grid*
          :x 84 :y y :width 20 :height 3
          :title "Open Browser"
          :pushAction
            (list 'h871-pf-v05-show-pair instance base)))))
  (when (sd-dialog-shell-p *h871-pf-v05-manager*)
    (unless (sd-dialog-shell-visible-p *h871-pf-v05-manager*)
      (sd-show-dialog-shell *h871-pf-v05-manager*)))
  t)

;; ---------------------------------------------------------------------------
;; Native Graphical Browser table callbacks (ported from the known-good
;; VER-02 browser pattern). Each Browser owns its own independent tree.
;; ---------------------------------------------------------------------------

(defun h871-pf-v05-row-data (node)
  (browsernode-objclientdata node))

(defun h871-pf-v05-column-name (node browser-name)
  (declare (ignore browser-name))
  (getf (h871-pf-v05-row-data node) :name))

(defun h871-pf-v05-column-instance (node browser-name)
  (declare (ignore browser-name))
  (let ((value (getf (h871-pf-v05-row-data node) :instance)))
    (if value (format nil "~A" value) "-")))

(defun h871-pf-v05-column-base (node browser-name)
  (declare (ignore browser-name))
  (let ((value (getf (h871-pf-v05-row-data node) :base)))
    (if value (format nil "~A" value) "-")))

(defun h871-pf-v05-column-path (node browser-name)
  (declare (ignore browser-name))
  (getf (h871-pf-v05-row-data node) :path))

(defun h871-pf-v05-build-pair-tree (tree-name pair-label parts)
  (let ((root
          (sd-create-browsernode
            :tree tree-name :parent nil
            :objPath (format nil "/H871_V05_RESULTS_~A" tree-name)
            :objPname (format nil "H871 ~A" pair-label)
            :objClientData (list :kind :root))))
    (dolist (part (reverse parts))
      (let ((instance-api (sd-inq-part-density part :instance))
            (base-api (sd-inq-part-density part :contents))
            (path (h871-pf-v05-path part)))
        (sd-create-browsernode
          :tree tree-name :parent root
          :objPath path
          :objPname (h871-pf-v05-name part)
          :objClientData
            (list :kind :part :part part
                  :name (h871-pf-v05-name part)
                  :path path
                  :instance (h871-pf-v05-density-display-value instance-api)
                  :base (h871-pf-v05-density-display-value base-api)))))
    root))

(defun h871-pf-v05-select-all (browser-name)
  (sd-browser-exec-cmd browser-name :select-all))

(defun h871-pf-v05-clear-selection (browser-name)
  (sd-browser-exec-cmd browser-name :clear-select-list))

(defun h871-pf-v05-show-selection-summary (browser-name)
  (let ((selected
          (sd-query-browser browser-name :get-selected-objects)))
    (sd-browser-set-status-text browser-name
      :value (format nil "~A result row(s) selected."
        (if selected (length selected) 0)))))

(defun h871-pf-v05-create-browser (instance base parts)
  (let* ((generation (incf *h871-pf-v05-browser-counter*))
         (browser (h871-pf-v05-browser-name instance base generation))
         (tree (h871-pf-v05-tree-name instance base generation))
         (label (h871-pf-v05-pair-label instance base))
         (callback-symbol
           (intern
             (string-upcase
               (format nil "H871-PF-V05-BUILD-~A-~A-~A"
                 instance base generation))
             *package*))
         (callback-parts (copy-list parts)))
    ;; The callback is a per-browser closure over this Browser's own tree,
    ;; label and immutable result snapshot. No shared active-pair globals.
    (setf (symbol-function callback-symbol)
      (let ((callback-tree tree)
            (callback-label label)
            (callback-results callback-parts))
        (lambda ()
          (h871-pf-v05-build-pair-tree
            callback-tree callback-label callback-results))))
    (unless
      (sd-create-browser-tree
        tree
        :update-events oli:*SD-CHANGE-OBJECT-TREE-EVENT*
        :update-func callback-symbol)
      (sd-display-error
        (format nil "H871 VER-05: Cannot create Browser Tree ~A." tree))
      (return-from h871-pf-v05-create-browser nil))
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
        :abortButtonAction (list 'h871-pf-v05-select-all browser)
        :buttonMenu
          (list
            (list "select-all" :label "Select All"
              :push (list 'h871-pf-v05-select-all browser))
            (list "clear-selection" :label "Clear Selection"
              :push (list 'h871-pf-v05-clear-selection browser)))
        :buttonMenuOffObjectOnly nil
        :topMenu
          (list
            (list "selection" :label "Selection"
              :contents
                (list
                  (list "select-all" :label "Select All"
                    :push (list 'h871-pf-v05-select-all browser))
                  (list "clear-selection" :label "Clear Selection"
                    :push (list 'h871-pf-v05-clear-selection browser))
                  (list "selection-summary" :label "Update Selection Count"
                    :push (list 'h871-pf-v05-show-selection-summary browser))))))
      (sd-display-error
        (format nil "H871 VER-05: Cannot create Graphical Browser ~A." browser))
      (ignore-errors (sd-destroy-browser-tree tree))
      (return-from h871-pf-v05-create-browser nil))
    (unless
      (sd-browser-define-table
        browser :table-name "h871-pf-v05-bom"
        :with-name-column nil
        :column-definition
          '((:label "Part Name" :type :string-column
             :display-func h871-pf-v05-column-name :initial-width 28)
            (:label "Density Instance" :type :string-column
             :display-func h871-pf-v05-column-instance :initial-width 13)
            (:label "Density Base" :type :string-column
             :display-func h871-pf-v05-column-base :initial-width 12)
            (:label "Assembly Path" :type :string-column
             :display-func h871-pf-v05-column-path :initial-width 42)))
      (sd-display-error
        (format nil "H871 VER-05: Cannot define Browser table ~A." browser))
      (ignore-errors (sd-destroy-graphical-browser browser))
      (ignore-errors (sd-destroy-browser-tree tree))
      (return-from h871-pf-v05-create-browser nil))
    (sd-browser-set-active-table browser :table-name "h871-pf-v05-bom")
    (sd-browser-exec-cmd browser :set-table-mode)
    (sd-show-graphical-browser browser)
    (let ((root (sd-get-browsernode-struct tree :root)))
      (unless root
        (sd-display-error
          (format nil "H871 VER-05: Browser Tree ~A has no root node." tree))
        (ignore-errors (sd-destroy-graphical-browser browser))
        (ignore-errors (sd-destroy-browser-tree tree))
        (return-from h871-pf-v05-create-browser nil))
      (sd-browser-exec-cmd browser :change-table-root root t))
    (list :browser browser :tree tree :callback callback-symbol)))

;; ---------------------------------------------------------------------------
;; Reports and filter action
;; ---------------------------------------------------------------------------

(defun h871-pf-v05-write-report (assembly matches requested-instance requested-base)
  (let ((report
          (merge-pathnames
            "H871_PART_FILTER_VER_05_RESULT.txt"
            (user-homedir-pathname))))
    (with-open-file
      (stream report :direction :output :if-exists :supersede
              :if-does-not-exist :create)
      (format stream "H871 PART FILTER VER-05 - NATIVE MULTI-BROWSER~%")
      (format stream "Assembly: ~A~%" (h871-pf-v05-path assembly))
      (format stream "Density Instance: ~A~%" requested-instance)
      (format stream "Density Base: ~A~%" requested-base)
      (format stream "Visited objects: ~A~%" *h871-pf-v05-collect-visited-count*)
      (format stream "~%RAW DENSITY SAMPLES~%")
      (dolist (sample (reverse *h871-pf-v05-diagnostic-samples*))
        (format stream "~S~%" sample))
      (dolist (part matches)
        (format stream "~%PART: ~A~%PATH: ~A~%"
          (h871-pf-v05-name part) (h871-pf-v05-path part))))
    report))

(defun h871-pf-v05-run (assembly requested-instance requested-base)
  (h871-pf-v05-trace-reset)
  (h871-pf-v05-trace "RUN/BEGIN"
    (list (type-of assembly) requested-instance requested-base))
  (unless (and (numberp requested-instance) (numberp requested-base))
    (sd-display-error
      "H871 VER-05: Density filter values must be numeric codes.")
    (return-from h871-pf-v05-run nil))
  (setf *h871-pf-v05-diagnostic-samples* nil)
  (setf *h871-pf-v05-collect-visited-count* 0)
  (h871-pf-v05-trace "COLLECT/BEGIN" (h871-pf-v05-path assembly))
  (let* ((matches
           (h871-pf-v05-collect assembly nil
             requested-instance requested-base))
         (report
           (h871-pf-v05-write-report
             assembly matches requested-instance requested-base))
         (entry (h871-pf-v05-find-pair requested-instance requested-base))
         (old-browser (and entry (getf entry :browser)))
         (old-tree (and entry (getf entry :tree)))
         (new-browser-info nil))
    (h871-pf-v05-trace "COLLECT/COMPLETE"
      (list (length matches) *h871-pf-v05-collect-visited-count*))
    ;; A no-match result never destroys or replaces an existing pair Browser.
    (when (null matches)
      (sd-display-message
        (format nil
          "No Parts matched ~A. Existing Browser data was left unchanged.~%Report: ~A"
          (h871-pf-v05-pair-label requested-instance requested-base)
          (namestring report)))
      (return-from h871-pf-v05-run (values 0 report)))
    (unless (h871-pf-v05-create-manager)
      (return-from h871-pf-v05-run nil))
    (setf new-browser-info
      (h871-pf-v05-create-browser
        requested-instance requested-base matches))
    (unless new-browser-info
      (h871-pf-v05-trace "RUN/CREATE-BROWSER-FAILED"
        (list requested-instance requested-base))
      (return-from h871-pf-v05-run nil))
    ;; Register the new Browser only after its tree/table are fully created.
    (if entry
        (setf (getf entry :browser) (getf new-browser-info :browser)
              (getf entry :tree) (getf new-browser-info :tree)
              (getf entry :callback) (getf new-browser-info :callback)
              (getf entry :count) (length matches)
              (getf entry :results) matches
              (getf entry :assembly) (h871-pf-v05-path assembly))
      (progn
        (setf entry
          (list :instance requested-instance :base requested-base
                :label (h871-pf-v05-pair-label requested-instance requested-base)
                :browser (getf new-browser-info :browser)
                :tree (getf new-browser-info :tree)
                :callback (getf new-browser-info :callback)
                :count (length matches) :results matches
                :assembly (h871-pf-v05-path assembly)
                :row-index (incf *h871-pf-v05-manager-row-counter*)))
        (push entry *h871-pf-v05-pairs*)))
    (h871-pf-v05-refresh-manager)
    ;; The new Browser is live before the old same-pair Browser is removed.
    (when (and old-browser (not (equal old-browser (getf entry :browser))))
      (ignore-errors (sd-hide-graphical-browser old-browser))
      (ignore-errors (sd-destroy-graphical-browser old-browser)))
    (when (and old-tree (not (equal old-tree (getf entry :tree))))
      (ignore-errors (sd-destroy-browser-tree old-tree)))
    (h871-pf-v05-trace "RUN/RESULT-BROWSER-READY"
      (list (getf entry :label) (getf entry :browser) (length matches)))
    (values (length matches) report)))

;; Search dialog - mappings are identical to ver-02.
;; ---------------------------------------------------------------------------

(sd-defdialog 'h871_part_filter_ver_05
  :dialog-title "H871 - PART FILTER VER-05"
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
     (h871-pf-v05-run assembly machining_process material)
     (sd-return-from-ok-action)))

;; LOAD:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER_VER_05.lsp")
;; COMMAND:
;; H871_PART_FILTER_VER_05
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
