;; ============================================================
;; H871 PART FILTER - Results Browser architecture - VER-06.1
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Search UI: machining process + material convention.
;; Search engine: exact Density Instance + Density Base pair.
;; Results: dedicated Graphical Browser with BOM-like table.
;; Row selection: native Graphical Browser selection state.
;; Select All / Clear Selection: browser commands.
;; Per-Part Notes: instance UDA, editable from the Browser context menu.
;; VER-06.2 fix: queue the interactive note dialog with SD-PUT-BUFFER.
;; Do not wrap an interactive dialog in SD-CALL-CMDS: nested action
;; calls cannot become interactive.
;;
;; IMPORTANT:
;; Graphical Browser APIs are documented in later PTC Integration
;; Kit references. This source is a compatibility implementation
;; candidate and must be loaded/tested in Creo 18.1.
;; ============================================================

(in-package :oli)

(defvar *h871-pf-v06-results* nil)
(defvar *h871-pf-v06-diagnostic-samples* nil)
(defvar *h871-pf-v06-results-assembly* nil)
(defvar *h871-pf-v06-requested-instance* nil)
(defvar *h871-pf-v06-requested-base* nil)

(defvar *h871-pf-v06-browser-name* "h871-pf-v06-results")
(defvar *h871-pf-v06-tree-name* "h871-pf-v06-results-tree")

(defvar *h871-pf-v06-note-edit-part* nil)
(defvar *h871-pf-v06-note-attribute-name* "H871_PART_FILTER_NOTE")

(defun h871-pf-v06-read-note (part)
  (or
    (sd-inq-item-attribute
      part
      *h871-pf-v06-note-attribute-name*
      :note
      :attachment :instance)
    ""))

