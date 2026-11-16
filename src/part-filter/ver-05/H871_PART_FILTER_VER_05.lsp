;; ============================================================================
;; H871 PART FILTER - SINGLE GRAPHICAL BROWSER / MULTI-PAGE IMPLEMENTATION CANDIDATE
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Product architecture:
;; - One standalone Results Graphical Browser owns all result pages.
;; - The same visible Browser owns row selection and native Apply.
;; - Search, page registry, page navigation and result rows are self-contained;
;;   no separate Results window or hidden Browser bridge is involved.
;; - One Browser Tree has one page root per numeric Density pair.
;; - A horizontal modeMenu page strip and Results Pages popup switch the active root.
;; - Page-local selection paths are restored in the same visible Browser.
;;
;; UI note: the modeMenu is used as a horizontal page-button strip inside the
;; same Browser. Its exact behavior must be checked in Modeling 18.1 because
;; the accessible detailed PTC reference is from a later release.
;; Search predicate, numeric normalization and mappings follow ver-02.
;; ============================================================================

(in-package :oli)

(defvar *h871-pf-v05-pages* nil)
(defvar *h871-pf-v05-current-page* nil)
(defvar *h871-pf-v05-page-root-map* nil)
(defvar *h871-pf-v05-part-node-map* nil)
(defvar *h871-pf-v05-browser* "H871-PF-V05-SINGLE-RESULTS")
(defvar *h871-pf-v05-tree* "H871-PF-V05-SINGLE-RESULTS-TREE")
(defvar *h871-pf-v05-menu-name* "H871-PF-V05-RESULT-PAGES-MENU")

(defun h871-pf-v05-trace-file ()
  (merge-pathnames
    "H871_PF_V05_SINGLE_BROWSER_TRACE.txt"
    (user-homedir-pathname)))

(defun h871-pf-v05-trace-reset ()
  (with-open-file
    (stream (h871-pf-v05-trace-file)
      :direction :output :if-exists :supersede :if-does-not-exist :create)
    (format stream "H871 PART FILTER VER-05~%")
    (force-output stream))
  t)

(defun h871-pf-v05-trace (stage &optional detail)
  (with-open-file
    (stream (h871-pf-v05-trace-file)
      :direction :output :if-exists :append :if-does-not-exist :create)
    (format stream "~A | ~S~%" stage detail)
    (force-output stream))
  t)

(defun h871-pf-v05-path (part)
  (or (sd-inq-obj-pathname part) "<NO PATH>"))

(defun h871-pf-v05-name (part)
  (or (sd-inq-obj-basename part) "<NO NAME>"))

(defun h871-pf-v05-density-value (part key)
  (let ((value (sd-inq-part-density part key)))
    (if (numberp value) (/ value 1000.0) nil)))

(defun h871-pf-v05-page-by-name (page-name)
  (find-if
    (lambda (entry) (equal (getf entry :page) page-name))
    *h871-pf-v05-pages*))

