;; ============================================================================
;; H871 PART FILTER - VER-03
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Architecture: ONE standalone UICT Results window with INTERNAL tabs.
;; Each unique Density Instance + Density Base pair owns one page.
;; Repeating a pair refreshes that page; a no-match search leaves pages intact.
;;
;; Stage delivered in this file:
;; - Integrated ver-02 Density pair scan and user mapping.
;; - UICT dialog-shell/tab-control/list-control prototype.
;; - Per-page result data and multi-selection; Select All / Clear Selection.
;; - Pair-key refresh and no-match protection.
;;
;; IMPORTANT VERIFICATION LIMIT:
;; UICT references available to development are PTC 20.7/20.8 manuals.
;; Their availability/signatures in Modeling 18.1 have NOT been confirmed.
;; This file is a controlled 18.1 compatibility prototype, not runtime-tested.
;; Applying selected real Part objects from a UICT list is intentionally not
;; wired until the Modeling 18.1 selection hand-off is proven. The working
;; native Graphical Browser Apply implementation remains preserved in ver-02.
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

;; Page entry:
;; (:instance n :base n :label string :page string :list string
;;  :status string :results (Part ...) :rows ((display-string . Part) ...))

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

(defun h871-pf-v03-list-name (page-name)
  (concatenate 'string page-name "-RESULTS-LI"))

(defun h871-pf-v03-status-name (page-name)
  (concatenate 'string page-name "-STATUS-TX"))

(defun h871-pf-v03-make-row-label (part instance base)
  (format nil "~A | I=~A | B=~A | ~A"
    (h871-pf-v03-name part)
    (h871-pf-v03-density-display-value
      (sd-inq-part-density part :instance))
    (h871-pf-v03-density-display-value
      (sd-inq-part-density part :contents))
    (h871-pf-v03-path part)))

(defun h871-pf-v03-build-rows (parts instance base)
  (let ((rows nil))
    (dolist (part parts)
      (push (cons (h871-pf-v03-make-row-label part instance base) part) rows))
    (nreverse rows)))

(defun h871-pf-v03-row-labels (rows)
  (mapcar #'car rows))

(defun h871-pf-v03-update-status (page-name)
  (let* ((entry (h871-pf-v03-page-by-name page-name))
         (list-name (getf entry :list))
         (status-name (getf entry :status))
         (selection (sd-get-list-control-selected-items list-name))
         (selected (if selection (length (car selection)) 0))
         (total (length (getf entry :results))))
    (sd-set-text-control-value status-name
      :text (format nil "~A Part(s) | ~A selected | Density ~A / ~A"
                    total selected
                    (getf entry :instance) (getf entry :base)))))

(defun h871-pf-v03-selection-changed (page-name)
  (h871-pf-v03-update-status page-name))

(defun h871-pf-v03-tab-changed (page-name)
  (setf *h871-pf-v03-current-page* page-name)
  (h871-pf-v03-update-status page-name))

(defun h871-pf-v03-position-list (count)
  (let ((positions nil))
    (do ((n 1 (+ n 1)))
        ((> n count) (nreverse positions))
      (push n positions))))

(defun h871-pf-v03-select-all (page-name)
  (let ((entry (h871-pf-v03-page-by-name page-name)))
    (when entry
      (sd-set-list-control-selected-items
        (getf entry :list)
        :positions
        (h871-pf-v03-position-list (length (getf entry :results))))
      (h871-pf-v03-update-status page-name))))

(defun h871-pf-v03-clear-selection (page-name)
  (let ((entry (h871-pf-v03-page-by-name page-name)))
    (when entry
      (sd-set-list-control-selected-items
        (getf entry :list) :items nil)
      (h871-pf-v03-update-status page-name))))

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

(defun h871-pf-v03-create-page (instance base)
  (let* ((label (h871-pf-v03-pair-label instance base))
         (page-name (format nil "H871-PF-V03-PAGE-~A"
                            (incf *h871-pf-v03-page-counter*)))
         (list-name (h871-pf-v03-list-name page-name))
         (status-name (h871-pf-v03-status-name page-name)))
    (unless
      (sd-insert-tab-control-page
        page-name *h871-pf-v03-tabs*
        :tabTitle label :cellSize 10,10 :margin 3 :spacing 1)
      (sd-display-error "H871 ver-03: Could not add an internal results tab.")
      (return-from h871-pf-v03-create-page nil))

    (sd-create-text-control
      status-name (concatenate 'string page-name "-TAB-GA")
      :x 0 :y 0 :width 86 :height 2
      :editable nil :showModified nil)

    (sd-create-list-control
      list-name (concatenate 'string page-name "-TAB-GA")
      :x 0 :y 2 :width 86 :height 43
      :selectionMode :multiple
      :selectionAction (list 'h871-pf-v03-selection-changed page-name)
      :items nil)

    (sd-create-pushbutton-control
      (concatenate 'string page-name "-SELECT-ALL-PB")
      (concatenate 'string page-name "-TAB-GA")
      :x 0 :y 46 :width 14 :height 3
      :title "Select All"
      :pushAction (list 'h871-pf-v03-select-all page-name))

    (sd-create-pushbutton-control
      (concatenate 'string page-name "-CLEAR-PB")
      (concatenate 'string page-name "-TAB-GA")
      :x 15 :y 46 :width 16 :height 3
      :title "Clear Selection"
      :pushAction (list 'h871-pf-v03-clear-selection page-name))

    (push
      (list :instance instance :base base :label label
            :page page-name :list list-name :status status-name
            :results nil :rows nil)
      *h871-pf-v03-pages*)
    (setf *h871-pf-v03-current-page* page-name)
    (sd-set-current-tab-control-page *h871-pf-v03-tabs* :page page-name)
    (h871-pf-v03-update-status page-name)
    (h871-pf-v03-page-by-name page-name)))

(defun h871-pf-v03-refresh-page (entry parts)
  (let* ((page-name (getf entry :page))
         (list-name (getf entry :list))
         (old-selection (sd-get-list-control-selected-items list-name))
         (old-selected (if old-selection (car old-selection) nil))
         (rows (h871-pf-v03-build-rows
                 parts (getf entry :instance) (getf entry :base)))
         (labels (h871-pf-v03-row-labels rows))
         (preserved nil))
    ;; Keep only selection labels which still exist after refresh.
    (dolist (label old-selected)
      (when (member label labels :test #'equal)
        (push label preserved)))
    (setf (getf entry :results) parts)
    (setf (getf entry :rows) rows)
    (sd-set-list-control-items list-name :items labels)
    (when preserved
      (sd-set-list-control-selected-items
        list-name :items (nreverse preserved)))
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

    (h871-pf-v03-refresh-page entry matches)
    (unless (sd-dialog-shell-visible-p *h871-pf-v03-shell*)
      (sd-show-dialog-shell *h871-pf-v03-shell*))

    (values (length matches) report)))

;; ---------------------------------------------------------------------------
;; Search dialog - mappings are identical to ver-02.
;; Density Instance + Density Base remain the actual filter properties.
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
;; FIRST RUNTIME TEST:
;; 1. Load this file in Creo Elements/Direct Modeling 18.1.
;; 2. Run H871_PART_FILTER_VER_03 and choose an Assembly.
;; 3. Search CNC + SUS304; expect one Results window with SUS304-CNC tab.
;; 4. Search KH + A6061; expect a second tab in the SAME window.
;; 5. Search CNC + SUS304 again; expect first tab to refresh, not duplicate.
;; 6. Test row multi-selection, Select All, Clear Selection and tab switching.
;;
;; Apply is intentionally not connected in this prototype. Do not use this
;; version for production selection hand-off until that stage is verified.