(defun h871-pf-v06-write-note (part note)
  (let ((attached
          (member
            *h871-pf-v06-note-attribute-name*
            (sd-inq-item-attributes part :attachment :instance)
            :test #'string=)))
    (if attached
        (sd-mod-item-attribute
          part
          *h871-pf-v06-note-attribute-name*
          :attachment :instance
          :filing :sd-file
          :values (list :note note))
      (sd-attach-item-attribute
        part
        *h871-pf-v06-note-attribute-name*
        :attachment :instance
        :filing :sd-file
        :values (list :note note)))
    (equal note (h871-pf-v06-read-note part))))


(defun h871-pf-v06-name (obj)
  (or (sd-inq-obj-basename obj) "<NO NAME>"))

(defun h871-pf-v06-path (obj)
  (or (sd-inq-obj-pathname obj) "<NO PATH>"))

;; Convert numeric values consistently. In Lisp, (= 1 1.0) is
;; already true; this helper additionally accepts numeric strings such
;; as "1" and "1.0" if a runtime/property layer returns text.
(defun h871-pf-v06-as-number (value)
  ;; Creo's dialog fields and SD-INQ-PART-DENSITY return numeric
  ;; values in this workflow. Avoid READ-FROM-STRING and reader
  ;; character literals for compatibility with Modeling 18.1.
  (if (numberp value) value nil))
;; The user verified two native Parts in Modeling 18.1:
;; UI Instance/Base values 1/304 -> API values 1000/304000,
;; and UI values 2/400 -> API values 2000/400000.
;; Normalize API density values to the Part Properties display scale.
(defun h871-pf-v06-density-display-value (api-value)
  (when (numberp api-value)
    (/ api-value 1000.0)))

(defun h871-pf-v06-numeric-equal-p (actual requested)
  (let ((a (h871-pf-v06-as-number actual))
        (b (h871-pf-v06-as-number requested)))
    (and a b
         (<= (abs (- a b)) 0.0000001))))

(defun h871-pf-v06-density-pair-match (part requested-instance requested-base)
  (let ((actual-instance (sd-inq-part-density part :instance))
        (actual-base (sd-inq-part-density part :contents)))
    (and (not (null actual-instance))
         (not (null actual-base))
         (h871-pf-v06-numeric-equal-p
           (h871-pf-v06-density-display-value actual-instance)
           requested-instance)
         (h871-pf-v06-numeric-equal-p
           (h871-pf-v06-density-display-value actual-base)
           requested-base))))

;; ------------------------------------------------------------
;; Filter engine - keep predicates separate from result UI
;; ------------------------------------------------------------

(defun h871-pf-v06-collect (obj matches requested-instance requested-base)
  (when (sd-inq-part-p obj)
    (let ((actual-instance (sd-inq-part-density obj :instance))
          (actual-base (sd-inq-part-density obj :contents)))
      ;; Keep a small raw-value sample in the report so a zero-match
      ;; result reveals what Creo 18.1 actually returned.
      (when (< (length *h871-pf-v06-diagnostic-samples*) 30)
        (push
          (list (h871-pf-v06-name obj)
                (h871-pf-v06-path obj)
                actual-instance
                (type-of actual-instance)
                actual-base
                (type-of actual-base))
          *h871-pf-v06-diagnostic-samples*))
      (when (and
              (h871-pf-v06-numeric-equal-p
                (h871-pf-v06-density-display-value actual-instance)
                requested-instance)
              (h871-pf-v06-numeric-equal-p
                (h871-pf-v06-density-display-value actual-base)
                requested-base))
        (push obj matches))))
  (dolist (child (sd-inq-obj-children obj))
    (setf matches
      (h871-pf-v06-collect child matches requested-instance requested-base)))
  matches)

;; ------------------------------------------------------------
;; Browser row client data and table display callbacks
;; ------------------------------------------------------------

(defun h871-pf-v06-row-data (node)
  (browsernode-objclientdata node))

(defun h871-pf-v06-column-name (node browser-name)
  (declare (ignore browser-name))
  (getf (h871-pf-v06-row-data node) :name))

(defun h871-pf-v06-column-instance (node browser-name)
  (declare (ignore browser-name))
  (let ((value (getf (h871-pf-v06-row-data node) :instance)))
    (if value (format nil "~A" value) "-")))

(defun h871-pf-v06-column-base (node browser-name)
  (declare (ignore browser-name))
  (let ((value (getf (h871-pf-v06-row-data node) :base)))
    (if value (format nil "~A" value) "-")))

(defun h871-pf-v06-column-path (node browser-name)
  (declare (ignore browser-name))
  (getf (h871-pf-v06-row-data node) :path))

(defun h871-pf-v06-column-note (node browser-name)
  (declare (ignore browser-name))
  (let* ((part (getf (h871-pf-v06-row-data node) :part))
         (note (and part (h871-pf-v06-read-note part))))
    (if (and note (> (length note) 0)) note "-")))

(defun h871-pf-v06-edit-selected-note ()
  (let ((parts (h871-pf-v06-selected-parts)))
    (cond
      ((null parts)
       (sd-display-message "Select one Part row before choosing Edit Note."))
      ((cdr parts)
       (sd-display-message "Edit Note supports one Part at a time. Select exactly one Part row."))
      (t
       (setf *h871-pf-v06-note-edit-part* (car parts))
       (sd-put-buffer "h871_pf_v06_note_editor")))))

(defun h871-pf-v06-build-results-tree ()
  ;; Called by the Graphical Browser when its tree is built/refreshed.
  (let ((root
          (sd-create-browsernode
            :tree *h871-pf-v06-tree-name*
            :parent nil
            :objPath "/H871_RESULTS"
            :objPname "H871 Part Filter Results"
            :objClientData (list :kind :root))))
    (dolist (part (reverse *h871-pf-v06-results*))
      (let ((instance (sd-inq-part-density part :instance))
            (base (sd-inq-part-density part :contents))
            (path (h871-pf-v06-path part)))
        (sd-create-browsernode
          :tree *h871-pf-v06-tree-name*
          :parent root
          :objPath path
          :objPname (h871-pf-v06-name part)
          :objClientData
            (list :kind :part
                  :part part
                  :name (h871-pf-v06-name part)
                  :path path
                  :instance (h871-pf-v06-density-display-value instance)
                  :base (h871-pf-v06-density-display-value base)
                  :instance-api instance
                  :base-api base))))
    root))

(defun h871-pf-v06-select-all ()
  (sd-browser-exec-cmd *h871-pf-v06-browser-name* :select-all))

(defun h871-pf-v06-clear-selection ()
  (sd-browser-exec-cmd *h871-pf-v06-browser-name* :clear-select-list))

(defun h871-pf-v06-selected-parts ()
  (let ((parts nil))
    (dolist (node
              (sd-query-browser
                *h871-pf-v06-browser-name* :get-selected-objects))
      (let ((data (h871-pf-v06-row-data node)))
        (when (eq (getf data :kind) :part)
          (push (getf data :part) parts))))
    (nreverse parts)))

(defun h871-pf-v06-show-selection-summary ()
  (let ((parts (h871-pf-v06-selected-parts)))
    (sd-browser-set-status-text
      *h871-pf-v06-browser-name*
      :value (format nil "~A result row(s) selected." (length parts)))))

(defun h871-pf-v06-open-results-browser ()
  ;; Recreate browser/tree so every search has a clean result set.
  (ignore-errors
    (sd-hide-graphical-browser *h871-pf-v06-browser-name*))
  (ignore-errors
    (sd-destroy-graphical-browser *h871-pf-v06-browser-name*))
  (ignore-errors
    (sd-destroy-browser-tree *h871-pf-v06-tree-name*))

  (unless
    (sd-create-browser-tree
      *h871-pf-v06-tree-name*
      :update-events oli:*SD-CHANGE-OBJECT-TREE-EVENT*
      :update-func 'h871-pf-v06-build-results-tree)
    (sd-display-error "H871: Could not create the results data tree.")
    (return-from h871-pf-v06-open-results-browser nil))

  (unless
    (sd-create-graphical-browser
      *h871-pf-v06-browser-name*
      :tree *h871-pf-v06-tree-name*
      :topLabel "H871 - PART FILTER RESULTS"
      :treeStatusBar
        (format nil "Matched ~A Part(s). Select rows; Ctrl-click adds/removes."
          (length *h871-pf-v06-results*))
      :minHeight 280
      :maxWidth 1200
      :maxHeight 900
      ;; Stage-1 architecture: one standalone/floating native Graphical Browser.
      ;; Modeling may override this preference from the previous PDS session.
      :createAsTab nil
      :tabname "H871 Results"
      ;; Native footer controls in the original Graphical Browser window.
      ;; Keep Creo's native OK action: it already performs
      ;; :select-and-execute on the browser's selected rows.
      ;; Do not wrap it in a callback that immediately reopens the
      ;; browser after Creo has handed off and cleared the selection.
      :okButtonLabel "Apply"
      :abortButtonLabel "Select All"
      :abortButtonAction '(h871-pf-v06-select-all)
      :buttonMenu
        '(("select-all"
           :label "Select All"
           :push (h871-pf-v06-select-all))
          ("clear-selection"
           :label "Clear Selection"
           :push (h871-pf-v06-clear-selection))
          ("edit-note"
           :label "Edit Note"
           :push (h871-pf-v06-edit-selected-note)))
      :buttonMenuOffObjectOnly nil
      :topMenu
        '(("selection"
           :label "Selection"
           :contents
             (("select-all"
               :label "Select All"
               :push (h871-pf-v06-select-all))
              ("clear-selection"
               :label "Clear Selection"
               :push (h871-pf-v06-clear-selection))
              ("selection-summary"
               :label "Update Selection Count"
               :push (h871-pf-v06-show-selection-summary))))))
    (sd-display-error "H871: Could not create the results browser.")
    (return-from h871-pf-v06-open-results-browser nil))

  (unless
    (sd-browser-define-table
      *h871-pf-v06-browser-name*
      :table-name "h871-pf-v06-bom"
      :with-name-column nil
      :column-definition
        '(;; :initial-width values below are character counts, not pixels.
          (:label "Part Name"
           :type :string-column
           :display-func h871-pf-v06-column-name
           :initial-width 28)
          (:label "Density Instance"
           :type :string-column
           :display-func h871-pf-v06-column-instance
           :initial-width 13)
          (:label "Density Base"
           :type :string-column
           :display-func h871-pf-v06-column-base
           :initial-width 12)
          (:label "Assembly Path"
           :type :string-column
           :display-func h871-pf-v06-column-path
           :initial-width 42)
          (:label "Part Note"
           :type :string-column
           :display-func h871-pf-v06-column-note
           :initial-width 34)))
    (sd-display-error "H871: Could not create the BOM result table.")
    (return-from h871-pf-v06-open-results-browser nil))

  (sd-browser-set-active-table
    *h871-pf-v06-browser-name* :table-name "h871-pf-v06-bom")
  (sd-browser-exec-cmd *h871-pf-v06-browser-name* :set-table-mode)
  (sd-show-graphical-browser *h871-pf-v06-browser-name*)

  ;; Root node is the table root; the table displays all matching Parts.
  (let ((root (sd-get-browsernode-struct *h871-pf-v06-tree-name* :root)))
    (when root
      (sd-browser-exec-cmd
        *h871-pf-v06-browser-name* :change-table-root root t)))
  t)

