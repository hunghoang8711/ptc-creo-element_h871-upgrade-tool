;; ============================================================================
;; H871 PART FILTER - SINGLE GRAPHICAL BROWSER / MULTI-PAGE DIAGNOSTIC
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; This diagnostic avoids the previously failed Browser-parent/reparent path.
;; It uses ONE visible Graphical Browser for all Density-pair pages:
;; - One Browser Tree with one page root per Density pair.
;; - One Browser table and one native Apply button.
;; - Previous/Next toolbar buttons plus a dynamic "Results Pages" popup menu.
;; - Page-local selection is saved/restored while changing table roots.
;;
;; UI note:
;; This is a page-navigation prototype, not the final horizontal tab strip.
;; It isolates whether same-browser native Apply can coexist with multiple
;; result pages without creating one Graphical Browser per query.
;;
;; Preconditions:
;; 1. Load the current ver-03 source.
;; 2. Run at least two searches so two Results pages exist.
;; 3. Run H871_PF_V03_SINGLE_BROWSER_PAGES_DIAG.
;; ============================================================================

(in-package :oli)

(defvar *h871-pf-v04-pages* nil)
(defvar *h871-pf-v04-current-page* nil)
(defvar *h871-pf-v04-page-root-map* nil)
(defvar *h871-pf-v04-part-node-map* nil)
(defvar *h871-pf-v04-browser* "H871-PF-V04-SINGLE-RESULTS")
(defvar *h871-pf-v04-tree* "H871-PF-V04-SINGLE-RESULTS-TREE")
(defvar *h871-pf-v04-menu-name* "H871-PF-V04-RESULT-PAGES-MENU")

(defun h871-pf-v04-trace-file ()
  (merge-pathnames
    "H871_PF_V04_SINGLE_BROWSER_TRACE.txt"
    (user-homedir-pathname)))

(defun h871-pf-v04-trace-reset ()
  (with-open-file
    (stream (h871-pf-v04-trace-file)
      :direction :output :if-exists :supersede :if-does-not-exist :create)
    (format stream "H871 V04 SINGLE BROWSER DIAGNOSTIC~%")
    (force-output stream))
  t)

(defun h871-pf-v04-trace (stage &optional detail)
  (with-open-file
    (stream (h871-pf-v04-trace-file)
      :direction :output :if-exists :append :if-does-not-exist :create)
    (format stream "~A | ~S~%" stage detail)
    (force-output stream))
  t)

(defun h871-pf-v04-path (part)
  (or (sd-inq-obj-pathname part) "<NO PATH>"))

(defun h871-pf-v04-name (part)
  (or (sd-inq-obj-basename part) "<NO NAME>"))

(defun h871-pf-v04-density-value (part key)
  (let ((value (sd-inq-part-density part key)))
    (if (numberp value) (/ value 1000.0) nil)))

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

