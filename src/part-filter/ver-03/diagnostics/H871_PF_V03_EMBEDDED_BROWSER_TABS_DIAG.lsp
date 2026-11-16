;; ============================================================================
;; H871 PART FILTER - EMBEDDED NATIVE BROWSER / TABS DIAGNOSTIC
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Purpose:
;; - Isolate the host-shell + Graphical Browser parent integration.
;; - Reuse the already-open ver-03 Results pages and Part data.
;; - Show ONE window: UICT horizontal tabs above ONE Graphical Browser.
;; - Keep the Graphical Browser's own native Apply/OK action.
;; - No hidden Apply bridge and no second visible Graphical Browser.
;;
;; Preconditions:
;; 1. Load the current ver-03 source.
;; 2. Search at least one Density pair so the ver-03 Results window exists.
;; 3. Run H871_PF_V03_EMBEDDED_BROWSER_TABS_DIAG.
;;
;; This is diagnostic-only. It does not modify ver-03 production source.
;; ============================================================================

(in-package :oli)

(defvar *h871-pf-v04-pages* nil)
(defvar *h871-pf-v04-current-page* nil)
(defvar *h871-pf-v04-page-root-map* nil)
(defvar *h871-pf-v04-part-node-map* nil)
(defvar *h871-pf-v04-browser-ready* nil)

(defvar *h871-pf-v04-host* "H871-PF-V04-RESULTS")
(defvar *h871-pf-v04-host-area* "H871-PF-V04-RESULTS-RG")
(defvar *h871-pf-v04-browser-area* "H871-PF-V04-BROWSER-RG")
(defvar *h871-pf-v04-tabs* "H871-PF-V04-TABS")
(defvar *h871-pf-v04-browser* "H871-PF-V04-RESULTS-BROWSER")
(defvar *h871-pf-v04-tree* "H871-PF-V04-RESULTS-TREE")

(defun h871-pf-v04-trace-file ()
  (merge-pathnames
    "H871_PF_V04_EMBEDDED_BROWSER_TRACE.txt"
    (user-homedir-pathname)))

(defun h871-pf-v04-trace-reset ()
  (with-open-file
    (stream (h871-pf-v04-trace-file)
      :direction :output :if-exists :supersede :if-does-not-exist :create)
    (format stream "H871 V04 EMBEDDED BROWSER DIAGNOSTIC~%")
    (force-output stream))
  t)

(defun h871-pf-v04-trace (stage &optional detail)
  (with-open-file
    (stream (h871-pf-v04-trace-file)
      :direction :output :if-exists :append :if-does-not-exist :create)
    (format stream "~A | ~S~%" stage detail)
    (force-output stream))
  t)

(defun h871-pf-v04-name (obj)
  (or (sd-inq-obj-basename obj) "<NO NAME>"))

(defun h871-pf-v04-path (obj)
  (or (sd-inq-obj-pathname obj) "<NO PATH>"))

(defun h871-pf-v04-density-value (part key)
  (let ((value (sd-inq-part-density part key)))
    (if (numberp value)
        (/ value 1000.0)
      nil)))

(defun h871-pf-v04-page-by-name (page-name)
  (find-if
    (lambda (entry) (equal (getf entry :page) page-name))
    *h871-pf-v04-pages*))