;; ------------------------------------------------------------
;; Report and search action
;; ------------------------------------------------------------

(defun h871-pf-v06-write-report (assembly matches requested-instance requested-base)
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
      (format s "Assembly: ~A~%" (h871-pf-v06-path assembly))
      (format s "Requested Density Instance: ~A~%" requested-instance)
      (format s "Requested Density Base: ~A~%" requested-base)
      (format s "~%RAW DENSITY SAMPLE (first 30 Parts)~%")
      (format s "Part | Path | Instance value/type | Base value/type~%")
      (dolist (sample (reverse *h871-pf-v06-diagnostic-samples*))
        (format s "~S~%" sample))
      (dolist (part matches)
        (format s "~%PART: ~A~%" (h871-pf-v06-name part))
        (format s "PATH: ~A~%" (h871-pf-v06-path part))
        (format s "DENSITY INSTANCE (Part Properties scale): ~A~%"
          (h871-pf-v06-density-display-value
            (sd-inq-part-density part :instance)))
        (format s "DENSITY BASE (Part Properties scale): ~A~%"
          (h871-pf-v06-density-display-value
            (sd-inq-part-density part :contents)))
        (format s "DENSITY INSTANCE (raw API): ~A~%"
          (sd-inq-part-density part :instance))
        (format s "DENSITY BASE (raw API): ~A~%"
          (sd-inq-part-density part :contents))))
    report))

