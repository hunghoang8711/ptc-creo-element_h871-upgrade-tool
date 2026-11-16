;; ============================================================================
;; H871 PART FILTER - VER-05: VER-03 FILTER + NATIVE MULTI-BROWSER MANAGER
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Architecture:
;; - The Search dialog and numeric Density filter are preserved from VER-03.
;; - One lightweight Manager window lists each filtered Density pair.
;; - Each Density Instance + Density Base pair owns an independent native
;;   Graphical Browser and Browser Tree.
;; - Each Browser uses its own callback closure and result snapshot; no shared
;;   active-pair global is used to build BrowserNodes.
;; - Re-filtering the same pair creates the replacement Browser first, then
;;   removes only the previous Browser for that same pair.
;; - A no-match result leaves all existing Browsers and Manager rows intact.
;; - Native Graphical Browser Apply is used directly; there is no Apply Bridge.
;; - No UICT Display Table or logical-table API is used.
;;
;; Density matching remains exact on BOTH Density Instance and Density Base.
;; Example: numeric 1-304 means CNC-SUS304.
;; VER-01/VER-02/VER-03 source files and main branch are not modified.
;; Runtime validation in Modeling 18.1 is still required.
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
;; VER-03 filter engine and numeric Density mapping, preserved as the base.
;; ---------------------------------------------------------------------------

(defun h871-pf-v05-name (obj)
  (or (sd-inq-obj-basename obj) "<NO NAME>"))

(defun h871-pf-v05-path (obj)
  (or (sd-inq-obj-pathname obj) "<NO PATH>"))

(defun h871-pf-v05-as-number (value)
  (if (numberp value) value nil))

(defun h871-pf-v05-density-display-value (api-value)
  (when (numberp api-value)
    (/ api-value 1000.0)))

(defun h871-pf-v05-numeric-equal-p (actual requested)
  (let ((a (h871-pf-v05-as-number actual))
        (b (h871-pf-v05-as-number requested)))
    (and a b
         (<= (abs (- a b)) 0.0000001))))

(defun h871-pf-v05-collect (obj matches requested-instance requested-base)
  ;; Preserve the VER-03 Assembly traversal and exact two-property predicate.
  (incf *h871-pf-v05-collect-visited-count*)
  (when (= (mod *h871-pf-v05-collect-visited-count* 100) 0)
    (h871-pf-v05-trace "COLLECT/PROGRESS"
      *h871-pf-v05-collect-visited-count*))
  (when (sd-inq-part-p obj)
    (let ((actual-instance (sd-inq-part-density obj :instance))
          (actual-base (sd-inq-part-density obj :contents)))
      (when (< (length *h871-pf-v05-diagnostic-samples*) 30)
        (push
          (list (h871-pf-v05-name obj)
                (h871-pf-v05-path obj)
                actual-instance (type-of actual-instance)
                actual-base (type-of actual-base))
          *h871-pf-v05-diagnostic-samples*))
      (when (and
              (not (null actual-instance))
              (not (null actual-base))
              (h871-pf-v05-numeric-equal-p
                (h871-pf-v05-density-display-value actual-instance)
                requested-instance)
              (h871-pf-v05-numeric-equal-p
                (h871-pf-v05-density-display-value actual-base)
                requested-base))
        (push obj matches))))
  (dolist (child (sd-inq-obj-children obj))
    (setf matches
      (h871-pf-v05-collect child matches requested-instance requested-base)))
  matches)

(defun h871-pf-v05-choice-label (value mapping fallback)
  (or (cadr (assoc value mapping)) fallback))

(defun h871-pf-v05-process-label (process)
  (h871-pf-v05-choice-label process
    '((1 "CNC") (2 "KH") (3 "CG") (4 "COVER"))
    (format nil "P~A" process)))

(defun h871-pf-v05-material-label (material)
  (h871-pf-v05-choice-label material
    '((6061 "A6061") (201 "SUS201") (304 "SUS304")
      (400 "SS400") (10 "POM") (20 "Bakelit")
      (30 "MC") (40 "MIKA") (50 "PU"))
    (format nil "M~A" material)))

(defun h871-pf-v05-pair-label (instance base)
  (format nil "~A-~A"
    (h871-pf-v05-process-label instance)
    (h871-pf-v05-material-label base)))

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
  (format nil "~A | ~A Part(s)"
    (getf entry :label)
    (getf entry :count)))

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
      :text "DENSITY PAIR / PART COUNT                         DENSITY PAIR / PART COUNT"))
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
           (column (if (evenp row-index) 0 1))
           (x (if (= column 0) 0 56))
           (y (+ 4 (* (floor row-index 2) 4))))
      (unless (sd-control-p text-name)
        (sd-create-text-control
          text-name *h871-pf-v05-manager-grid*
          :x x :y y :width 38 :height 3
          :editable nil :showModified nil))
      (sd-set-text-control-value text-name
        :text (h871-pf-v05-manager-row-label entry))
      (unless (sd-control-p button-name)
        (sd-create-pushbutton-control
          button-name *h871-pf-v05-manager-grid*
          :x (+ x 39) :y y :width 15 :height 3
          :title "Open"
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
    (when (and (null entry) (>= *h871-pf-v05-manager-row-counter* 36))
      (sd-display-error
        "H871 VER-05: Manager capacity reached (36 Density pairs). Close this session and restart the tool before adding more pairs.")
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
                :row-index *h871-pf-v05-manager-row-counter*))
        (incf *h871-pf-v05-manager-row-counter*)
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
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER_VER_05_MULTI_BROWSER.lsp")
;; COMMAND:
;; H871_PART_FILTER_VER_05
;;
;; RUNTIME TEST:
;; 1. Filter CNC + SUS304 (1-304): manager row and native Graphical Browser appear.
;; 2. Filter KH + A6061 (2-6061): second independent Browser appears.
;; 3. Keep both Browsers open and verify their Part lists are independent.
;; 4. Re-filter CNC + SUS304 from another Assembly: only the old 1-304 Browser
;;    is replaced; the KH-A6061 Browser remains unchanged.
;; 5. Use native Select All/Clear Selection and Apply in each Browser.
;; 6. Verify the intended Parts are selected in the 3D viewport.
;; 7. Use each Manager row's Open Browser button to reopen that pair.
;; 8. Try a no-match pair; existing Browser windows/data and Manager rows remain.
;;
;; COMPATIBILITY NOTE:
;; Browser Tree and Graphical Browser use the VER-02 native API pattern.
;; Multiple simultaneous independent Browser instances and manager UI controls
;; still require a runtime test in Modeling 18.1.