(defun h871-pf-v05-page-root-id (page-name)
  (cdr (assoc page-name *h871-pf-v05-page-root-map* :test #'equal)))

(defun h871-pf-v05-part-node-id (page-name part-path)
  (let ((item
          (find-if
            (lambda (entry)
              (and (equal (first entry) page-name)
                   (equal (second entry) part-path)))
            *h871-pf-v05-part-node-map*)))
    (and item (third item))))

(defun h871-pf-v05-node-data (node)
  (and node (BrowserNode-objClientData node)))

(defun h871-pf-v05-display-name (node browser-name)
  (let ((data (h871-pf-v05-node-data node)))
    (if (eq (getf data :kind) :part)
        (BrowserNode-objPname node)
      "")))

(defun h871-pf-v05-display-instance (node browser-name)
  (let* ((data (h871-pf-v05-node-data node))
         (value (getf data :instance)))
    (if (and (eq (getf data :kind) :part) (numberp value))
        (format nil "~A" value)
      "")))

(defun h871-pf-v05-display-base (node browser-name)
  (let* ((data (h871-pf-v05-node-data node))
         (value (getf data :base)))
    (if (and (eq (getf data :kind) :part) (numberp value))
        (format nil "~A" value)
      "")))

(defun h871-pf-v05-display-path (node browser-name)
  (let ((data (h871-pf-v05-node-data node)))
    (if (eq (getf data :kind) :part)
        (BrowserNode-objPath node)
      "")))

(defun h871-pf-v05-build-tree ()
  ;; ver-02-style BrowserNode tree: one page root, direct Part children.
  (let ((root
          (sd-create-browsernode
            :tree *h871-pf-v05-tree*
            :parent nil
            :objPath "/H871_PF_V05_RESULTS"
            :objPname "H871 Results"
            :objClientData (list :kind :root))))
    (setf *h871-pf-v05-page-root-map* nil)
    (setf *h871-pf-v05-part-node-map* nil)
    (dolist (entry (reverse *h871-pf-v05-pages*))
      (let* ((page-name (getf entry :page))
             (page-id
               (sd-create-browsernode
                 :tree *h871-pf-v05-tree*
                 :parent root
                 :objPath (format nil "/H871_PF_V05_RESULTS/~A" page-name)
                 :objPname (getf entry :label)
                 :objClientData (list :kind :page :page page-name))))
        (push (cons page-name page-id) *h871-pf-v05-page-root-map*)
        (dolist (part (getf entry :results))
          (let* ((part-path (h871-pf-v05-path part))
                 (node-id
                   (sd-create-browsernode
                     :tree *h871-pf-v05-tree*
                     :parent page-id
                     :objPath part-path
                     :objPname (h871-pf-v05-name part)
                     :objClientData
                       (list :kind :part
                             :page page-name
                             :part part
                             :instance (h871-pf-v05-density-value part :instance)
                             :base (h871-pf-v05-density-value part :contents)))))
            (push (list page-name part-path node-id)
                  *h871-pf-v05-part-node-map*)))))
    (h871-pf-v05-trace
      "TREE/BUILT"
      (list (length *h871-pf-v05-pages*)
            (length *h871-pf-v05-page-root-map*)
            (length *h871-pf-v05-part-node-map*)))
    root))

(defun h871-pf-v05-save-current-selection ()
  (when (stringp *h871-pf-v05-current-page*)
    (let ((paths nil)
          (entry (h871-pf-v05-page-by-name *h871-pf-v05-current-page*)))
      (dolist (node
                (or (sd-query-browser
                      *h871-pf-v05-browser* :get-selected-objects)
                    nil))
        (let ((data (h871-pf-v05-node-data node)))
          (when (and (eq (getf data :kind) :part)
                     (equal (getf data :page) *h871-pf-v05-current-page*))
            (push (BrowserNode-objPath node) paths))))
      (when entry
        (setf (getf entry :selected-paths) (nreverse paths)))
      (h871-pf-v05-trace
        "PAGE/SAVE-SELECTION"
        (list *h871-pf-v05-current-page* (length paths))))))

(defun h871-pf-v05-update-status (page-name)
  (let ((entry (h871-pf-v05-page-by-name page-name)))
    (when entry
      (sd-browser-set-status-text
        *h871-pf-v05-browser*
        :type :table
        :value
          (format nil "~A | ~A Part(s) | Density Instance ~A / Base ~A"
            (getf entry :label)
            (length (getf entry :results))
            (getf entry :instance)
            (getf entry :base))))))

(defun h871-pf-v05-activate-page (page-name &optional skip-save)
  (let ((entry (h871-pf-v05-page-by-name page-name)))
    (when entry
      (unless (or skip-save (equal page-name *h871-pf-v05-current-page*))
        (h871-pf-v05-save-current-selection))
      (let* ((node-id (h871-pf-v05-page-root-id page-name))
             (node (and node-id
                        (sd-get-browsernode-struct
                          *h871-pf-v05-tree* node-id)))
             (clear-roots-status nil)
             (root-set nil)
             (root-count nil))
        (unless node
          (h871-pf-v05-trace "PAGE/ROOT-NOT-FOUND" page-name)
          (return-from h871-pf-v05-activate-page nil))
        ;; A Browser can retain multiple table roots. Clear the old root
        ;; before activating this page; otherwise rows from earlier pages
        ;; can remain visible and native Apply could include the wrong page.
        ;; Buffer redraws so the root switch is one visual update.
        (sd-browser-exec-cmd *h871-pf-v05-browser* :buffer-display t)
        (sd-browser-exec-cmd *h871-pf-v05-browser* :clear-select-list)
        (setf clear-roots-status
          (sd-browser-exec-cmd *h871-pf-v05-browser* :clear-table-roots))
        (when clear-roots-status
          (setf root-set
            (sd-browser-exec-cmd
              *h871-pf-v05-browser* :change-table-root node t)))
        (sd-browser-exec-cmd *h871-pf-v05-browser* :buffer-display nil)
        ;; The query is diagnostic only; do not let an unsupported query
        ;; prevent the native Browser from completing the page transition.
        (setf root-count
          (ignore-errors
            (sd-query-browser
              *h871-pf-v05-browser* :number-of-table-roots)))
        (h871-pf-v05-trace
          "PAGE/CHANGE-ROOT"
          (list page-name clear-roots-status root-set root-count))
        ;; Fail closed: never activate a page if its previous roots could
        ;; not be cleared or the requested root could not be set.
        (unless (and clear-roots-status root-set)
          (return-from h871-pf-v05-activate-page nil)))
      (setf *h871-pf-v05-current-page* page-name)
      (dolist (part-path (getf entry :selected-paths))
        (let* ((node-id (h871-pf-v05-part-node-id page-name part-path))
               (node (and node-id
                          (sd-get-browsernode-struct
                            *h871-pf-v05-tree* node-id))))
          (when node
            (h871-pf-v05-trace
              "PAGE/RESTORE-ROW"
              (list page-name part-path
                    (sd-browser-exec-cmd
                      *h871-pf-v05-browser* :set-object-selection node t))))))
      (h871-pf-v05-update-status page-name)
      (h871-pf-v05-trace "PAGE/ACTIVE" page-name)
      t)))

(defun h871-pf-v05-menu-visible (node browser-name page-name)
  t)

(defun h871-pf-v05-menu-applicable (node browser-name page-name)
  (not (null (h871-pf-v05-page-by-name page-name))))

(defun h871-pf-v05-menu-action (node browser-name page-name)
  (h871-pf-v05-activate-page page-name)
  t)

(defun h871-pf-v05-add-page-menu ()
  (sd-browser-add-popup-entry
    *h871-pf-v05-browser*
    :label "Results Pages"
    :entry-type :sub-menu
    :sub-menu-name *h871-pf-v05-menu-name*
    :new-group t)
  (dolist (entry (reverse *h871-pf-v05-pages*))
    (h871-pf-v05-trace
      "MENU/ADD-PAGE"
      (list (getf entry :label)
            (sd-browser-add-popup-entry
              *h871-pf-v05-browser*
              :label (getf entry :label)
              :parent-menu-name *h871-pf-v05-menu-name*
              :string-client-data (getf entry :page)
              :is-entry-visible 'h871-pf-v05-menu-visible
              :is-entry-applicable 'h871-pf-v05-menu-applicable
              :menu-action 'h871-pf-v05-menu-action)))))

(defun h871-pf-v05-page-order ()
  (reverse *h871-pf-v05-pages*))

(defun h871-pf-v05-switch-offset (offset)
  (let* ((pages (h871-pf-v05-page-order))
         (count (length pages))
         (current-index
           (position *h871-pf-v05-current-page* pages
             :key (lambda (entry) (getf entry :page))
             :test #'equal)))
    (h871-pf-v05-trace
      "PAGE/NAVIGATION-REQUEST"
      (list *h871-pf-v05-current-page* offset current-index count))
    (when (> count 0)
      (let* ((index (if current-index
                        (mod (+ current-index offset) count)
                      0))
             (entry (nth index pages))
             (target (getf entry :page)))
        (h871-pf-v05-trace "PAGE/NAVIGATION-TARGET" target)
        (h871-pf-v05-activate-page target)))))

(defun h871-pf-v05-previous-page ()
  (h871-pf-v05-switch-offset -1))

(defun h871-pf-v05-next-page ()
  (h871-pf-v05-switch-offset 1))

(defun h871-pf-v05-select-all ()
  (sd-browser-exec-cmd *h871-pf-v05-browser* :select-all)
  (h871-pf-v05-update-status *h871-pf-v05-current-page*)
  t)

(defun h871-pf-v05-clear-selection ()
  (sd-browser-exec-cmd *h871-pf-v05-browser* :clear-select-list)
  (let ((entry (h871-pf-v05-page-by-name *h871-pf-v05-current-page*)))
    (when entry
      (setf (getf entry :selected-paths) nil)))
  (h871-pf-v05-update-status *h871-pf-v05-current-page*)
  t)

(defun h871-pf-v05-reset-browser-objects ()
  ;; Destroy the Browser before its Tree. This makes reruns safe after
  ;; native Apply has closed the window or after Close Results was pressed.
  (ignore-errors
    (sd-hide-graphical-browser *h871-pf-v05-browser* :ignore-pin t))
  (ignore-errors
    (sd-destroy-graphical-browser *h871-pf-v05-browser*))
  (ignore-errors
    (sd-destroy-browser-tree *h871-pf-v05-tree*))
  (setf *h871-pf-v05-page-root-map* nil)
  (setf *h871-pf-v05-part-node-map* nil)
  (h871-pf-v05-trace "LIFECYCLE/RESET-BROWSER-AND-TREE" :attempted)
  t)

(defun h871-pf-v05-close-results ()
  ;; Close only the single Results Browser; no second Results window is shown.
  (ignore-errors
    (sd-hide-graphical-browser *h871-pf-v05-browser* :ignore-pin t))
  (h871-pf-v05-trace "LIFECYCLE/RESULTS-HIDDEN" t)
  t)

;; ------------------------------------------------------------
;; Search engine and page registry
;; ------------------------------------------------------------

(defvar *h871-pf-v05-page-counter* 0)
(defvar *h871-pf-v05-assembly* nil)

(defun h871-pf-v05-as-number (value)
  (if (numberp value) value nil))

(defun h871-pf-v05-density-display-value (api-value)
  (when (numberp api-value) (/ api-value 1000.0)))

(defun h871-pf-v05-numeric-equal-p (actual requested)
  (let ((a (h871-pf-v05-as-number actual))
        (b (h871-pf-v05-as-number requested)))
    (and a b (<= (abs (- a b)) 0.0000001))))

(defun h871-pf-v05-collect (obj matches requested-instance requested-base)
  ;; Exact ver-02 collector retained; no traversal rewrite in this version.
  (when (sd-inq-part-p obj)
    (let ((actual-instance (sd-inq-part-density obj :instance))
          (actual-base (sd-inq-part-density obj :contents)))
      (when (and actual-instance actual-base
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

(defun h871-pf-v05-process-label (value)
  (or (cadr (assoc value '((1 "CNC") (2 "KH") (3 "CG") (4 "COVER"))))
      (format nil "~A" value)))

(defun h871-pf-v05-material-label (value)
  (or (cadr (assoc value
        '((6061 "A6061") (201 "SUS201") (304 "SUS304") (400 "SS400")
          (10 "POM") (20 "Bakelit") (30 "MC") (40 "MIKA") (50 "PU"))))
      (format nil "~A" value)))

(defun h871-pf-v05-page-by-pair (instance base)
  (find-if
    (lambda (entry)
      (and (equal (getf entry :instance) instance)
           (equal (getf entry :base) base)))
    *h871-pf-v05-pages*))

(defun h871-pf-v05-store-page (instance base results)
  (let ((entry (h871-pf-v05-page-by-pair instance base)))
    (if entry
        (progn
          (setf (getf entry :results) results)
          (setf (getf entry :selected-paths) nil)
          (setf (getf entry :label)
            (format nil "~A-~A"
              (h871-pf-v05-process-label instance)
              (h871-pf-v05-material-label base)))
          (getf entry :page))
      (let* ((page-name
               (format nil "H871-PF-V05-PAGE-~A"
                 (incf *h871-pf-v05-page-counter*)))
             (new-entry
               (list :instance instance :base base
                     :label
                       (format nil "~A-~A"
                         (h871-pf-v05-process-label instance)
                         (h871-pf-v05-material-label base))
                     :page page-name :results results :selected-paths nil)))
        (push new-entry *h871-pf-v05-pages*)
        page-name))))

(defun h871-pf-v05-page-button-name (entry)
  (format nil "PAGE-~A" (getf entry :page)))

(defun h871-pf-v05-page-button-menu ()
  ;; PTC maps buttonMenu to the visible horizontal row above the Browser
  ;; table. modeMenu is a context-popup menu, not the horizontal tab row.
  ;; Use push buttons for pages; active page identity is also shown in status.
  (append
    (mapcar
      (lambda (entry)
        (list
          (h871-pf-v05-page-button-name entry)
          :label (getf entry :label)
          :push (list 'h871-pf-v05-activate-page (getf entry :page))))
      (reverse *h871-pf-v05-pages*))
    (list
      '("select-all" :label "Select All" :push (h871-pf-v05-select-all))
      '("clear-selection" :label "Clear Selection"
        :push (h871-pf-v05-clear-selection)))))

(defun h871-pf-v05-rebuild-results-browser ()
  ;; Rebuild one named Browser and one named Tree; never create a second
  ;; visible Results window or a hidden selection bridge.
  (h871-pf-v05-reset-browser-objects)
  (unless
    (sd-create-browser-tree
      *h871-pf-v05-tree*
      :update-events oli:*SD-CHANGE-OBJECT-TREE-EVENT*
      :update-func 'h871-pf-v05-build-tree)
    (sd-display-error "H871: Could not create the Results Browser Tree.")
    (return-from h871-pf-v05-rebuild-results-browser nil))
  (unless
    (sd-create-graphical-browser
      *h871-pf-v05-browser*
      :tree *h871-pf-v05-tree*
      :topLabel "H871 - PART FILTER RESULTS"
      :treeStatusBar "Select Parts directly; Apply transfers the native Browser selection to Modeling."
      :tableStatusBar "Use the horizontal page buttons to switch Density-pair results. Active page is shown in the status line."
      :minHeight 280 :maxWidth 980 :maxHeight 760
      :okButtonLabel "Apply"
      :abortButtonLabel "Close Results"
      :abortButtonAction '(h871-pf-v05-close-results)
      :buttonMenu (h871-pf-v05-page-button-menu))
    (ignore-errors (sd-destroy-browser-tree *h871-pf-v05-tree*))
    (sd-display-error "H871: Could not create the single Results Browser.")
    (return-from h871-pf-v05-rebuild-results-browser nil))
  (unless
    (sd-browser-define-table
      *h871-pf-v05-browser*
      :table-name "h871-pf-v05-results-table"
      :with-name-column nil
      :column-definition
        '((:label "Part Name" :type :string-column
           :display-func h871-pf-v05-display-name :initial-width 28)
          (:label "Density Instance" :type :string-column
           :display-func h871-pf-v05-display-instance :initial-width 14)
          (:label "Density Base" :type :string-column
           :display-func h871-pf-v05-display-base :initial-width 12)
          (:label "Assembly Path" :type :string-column
           :display-func h871-pf-v05-display-path :initial-width 48)))
    (ignore-errors (sd-destroy-graphical-browser *h871-pf-v05-browser*))
    (ignore-errors (sd-destroy-browser-tree *h871-pf-v05-tree*))
    (sd-display-error "H871: Could not define the Results table.")
    (return-from h871-pf-v05-rebuild-results-browser nil))
  (sd-browser-set-active-table
    *h871-pf-v05-browser* :table-name "h871-pf-v05-results-table")
  (sd-browser-exec-cmd *h871-pf-v05-browser* :set-table-mode)
  (unless (sd-show-graphical-browser *h871-pf-v05-browser*)
    (h871-pf-v05-reset-browser-objects)
    (sd-display-error "H871: Could not show the Results Browser.")
    (return-from h871-pf-v05-rebuild-results-browser nil))
  (h871-pf-v05-activate-page *h871-pf-v05-current-page* t)
  t)

(defun h871-pf-v05-run (assembly requested-instance requested-base)
  ;; Save the active page's selection before a new search rebuilds the Browser.
  (when (stringp *h871-pf-v05-current-page*)
    (h871-pf-v05-save-current-selection))
  (setf *h871-pf-v05-assembly* assembly)
  (let ((matches
          (h871-pf-v05-collect
            assembly nil requested-instance requested-base)))
    (if (null matches)
        (progn
          (sd-display-message
            (format nil "No Parts matched Density Instance ~A and Density Base ~A. Existing Results pages were preserved."
              requested-instance requested-base))
          (values 0 nil))
      (progn
        (setf *h871-pf-v05-current-page*
          (h871-pf-v05-store-page
            requested-instance requested-base matches))
        (h871-pf-v05-trace
          "SEARCH/PAGE-STORED"
          (list requested-instance requested-base (length matches)
                *h871-pf-v05-current-page*))
        (unless (h871-pf-v05-rebuild-results-browser)
          (return-from h871-pf-v05-run nil))
        (sd-browser-set-status-text
          *h871-pf-v05-browser* :value
          (format nil "~A matching Part(s) | ~A page(s)"
            (length matches) (length *h871-pf-v05-pages*)))
        (values (length matches) *h871-pf-v05-current-page*)))))

;; The ver-02 user-facing Process/Material mapping is retained unchanged.
(sd-defdialog 'h871_part_filter_ver_05
  :dialog-title "H871 - PART FILTER VER-05"
  :variables
  '(
    ("ASSEMBLY")
    (ASSEMBLY :value-type :assembly
      :title "Select Assembly" :prompt-text "Select assembly to scan.")
    ("MACHINING PROCESS")
    (MACHINING_PROCESS
      :range ((1 :label "CNC") (2 :label "KH")
              (3 :label "CG") (4 :label "COVER"))
      :initial-value 1 :title "Machining Process"
      :after-input (setq MACHINING_PROCESS_CODE MACHINING_PROCESS))
    (MACHINING_PROCESS_CODE
      :value-type :display-only :initial-value 1 :title "Process Code")
    ("MATERIAL")
    (MATERIAL
      :range ((6061 :label "A6061") (201 :label "SUS201")
              (304 :label "SUS304") (400 :label "SS400")
              (10 :label "POM") (20 :label "Bakelit")
              (30 :label "MC") (40 :label "MIKA") (50 :label "PU"))
      :initial-value 304 :title "Material"
      :after-input (setq MATERIAL_CODE MATERIAL))
    (MATERIAL_CODE
      :value-type :display-only :initial-value 304 :title "Material Code"))
  :ok-action
  '(progn
     (h871-pf-v05-run assembly machining_process material)
     (sd-return-from-ok-action)))

;; LOAD this file, then run H871_PART_FILTER_VER_05.
;; Test at least two Density pairs, individual row selection, Select All,
;; page-local selection restore, and actual viewport selection after Apply.