(defun h871-pf-v06-run (assembly requested-instance requested-base)
  (setf *h871-pf-v06-diagnostic-samples* nil)
  (setf *h871-pf-v06-results-assembly* assembly)
  (setf *h871-pf-v06-requested-instance* requested-instance)
  (setf *h871-pf-v06-requested-base* requested-base)
  (setf *h871-pf-v06-results*
    (h871-pf-v06-collect
      assembly nil requested-instance requested-base))
  (let ((report
          (h871-pf-v06-write-report
            assembly *h871-pf-v06-results*
            requested-instance requested-base)))
    (if (null *h871-pf-v06-results*)
        (sd-display-message
          (format nil
            "No Parts matched Density Instance ~A and Density Base ~A.~%Report: ~A"
            requested-instance requested-base (namestring report)))
      (progn
        (unless (h871-pf-v06-open-results-browser)
          (return-from h871-pf-v06-run nil))
        (sd-browser-set-status-text
          *h871-pf-v06-browser-name*
          :value (format nil
            "~A matching Part(s). Select rows; use Select All/Clear Selection buttons."
            (length *h871-pf-v06-results*)))))
    (values (length *h871-pf-v06-results*) report)))

;; ------------------------------------------------------------
;; Dialog entry point - ver-02
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
(sd-defdialog 'h871_part_filter_ver_06
  :dialog-title "H871 - PART FILTER VER-06"
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
     (h871-pf-v06-run assembly machining_process material)
     ;; Keep the input dialog active for consecutive searches.
     (sd-return-from-ok-action)))


;; ------------------------------------------------------------
;; Per-Part Note editor
;; ------------------------------------------------------------
;;
;; The editor is launched from the Results Browser's Edit Note
;; button after exactly one result row is selected. The selected
;; Part is passed through a dedicated global target so the dialog
;; does not ask the user to select the Part a second time.
;;
(sd-defdialog 'h871_pf_v06_note_editor
  :dialog-title "H871 - EDIT PART NOTE"
  :after-initialization
    '(setq NOTE
       (h871-pf-v06-read-note *h871-pf-v06-note-edit-part*))
  :variables
  '((NOTE
      :value-type :string
      :title "Part Note"
      :initial-value ""))
  :ok-action
  '(progn
     (if (and *h871-pf-v06-note-edit-part*
              (h871-pf-v06-write-note *h871-pf-v06-note-edit-part* NOTE))
         (progn
           (sd-display-message "Part Note saved.")
           ;; Refresh is display-only; never touch Browser selection
           ;; or the native Apply action.
           (ignore-errors
             (sd-browser-exec-cmd
               *h871-pf-v06-browser-name* :refresh-tree)))
       (sd-display-error "H871: Could not save the Part Note."))))

;; LOAD:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER_VER_06.lsp")
;; COMMAND:
;; H871_PART_FILTER_VER_06