(defun h871-pf-v04-display-name (node browser-name)
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
  ;; ver-02-style BrowserNode tree: one page root, direct Part children.
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
             (page-id
               (sd-create-browsernode
                 :tree *h871-pf-v04-tree*
                 :parent root
                 :objPath (format nil "/H871_PF_V04_RESULTS/~A" page-name)
                 :objPname (getf entry :label)
                 :objClientData (list :kind :page :page page-name))))
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
  (when (stringp *h871-pf-v04-current-page*)
    (let ((paths nil)
          (entry (h871-pf-v04-page-by-name *h871-pf-v04-current-page*)))
      (dolist (node
                (or (sd-query-browser
                      *h871-pf-v04-browser* :get-selected-objects)
                    nil))
        (let ((data (h871-pf-v04-node-data node)))
          (when (and (eq (getf data :kind) :part)
                     (equal (getf data :page) *h871-pf-v04-current-page*))
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
    (when entry
      (unless (or skip-save (equal page-name *h871-pf-v04-current-page*))
        (h871-pf-v04-save-current-selection))
      (sd-browser-exec-cmd *h871-pf-v04-browser* :clear-select-list)
      (let* ((node-id (h871-pf-v04-page-root-id page-name))
             (node (and node-id
                        (sd-get-browsernode-struct
                          *h871-pf-v04-tree* node-id))))
        (unless node
          (h871-pf-v04-trace "PAGE/ROOT-NOT-FOUND" page-name)
          (return-from h871-pf-v04-activate-page nil))
        (h871-pf-v04-trace
          "PAGE/CHANGE-ROOT"
          (list page-name
                (sd-browser-exec-cmd
                  *h871-pf-v04-browser* :change-table-root node t))))
      (setf *h871-pf-v04-current-page* page-name)
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

(defun h871-pf-v04-menu-visible (node browser-name page-name)
  t)

(defun h871-pf-v04-menu-applicable (node browser-name page-name)
  (not (null (h871-pf-v04-page-by-name page-name))))

(defun h871-pf-v04-menu-action (node browser-name page-name)
  (h871-pf-v04-activate-page page-name)
  t)

(defun h871-pf-v04-add-page-menu ()
  (sd-browser-add-popup-entry
    *h871-pf-v04-browser*
    :label "Results Pages"
    :entry-type :sub-menu
    :sub-menu-name *h871-pf-v04-menu-name*
    :new-group t)
  (dolist (entry (reverse *h871-pf-v04-pages*))
    (h871-pf-v04-trace
      "MENU/ADD-PAGE"
      (list (getf entry :label)
            (sd-browser-add-popup-entry
              *h871-pf-v04-browser*
              :label (getf entry :label)
              :parent-menu-name *h871-pf-v04-menu-name*
              :string-client-data (getf entry :page)
              :is-entry-visible 'h871-pf-v04-menu-visible
              :is-entry-applicable 'h871-pf-v04-menu-applicable
              :menu-action 'h871-pf-v04-menu-action)))))

(defun h871-pf-v04-page-order ()
  (reverse *h871-pf-v04-pages*))

(defun h871-pf-v04-switch-offset (offset)
  (let* ((pages (h871-pf-v04-page-order))
         (count (length pages))
         (current-index
           (position *h871-pf-v04-current-page* pages
             :key (lambda (entry) (getf entry :page))
             :test #'equal)))
    (when (> count 0)
      (let* ((index (if current-index
                        (mod (+ current-index offset) count)
                      0))
             (entry (nth index pages)))
        (h871-pf-v04-activate-page (getf entry :page))))))

(defun h871-pf-v04-previous-page ()
  (h871-pf-v04-switch-offset -1))

(defun h871-pf-v04-next-page ()
  (h871-pf-v04-switch-offset 1))

(defun h871-pf-v04-select-all ()
  (sd-browser-exec-cmd *h871-pf-v04-browser* :select-all)
  (h871-pf-v04-update-status *h871-pf-v04-current-page*)
  t)

(defun h871-pf-v04-clear-selection ()
  (sd-browser-exec-cmd *h871-pf-v04-browser* :clear-select-list)
  (let ((entry (h871-pf-v04-page-by-name *h871-pf-v04-current-page*)))
    (when entry
      (setf (getf entry :selected-paths) nil)))
  (h871-pf-v04-update-status *h871-pf-v04-current-page*)
  t)

(defun h871-pf-v04-close-results ()
  (ignore-errors
    (sd-hide-graphical-browser *h871-pf-v04-browser* :ignore-pin t))
  (when (and (boundp '*h871-pf-v03-shell*)
             (stringp *h871-pf-v03-shell*)
             (sd-dialog-shell-p *h871-pf-v03-shell*))
    (sd-show-dialog-shell *h871-pf-v03-shell*))
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
  (unless (and (boundp '*h871-pf-v03-pages*)
               (listp *h871-pf-v03-pages*)
               *h871-pf-v03-pages*)
    (sd-display-error
      "H871 V04 diagnostic: Load ver-03 and create at least one Results tab first.")
    (return-from h871-pf-v04-run-diagnostic nil))

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

  (h871-pf-v04-trace
    "DIAG/PAGES-COPIED"
    (mapcar
      (lambda (entry)
        (list (getf entry :label)
              (getf entry :page)
              (length (getf entry :results))
              (length (getf entry :selected-paths))))
      (reverse *h871-pf-v04-pages*)))

  (unless
    (sd-create-browser-tree
      *h871-pf-v04-tree*
      :update-events oli:*SD-CHANGE-OBJECT-TREE-EVENT*
      :update-func 'h871-pf-v04-build-tree)
    (sd-display-error "H871 V04 diagnostic: Could not create the Browser Tree.")
    (return-from h871-pf-v04-run-diagnostic nil))

  (unless
    (sd-create-graphical-browser
      *h871-pf-v04-browser*
      :tree *h871-pf-v04-tree*
      :topLabel "H871 - PART FILTER RESULTS"
      :tableStatusBar "Use Previous/Next or right-click > Results Pages."
      :minHeight 280
      :maxWidth 980
      :maxHeight 760
      :okButtonLabel "Apply"
      :abortButtonLabel "Close Results"
      :abortButtonAction '(h871-pf-v04-close-results)
      :buttonMenu
        '(( "previous-page"
            :label "Previous Page"
            :push (h871-pf-v04-previous-page))
          ( "next-page"
            :label "Next Page"
            :push (h871-pf-v04-next-page))
          ( "select-all"
            :label "Select All"
            :push (h871-pf-v04-select-all))
          ( "clear-selection"
            :label "Clear Selection"
            :push (h871-pf-v04-clear-selection))))
    (ignore-errors (sd-destroy-browser-tree *h871-pf-v04-tree*))
    (sd-display-error "H871 V04 diagnostic: Could not create the Graphical Browser.")
    (return-from h871-pf-v04-run-diagnostic nil))

  (unless
    (sd-browser-define-table
      *h871-pf-v04-browser*
      :table-name "h871-pf-v04-results-table"
      :with-name-column nil
      :column-definition
        '((:label "Part Name"
           :type :string-column
           :display-func h871-pf-v04-display-name
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
    (ignore-errors (sd-destroy-graphical-browser *h871-pf-v04-browser*))
    (ignore-errors (sd-destroy-browser-tree *h871-pf-v04-tree*))
    (sd-display-error "H871 V04 diagnostic: Could not define the Results table.")
    (return-from h871-pf-v04-run-diagnostic nil))

  (sd-browser-set-active-table
    *h871-pf-v04-browser* :table-name "h871-pf-v04-results-table")
  (sd-browser-exec-cmd *h871-pf-v04-browser* :set-table-mode)

  ;; Only one window is visible at a time: hide the current UICT Results shell
  ;; before showing the one native Graphical Browser Results window.
  (when (and (boundp '*h871-pf-v03-shell*)
             (sd-dialog-shell-visible-p *h871-pf-v03-shell*))
    (sd-hide-dialog-shell *h871-pf-v03-shell* :ignorePin t))

  (let ((shown (sd-show-graphical-browser *h871-pf-v04-browser*)))
    (h871-pf-v04-trace "DIAG/SHOW-BROWSER" shown)
    (unless shown
      (ignore-errors (sd-destroy-graphical-browser *h871-pf-v04-browser*))
      (ignore-errors (sd-destroy-browser-tree *h871-pf-v04-tree*))
      (when (and (boundp '*h871-pf-v03-shell*)
                 (sd-dialog-shell-p *h871-pf-v03-shell*))
        (sd-show-dialog-shell *h871-pf-v03-shell*))
      (sd-display-error "H871 V04 diagnostic: Could not show Results Browser.")
      (return-from h871-pf-v04-run-diagnostic nil)))

  ;; The browser's update callback builds all page roots before this lookup.
  (let* ((page-id (h871-pf-v04-page-root-id *h871-pf-v04-current-page*))
         (page-node (and page-id
                         (sd-get-browsernode-struct
                           *h871-pf-v04-tree* page-id))))
    (unless page-node
      (h871-pf-v04-trace "DIAG/ACTIVE-ROOT-MISSING"
        (list *h871-pf-v04-current-page* *h871-pf-v04-page-root-map*))
      (sd-hide-graphical-browser *h871-pf-v04-browser* :ignore-pin t)
      (when (and (boundp '*h871-pf-v03-shell*)
                 (sd-dialog-shell-p *h871-pf-v03-shell*))
        (sd-show-dialog-shell *h871-pf-v03-shell*))
      (sd-display-error "H871 V04 diagnostic: Active page root was not built.")
      (return-from h871-pf-v04-run-diagnostic nil))
    (h871-pf-v04-trace
      "DIAG/INITIAL-ROOT"
      (sd-browser-exec-cmd
        *h871-pf-v04-browser* :change-table-root page-node t)))

  (h871-pf-v04-add-page-menu)
  (h871-pf-v04-activate-page *h871-pf-v04-current-page* t)
  (h871-pf-v04-trace "DIAG/END" :success)
  (sd-display-message
    "H871 V04 diagnostic: One native Results Browser is open. Use Previous/Next or right-click > Results Pages. Apply is the browser's native button.")
  t)

(sd-defdialog 'h871_pf_v04_single_browser_pages_diag
  :dialog-title "H871 V04 Single Browser Pages Diagnostic"
  :dialog-control :sequential
  :variables '()
  :ok-action '(h871-pf-v04-run-diagnostic))

;; COMMAND:
;; H871_PF_V03_SINGLE_BROWSER_PAGES_DIAG
;;
;; TEST:
;; 1. Load ver-03 source and create at least two Density result pages.
;; 2. Select one or more rows in the active ver-03 page (optional).
;; 3. Run H871_PF_V03_SINGLE_BROWSER_PAGES_DIAG.
;; 4. Confirm only one Results window is visible.
;; 5. Switch pages with Previous/Next or right-click > Results Pages.
;; 6. Verify each page shows only its own Parts.
;; 7. Select one Part and press the native Apply button.
;; 8. Confirm that Part is selected in the 3D viewport.
;; 9. Test multiple rows, Select All, Clear Selection, and page-local selection.
;;
;; TRACE:
;; H871_PF_V04_SINGLE_BROWSER_TRACE.txt in the user's home folder.