(defun h871-pf-v04-page-root-id (page-name)
  (cdr (assoc page-name *h871-pf-v04-page-root-map* :test #'equal)))

(defun h871-pf-v04-part-node-id (page-name part-path)
  (let ((item
          (find-if
            (lambda (entry)
              (and (equal (first entry) page-name)
                   (equal (second entry) part-path)))
            *h871-pf-v04-part-node-map*)))
    (and item (third item))))

(defun h871-pf-v04-node-data (node)
  (and node (BrowserNode-objClientData node)))

(defun h871-pf-v04-display-part-name (node browser-name)
  (let ((data (h871-pf-v04-node-data node)))
    (if (eq (getf data :kind) :part)
        (BrowserNode-objPname node)
      "")))

(defun h871-pf-v04-display-instance (node browser-name)
  (let* ((data (h871-pf-v04-node-data node))
         (value (getf data :instance)))
    (if (and (eq (getf data :kind) :part) (numberp value))
        (format nil "~A" value)
      "")))

(defun h871-pf-v04-display-base (node browser-name)
  (let* ((data (h871-pf-v04-node-data node))
         (value (getf data :base)))
    (if (and (eq (getf data :kind) :part) (numberp value))
        (format nil "~A" value)
      "")))

(defun h871-pf-v04-display-path (node browser-name)
  (let ((data (h871-pf-v04-node-data node)))
    (if (eq (getf data :kind) :part)
        (BrowserNode-objPath node)
      "")))

(defun h871-pf-v04-build-tree ()
  ;; One tree contains every result page. Each page node is a table root;
  ;; its direct Part children become the visible rows for that tab.
  (let ((root
          (sd-create-browsernode
            :tree *h871-pf-v04-tree*
            :parent nil
            :objPath "/H871_PF_V04_RESULTS"
            :objPname "H871 Results"
            :objClientData (list :kind :root))))
    (setf *h871-pf-v04-page-root-map* nil)
    (setf *h871-pf-v04-part-node-map* nil)
    (dolist (entry (reverse *h871-pf-v04-pages*))
      (let* ((page-name (getf entry :page))
             (label (getf entry :label))
             (page-id
               (sd-create-browsernode
                 :tree *h871-pf-v04-tree*
                 :parent root
                 :objPath (format nil "/H871_PF_V04_RESULTS/~A" page-name)
                 :objPname label
                 :objClientData
                   (list :kind :page :page page-name))))
        (push (cons page-name page-id) *h871-pf-v04-page-root-map*)
        (dolist (part (getf entry :results))
          (let* ((part-path (h871-pf-v04-path part))
                 (node-id
                   (sd-create-browsernode
                     :tree *h871-pf-v04-tree*
                     :parent page-id
                     :objPath part-path
                     :objPname (h871-pf-v04-name part)
                     :objClientData
                       (list :kind :part
                             :page page-name
                             :part part
                             :instance (h871-pf-v04-density-value part :instance)
                             :base (h871-pf-v04-density-value part :contents)))))
            (push (list page-name part-path node-id)
                  *h871-pf-v04-part-node-map*)))))
    (h871-pf-v04-trace
      "TREE/BUILT"
      (list (length *h871-pf-v04-pages*)
            (length *h871-pf-v04-page-root-map*)
            (length *h871-pf-v04-part-node-map*)))
    root))

(defun h871-pf-v04-save-current-selection ()
  (when (and *h871-pf-v04-browser-ready*
             (stringp *h871-pf-v04-current-page*))
    (let ((paths nil)
          (entry (h871-pf-v04-page-by-name *h871-pf-v04-current-page*)))
      (dolist (node
                (or (sd-query-browser
                      *h871-pf-v04-browser* :get-selected-objects)
                    nil))
        (let ((data (h871-pf-v04-node-data node)))
          (when (eq (getf data :kind) :part)
            (push (BrowserNode-objPath node) paths))))
      (when entry
        (setf (getf entry :selected-paths) (nreverse paths)))
      (h871-pf-v04-trace
        "PAGE/SAVE-SELECTION"
        (list *h871-pf-v04-current-page* (length paths))))))

(defun h871-pf-v04-update-status (page-name)
  (let ((entry (h871-pf-v04-page-by-name page-name)))
    (when entry
      (sd-browser-set-status-text
        *h871-pf-v04-browser*
        :type :table
        :value
          (format nil "~A | ~A Part(s) | Density Instance ~A / Base ~A"
            (getf entry :label)
            (length (getf entry :results))
            (getf entry :instance)
            (getf entry :base))))))

(defun h871-pf-v04-activate-page (page-name &optional skip-save)
  (let ((entry (h871-pf-v04-page-by-name page-name)))
    (when (and entry *h871-pf-v04-browser-ready*)
      (unless skip-save
        (unless (equal page-name *h871-pf-v04-current-page*)
          (h871-pf-v04-save-current-selection)))
      (sd-browser-exec-cmd *h871-pf-v04-browser* :clear-select-list)
      (let* ((node-id (h871-pf-v04-page-root-id page-name))
             (node (and node-id
                        (sd-get-browsernode-struct
                          *h871-pf-v04-tree* node-id))))
        (unless node
          (h871-pf-v04-trace "PAGE/ROOT-NOT-FOUND" page-name)
          (return-from h871-pf-v04-activate-page nil))
        (let ((root-result
                (sd-browser-exec-cmd
                  *h871-pf-v04-browser* :change-table-root node t)))
          (h871-pf-v04-trace "PAGE/CHANGE-ROOT" (list page-name root-result))))
      (setf *h871-pf-v04-current-page* page-name)
      ;; Restore only this page's saved selection. The Part BrowserNodes are
      ;; direct children of the active table root and therefore visible.
      (dolist (part-path (getf entry :selected-paths))
        (let* ((node-id (h871-pf-v04-part-node-id page-name part-path))
               (node (and node-id
                          (sd-get-browsernode-struct
                            *h871-pf-v04-tree* node-id))))
          (when node
            (h871-pf-v04-trace
              "PAGE/RESTORE-ROW"
              (list page-name part-path
                    (sd-browser-exec-cmd
                      *h871-pf-v04-browser* :set-object-selection node t))))))
      (h871-pf-v04-update-status page-name)
      (h871-pf-v04-trace "PAGE/ACTIVE" page-name)
      t)))

(defun h871-pf-v04-tab-changed (page-name)
  (h871-pf-v04-trace "TAB/CHANGED" page-name)
  (when (stringp page-name)
    (if *h871-pf-v04-browser-ready*
        (h871-pf-v04-activate-page page-name)
      (setf *h871-pf-v04-current-page* page-name))))

(defun h871-pf-v04-select-all ()
  (sd-browser-exec-cmd *h871-pf-v04-browser* :select-all)
  (h871-pf-v04-update-status *h871-pf-v04-current-page*)
  t)

(defun h871-pf-v04-clear-selection ()
  (sd-browser-exec-cmd *h871-pf-v04-browser* :clear-select-list)
  (when (stringp *h871-pf-v04-current-page*)
    (let ((entry (h871-pf-v04-page-by-name *h871-pf-v04-current-page*)))
      (when entry
        (setf (getf entry :selected-paths) nil)))
    (h871-pf-v04-update-status *h871-pf-v04-current-page*))
  t)

(defun h871-pf-v04-close-results ()
  (ignore-errors
    (sd-hide-dialog-shell *h871-pf-v04-host* :ignorePin t))
  (when (and (boundp '*h871-pf-v03-shell*)
             (stringp *h871-pf-v03-shell*)
             (sd-dialog-shell-p *h871-pf-v03-shell*))
    (sd-show-dialog-shell *h871-pf-v03-shell*))
  t)

(defun h871-pf-v04-create-host ()
  (h871-pf-v04-trace "HOST/CREATE-BEGIN" nil)
  (unless
    (sd-create-resizable-dialog-shell
      *h871-pf-v04-host*
      :title "H871 - PART FILTER RESULTS"
      :width 980 :height 780
      :margin 0 :spacing 0 :cellSize 1,1)
    (h871-pf-v04-trace "HOST/CREATE-SHELL-FAILED" nil)
    (return-from h871-pf-v04-create-host nil))

  ;; The UICT tabs and embedded native Graphical Browser are siblings in the
  ;; same resizable shell. The browser's immediate parent is a resizable area.
  (unless
    (sd-create-tab-control
      *h871-pf-v04-tabs* *h871-pf-v04-host-area*
      :x 0 :y 0 :width 980 :height 38
      :tabChangedAction #'h871-pf-v04-tab-changed)
    (h871-pf-v04-trace "HOST/CREATE-TABS-FAILED" nil)
    (return-from h871-pf-v04-create-host nil))

  (unless
    (sd-create-resizable-grid-area
      *h871-pf-v04-browser-area* *h871-pf-v04-host-area*
      :x 0 :y 38 :width 980 :height 742
      :cellSize 1,1 :margin 0 :spacing 0)
    (h871-pf-v04-trace "HOST/CREATE-BROWSER-AREA-FAILED" nil)
    (return-from h871-pf-v04-create-host nil))

  (sd-set-control-binding *h871-pf-v04-browser-area* '(:resize-both))
  (h871-pf-v04-trace "HOST/CREATE-OK"
    (list (sd-control-p *h871-pf-v04-host-area*)
          (sd-control-p *h871-pf-v04-browser-area*)))
  t)

(defun h871-pf-v04-create-browser ()
  (h871-pf-v04-trace "BROWSER/CREATE-TREE-BEGIN" nil)
  (unless
    (sd-create-browser-tree
      *h871-pf-v04-tree*
      :update-events oli:*SD-CHANGE-OBJECT-TREE-EVENT*
      :update-func 'h871-pf-v04-build-tree)
    (h871-pf-v04-trace "BROWSER/CREATE-TREE-FAILED" nil)
    (return-from h871-pf-v04-create-browser nil))

  (unless (h871-pf-v04-build-tree)
    (h871-pf-v04-trace "BROWSER/BUILD-TREE-FAILED" nil)
    (return-from h871-pf-v04-create-browser nil))

  (unless
    (sd-create-graphical-browser
      *h871-pf-v04-browser*
      :tree *h871-pf-v04-tree*
      :topLabel "H871 - PART FILTER RESULTS"
      :tableStatusBar "Select result rows, then press Apply."
      :minHeight 250
      :maxWidth 980
      :maxHeight 740
      :okButtonLabel "Apply"
      :abortButtonLabel "Close Results"
      :abortButtonAction '(h871-pf-v04-close-results)
      :buttonMenu
        '(( "select-all"
            :label "Select All"
            :push (h871-pf-v04-select-all))
          ( "clear-selection"
            :label "Clear Selection"
            :push (h871-pf-v04-clear-selection))))
    (h871-pf-v04-trace "BROWSER/CREATE-BROWSER-FAILED" nil)
    (return-from h871-pf-v04-create-browser nil))

  (unless
    (sd-browser-define-table
      *h871-pf-v04-browser*
      :table-name "h871-pf-v04-results-table"
      :with-name-column nil
      :column-definition
        '((:label "Part Name"
           :type :string-column
           :display-func h871-pf-v04-display-part-name
           :initial-width 28)
          (:label "Density Instance"
           :type :string-column
           :display-func h871-pf-v04-display-instance
           :initial-width 14)
          (:label "Density Base"
           :type :string-column
           :display-func h871-pf-v04-display-base
           :initial-width 12)
          (:label "Assembly Path"
           :type :string-column
           :display-func h871-pf-v04-display-path
           :initial-width 48)))
    (h871-pf-v04-trace "BROWSER/DEFINE-TABLE-FAILED" nil)
    (return-from h871-pf-v04-create-browser nil))

  (sd-browser-set-active-table
    *h871-pf-v04-browser* :table-name "h871-pf-v04-results-table")
  (sd-browser-exec-cmd *h871-pf-v04-browser* :set-table-mode)
  (h871-pf-v04-trace "BROWSER/CREATE-OK" nil)
  t)

(defun h871-pf-v04-capture-ui-selection (entry)
  (let* ((table-name (getf entry :table))
         (selection (and (stringp table-name)
                         (sd-display-table-p table-name)
                         (sd-get-display-table-selection table-name)))
         (columns (and selection (cadr selection)))
         (parts (and columns (getf columns :part-object))))
    (if parts
        (mapcar #'h871-pf-v04-path parts)
      nil)))

(defun h871-pf-v04-run-diagnostic ()
  (h871-pf-v04-trace-reset)
  (h871-pf-v04-trace "DIAG/BEGIN" nil)
  (unless (and (boundp '*h871-pf-v03-pages*)
               (listp *h871-pf-v03-pages*)
               *h871-pf-v03-pages*)
    (sd-display-error
      "H871 V04 diagnostic: Load ver-03 and create at least one Results tab first.")
    (return-from h871-pf-v04-run-diagnostic nil))

  ;; Copy the existing page data; do not mutate the production ver-03 registry.
  (setf *h871-pf-v04-pages*
    (mapcar
      (lambda (entry)
        (let ((copy (copy-list entry)))
          (setf (getf copy :selected-paths)
            (h871-pf-v04-capture-ui-selection entry))
          copy))
      *h871-pf-v03-pages*))
  (setf *h871-pf-v04-current-page*
    (if (and (boundp '*h871-pf-v03-current-page*)
             (stringp *h871-pf-v03-current-page*))
        *h871-pf-v03-current-page*
      (getf (car *h871-pf-v04-pages*) :page)))
  (setf *h871-pf-v04-browser-ready* nil)

  (h871-pf-v04-trace "DIAG/PAGES-COPIED"
    (mapcar
      (lambda (entry)
        (list (getf entry :label)
              (getf entry :page)
              (length (getf entry :results))
              (length (getf entry :selected-paths))))
      (reverse *h871-pf-v04-pages*)))

  (unless (h871-pf-v04-create-host)
    (sd-display-error
      "H871 V04 diagnostic: Could not create the single-window host. See trace.")
    (return-from h871-pf-v04-run-diagnostic nil))

  (unless (h871-pf-v04-create-browser)
    (ignore-errors (sd-destroy-dialog-shell *h871-pf-v04-host*))
    (ignore-errors (sd-destroy-graphical-browser *h871-pf-v04-browser*))
    (ignore-errors (sd-destroy-browser-tree *h871-pf-v04-tree*))
    (sd-display-error
      "H871 V04 diagnostic: Could not create the native Results Browser. See trace.")
    (return-from h871-pf-v04-run-diagnostic nil))

  ;; Reparent the not-yet-shown floating browser into the hidden host shell.
  ;; Do not call sd-show-graphical-browser here: that would expose a second
  ;; top-level window and violate the one-window test requirement.
  (let ((parent-result
          (sd-set-graphical-browser-parent
            *h871-pf-v04-browser*
            *h871-pf-v04-host*
            *h871-pf-v04-browser-area*
            :dockable nil)))
    (h871-pf-v04-trace "DIAG/PARENT-RESULT" parent-result)
    (unless parent-result
      (ignore-errors (sd-destroy-graphical-browser *h871-pf-v04-browser*))
      (ignore-errors (sd-destroy-browser-tree *h871-pf-v04-tree*))
      (ignore-errors (sd-destroy-dialog-shell *h871-pf-v04-host*))
      (when (and (boundp '*h871-pf-v03-shell*)
                 (sd-dialog-shell-p *h871-pf-v03-shell*))
        (sd-show-dialog-shell *h871-pf-v03-shell*))
      (sd-display-error
        "H871 V04 diagnostic: Browser-parent assignment failed. Original ver-03 Results restored. See trace.")
      (return-from h871-pf-v04-run-diagnostic nil)))

  ;; Create the same internal tab labels in the host window.
  (dolist (entry (reverse *h871-pf-v04-pages*))
    (unless
      (sd-insert-tab-control-page
        (getf entry :page) *h871-pf-v04-tabs*
        :tabTitle (getf entry :label)
        :cellSize 10,10 :margin 2 :spacing 0)
      (h871-pf-v04-trace
        "DIAG/INSERT-TAB-FAILED"
        (list (getf entry :page) (getf entry :label)))))

  (setf *h871-pf-v04-browser-ready* t)
  (when (stringp *h871-pf-v04-current-page*)
    (h871-pf-v04-trace "DIAG/SET-CURRENT-TAB"
      (sd-set-current-tab-control-page
        *h871-pf-v04-tabs* :page *h871-pf-v04-current-page*)))
  (unless (h871-pf-v04-activate-page *h871-pf-v04-current-page* t)
    (h871-pf-v04-trace "DIAG/INITIAL-PAGE-ACTIVATE-FAILED"
      *h871-pf-v04-current-page*))

  (when (and (boundp '*h871-pf-v03-shell*)
             (sd-dialog-shell-visible-p *h871-pf-v03-shell*))
    (sd-hide-dialog-shell *h871-pf-v03-shell* :ignorePin t))

  (let ((shown (sd-show-dialog-shell *h871-pf-v04-host*)))
    (h871-pf-v04-trace "DIAG/SHOW-HOST" shown)
    (unless shown
      (setf *h871-pf-v04-browser-ready* nil)
      (ignore-errors (sd-destroy-graphical-browser *h871-pf-v04-browser*))
      (ignore-errors (sd-destroy-browser-tree *h871-pf-v04-tree*))
      (ignore-errors (sd-destroy-dialog-shell *h871-pf-v04-host*))
      (when (and (boundp '*h871-pf-v03-shell*)
                 (sd-dialog-shell-p *h871-pf-v03-shell*))
        (sd-show-dialog-shell *h871-pf-v03-shell*))
      (sd-display-error
        "H871 V04 diagnostic: Could not show the integrated Results window. See trace.")
      (return-from h871-pf-v04-run-diagnostic nil)))

  (h871-pf-v04-trace "DIAG/END" :success)
  (sd-display-message
    "H871 V04 diagnostic: One Results window with internal tabs and native Apply is open. Test row selection and Apply.")
  t)

(sd-defdialog 'h871_pf_v04_embedded_browser_tabs_diag
  :dialog-title "H871 V04 Embedded Browser Diagnostic"
  :dialog-control :sequential
  :variables '()
  :ok-action '(h871-pf-v04-run-diagnostic))

;; COMMAND:
;; H871_PF_V04_EMBEDDED_BROWSER_TABS_DIAG
;;
;; TEST:
;; 1. Load ver-03 source and create at least two Density result tabs.
;; 2. Select some rows in the active ver-03 tab (optional; selection is copied).
;; 3. Run H871_PF_V04_EMBEDDED_BROWSER_TABS_DIAG.
;; 4. Confirm there is only one visible Results window and all page tabs appear.
;; 5. Switch tabs; verify each page shows only its own Part rows.
;; 6. Select one row and press the Graphical Browser's native Apply button.
;; 7. Confirm the intended Part is selected in the 3D viewport.
;; 8. Test multiple rows and Select All / Clear Selection.
;; 9. If parent assignment fails, the original ver-03 Results window is restored.
;;
;; TRACE:
;; H871_PF_V04_EMBEDDED_BROWSER_TRACE.txt in the user's home folder.
