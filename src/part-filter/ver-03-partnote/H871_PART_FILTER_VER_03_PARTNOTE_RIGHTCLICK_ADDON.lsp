;; H871 VER-03-PARTNOTE - RIGHT-CLICK ACTION BROWSER ADD-ON
;; Load after H871_PART_FILTER_VER_03_PARTNOTE.lsp.
(in-package :oli)
(defvar *h871-pf-v03-rc-browser* "h871-pf-v03-note-actions")
(defvar *h871-pf-v03-rc-tree* "h871-pf-v03-note-actions-tree")
(defvar *h871-pf-v03-rc-original-tab-callback* (symbol-function 'h871-pf-v03-tab-changed))
(defvar *h871-pf-v03-rc-original-refresh-page* (symbol-function 'h871-pf-v03-refresh-page))

(defun h871-pf-v03-rc-row-data (node) (browsernode-objclientdata node))
(defun h871-pf-v03-rc-col-name (node browser-name)
  (declare (ignore browser-name)) (getf (h871-pf-v03-rc-row-data node) :name))
(defun h871-pf-v03-rc-col-instance (node browser-name)
  (declare (ignore browser-name))
  (let ((v (getf (h871-pf-v03-rc-row-data node) :instance)))
    (if v (format nil "~A" v) "-")))
(defun h871-pf-v03-rc-col-base (node browser-name)
  (declare (ignore browser-name))
  (let ((v (getf (h871-pf-v03-rc-row-data node) :base)))
    (if v (format nil "~A" v) "-")))
(defun h871-pf-v03-rc-col-path (node browser-name)
  (declare (ignore browser-name)) (getf (h871-pf-v03-rc-row-data node) :path))
(defun h871-pf-v03-rc-col-note (node browser-name)
  (declare (ignore browser-name))
  (let* ((part (getf (h871-pf-v03-rc-row-data node) :part))
         (note (and part (h871-pf-v03-read-note part))))
    (if (and note (> (length note) 0)) note "-")))

(defun h871-pf-v03-rc-build-tree ()
  (let* ((entry (h871-pf-v03-page-by-name *h871-pf-v03-current-page*))
         (root (sd-create-browsernode
                 :tree *h871-pf-v03-rc-tree* :parent nil
                 :objPath "/H871_V03_PARTNOTE_ACTIONS"
                 :objPname "H871 Part Note Actions"
                 :objClientData (list :kind :root))))
    (when entry
      (dolist (part (reverse (getf entry :results)))
        (sd-create-browsernode
          :tree *h871-pf-v03-rc-tree* :parent root
          :objPath (h871-pf-v03-path part) :objPname (h871-pf-v03-name part)
          :objClientData
            (list :kind :part :part part
                  :name (h871-pf-v03-name part)
                  :path (h871-pf-v03-path part)
                  :instance (h871-pf-v03-density-display-value (sd-inq-part-density part :instance))
                  :base (h871-pf-v03-density-display-value (sd-inq-part-density part :contents))))))
    root))

(defun h871-pf-v03-rc-selected-parts ()
  (let ((parts nil))
    (dolist (node (sd-query-browser *h871-pf-v03-rc-browser* :get-selected-objects))
      (let ((data (h871-pf-v03-rc-row-data node)))
        (when (eq (getf data :kind) :part) (push (getf data :part) parts))))
    (nreverse parts)))
(defun h871-pf-v03-rc-select-all ()
  (sd-browser-exec-cmd *h871-pf-v03-rc-browser* :select-all))
(defun h871-pf-v03-rc-clear-selection ()
  (sd-browser-exec-cmd *h871-pf-v03-rc-browser* :clear-select-list))
(defun h871-pf-v03-rc-edit-note ()
  (let ((parts (h871-pf-v03-rc-selected-parts)))
    (cond
      ((null parts) (sd-display-message "Select one Part row before choosing Edit Note."))
      ((cdr parts) (sd-display-message "Edit Note supports one Part at a time."))
      (t
       (setf *h871-pf-v03-note-edit-part* (car parts))
       (setf *h871-pf-v03-note-edit-page* *h871-pf-v03-current-page*)
       (sd-put-buffer "h871_pf_v03_note_editor")))))

(defun h871-pf-v03-rc-open-browser ()
  (when (h871-pf-v03-page-by-name *h871-pf-v03-current-page*)
    (ignore-errors (sd-hide-graphical-browser *h871-pf-v03-rc-browser*))
    (ignore-errors (sd-destroy-graphical-browser *h871-pf-v03-rc-browser*))
    (ignore-errors (sd-destroy-browser-tree *h871-pf-v03-rc-tree*))
    (unless (sd-create-browser-tree *h871-pf-v03-rc-tree*
              :update-events oli:*SD-CHANGE-OBJECT-TREE-EVENT*
              :update-func 'h871-pf-v03-rc-build-tree)
      (sd-display-error "H871 Part Note: Could not create right-click action tree.")
      (return-from h871-pf-v03-rc-open-browser nil))
    (unless (sd-create-graphical-browser
              *h871-pf-v03-rc-browser* :tree *h871-pf-v03-rc-tree*
              :topLabel "H871 - VER-03 PART ACTIONS"
              :treeStatusBar "Right-click a Part row for Select All, Clear Selection, and Edit Note."
              :minHeight 240 :maxWidth 1100 :maxHeight 760 :createAsTab nil
              :buttonMenu
                '(("select-all" :label "Select All" :push (h871-pf-v03-rc-select-all))
                  ("clear-selection" :label "Clear Selection" :push (h871-pf-v03-rc-clear-selection))
                  ("edit-note" :label "Edit Note" :push (h871-pf-v03-rc-edit-note)))
              :buttonMenuOffObjectOnly nil
              :topMenu
                '(("part-actions" :label "Part Actions"
                   :contents
                     (("select-all" :label "Select All" :push (h871-pf-v03-rc-select-all))
                      ("clear-selection" :label "Clear Selection" :push (h871-pf-v03-rc-clear-selection))
                      ("edit-note" :label "Edit Note" :push (h871-pf-v03-rc-edit-note)))))
      (sd-display-error "H871 Part Note: Could not create right-click action browser.")
      (return-from h871-pf-v03-rc-open-browser nil))
    (unless (sd-browser-define-table
              *h871-pf-v03-rc-browser* :table-name "h871-pf-v03-rc-table"
              :with-name-column nil
              :column-definition
                '((:label "Part Name" :type :string-column :display-func h871-pf-v03-rc-col-name :initial-width 28)
                  (:label "Density Instance" :type :string-column :display-func h871-pf-v03-rc-col-instance :initial-width 13)
                  (:label "Density Base" :type :string-column :display-func h871-pf-v03-rc-col-base :initial-width 12)
                  (:label "Assembly Path" :type :string-column :display-func h871-pf-v03-rc-col-path :initial-width 42)
                  (:label "Part Note" :type :string-column :display-func h871-pf-v03-rc-col-note :initial-width 34)))
      (sd-display-error "H871 Part Note: Could not create right-click action table.")
      (return-from h871-pf-v03-rc-open-browser nil))
    (sd-browser-set-active-table *h871-pf-v03-rc-browser* :table-name "h871-pf-v03-rc-table")
    (sd-browser-exec-cmd *h871-pf-v03-rc-browser* :set-table-mode)
    (sd-show-graphical-browser *h871-pf-v03-rc-browser*)
    (let ((root (sd-get-browsernode-struct *h871-pf-v03-rc-tree* :root)))
      (when root (sd-browser-exec-cmd *h871-pf-v03-rc-browser* :change-table-root root t)))
    t)))

(defun h871-pf-v03-tab-changed (page-name)
  (funcall *h871-pf-v03-rc-original-tab-callback* page-name)
  (when (h871-pf-v03-page-by-name page-name) (h871-pf-v03-rc-open-browser)))
(defun h871-pf-v03-refresh-page (entry parts)
  (let ((result (funcall *h871-pf-v03-rc-original-refresh-page* entry parts)))
    (when result (h871-pf-v03-rc-open-browser))
    result))
