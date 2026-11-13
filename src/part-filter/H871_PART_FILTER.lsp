;; ============================================================
;; H871 PART FILTER - Density Instance/Base exact match
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Scans Parts recursively below a selected Assembly.
;; A match requires exact Density Instance AND Density Base.
;;
;; Matching objects are selected in the native Structure Browser
;; ("parcel-gbrowser") using :SET-OBJECT-SELECTION.
;; This is intended to leave the Parts selected in the browser
;; so the user can continue with standard commands.
;;
;; Verification: static source review only; test in Creo 18.1.
;; ============================================================

(in-package :oli)

(defvar *h871-pf-requested-instance* nil)
(defvar *h871-pf-requested-base* nil)

(defun h871-pf-name (obj)
  (or (sd-inq-obj-basename obj) "<NO NAME>"))

(defun h871-pf-path (obj)
  (or (sd-inq-obj-pathname obj) "<NO PATH>"))

(defun h871-pf-density-pair-match
       (part requested-instance requested-base)
  (let ((actual-instance
          (sd-inq-part-density part :instance))
        (actual-base
          (sd-inq-part-density part :contents)))
    (and actual-instance
         actual-base
         (= actual-instance requested-instance)
         (= actual-base requested-base))))

;; ------------------------------------------------------------
;; Collect exact matches from the model object tree
;; ------------------------------------------------------------

(defun h871-pf-collect
       (obj matches requested-instance requested-base)
  (when (sd-inq-part-p obj)
    (when
      (h871-pf-density-pair-match
        obj requested-instance requested-base)
      (push obj matches)))

  (dolist (child (sd-inq-obj-children obj))
    (setf matches
      (h871-pf-collect
        child matches requested-instance requested-base)))

  matches)

;; ------------------------------------------------------------
;; Find a Structure Browser node by the model object's path
;; ------------------------------------------------------------

(defun h871-pf-find-browser-node (browser-name parent-node target-path)
  (when parent-node
    (if (equal (BrowserNode-objPath parent-node) target-path)
        parent-node
      (let ((children
              (sd-query-browser browser-name :get-children parent-node))
            (found nil))
        (dolist (child children)
          (unless found
            (setf found
              (h871-pf-find-browser-node
                browser-name child target-path))))
        found))))

(defun h871-pf-select-in-structure-browser (matches)
  (let* ((browser-name "parcel-gbrowser")
         (root-node
           (sd-query-browser browser-name :get-graphics-root))
         (selected-count 0)
         (not-visible-count 0))

    (if (null root-node)
        (values 0 (length matches))
      (progn
        ;; Expand the browser tree so matching descendants can be selected.
        (sd-browser-exec-cmd
          browser-name :expand-tree 0 root-node)

        ;; Start with a clean selection list.
        (sd-browser-exec-cmd browser-name :clear-select-list)

        (dolist (part matches)
          (let* ((path (h871-pf-path part))
                 (node
                   (h871-pf-find-browser-node
                     browser-name root-node path)))
            (if node
                (when
                  (sd-browser-exec-cmd
                    browser-name :set-object-selection node t)
                  (incf selected-count))
              (incf not-visible-count))))

        (values selected-count not-visible-count)))))

;; ------------------------------------------------------------
;; Report
;; ------------------------------------------------------------

(defun h871-pf-write-report
       (assembly matches requested-instance requested-base
        selected-count not-visible-count)
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
      (format s "Assembly: ~A~%" (h871-pf-path assembly))
      (format s "Requested Density Instance: ~A~%" requested-instance)
      (format s "Requested Density Base: ~A~%" requested-base)
      (format s "Match rule: both values must match exactly.~%")
      (dolist (part matches)
        (format s "~%----------------------------------------~%")
        (format s "PART: ~A~%" (h871-pf-name part))
        (format s "PATH: ~A~%" (h871-pf-path part))
        (format s "DENSITY INSTANCE: ~A~%"
          (sd-inq-part-density part :instance))
        (format s "DENSITY BASE: ~A~%"
          (sd-inq-part-density part :contents)))
      (format s "~%========================================~%")
      (format s "Matching Parts: ~A~%" (length matches))
      (format s "Selected in Structure Browser: ~A~%" selected-count)
      (format s "Not found/visible in Structure Browser: ~A~%"
        not-visible-count))
    report))

;; ------------------------------------------------------------
;; Main action
;; ------------------------------------------------------------

(defun h871-pf-run (assembly requested-instance requested-base)
  (let* ((matches
           (h871-pf-collect
             assembly nil requested-instance requested-base))
         (selected-count 0)
         (not-visible-count 0)
         (report nil))

    (multiple-value-setq (selected-count not-visible-count)
      (h871-pf-select-in-structure-browser matches))

    (setf report
      (h871-pf-write-report
        assembly matches requested-instance requested-base
        selected-count not-visible-count))

    (cond
      ((zerop (length matches))
       (display
         (format nil
           "No Parts matched Density Instance ~A and Density Base ~A.~%Please verify the Density values in Part Properties.~%Report: ~A"
           requested-instance requested-base (namestring report))))
      ((zerop selected-count)
       (display
         (format nil
           "Found ~A matching Parts, but none could be selected in the Structure Browser.~%Check that the Structure Browser is open and showing the Assembly branch.~%Report: ~A"
           (length matches) (namestring report))))
      (t
       (display
         (format nil
           "H871 Part Filter completed.~%Matching Parts: ~A~%Selected in Structure Browser: ~A~%Not visible/selectable: ~A~%You can now use the selected items with Creo commands such as Add to Drawlist.~%Report: ~A"
           (length matches) selected-count not-visible-count
           (namestring report)))))

    matches))

;; ------------------------------------------------------------
;; Dialog
;; ------------------------------------------------------------

(sd-defdialog 'h871_part_filter
  :dialog-title "H871 - PART FILTER"
  :variables
  '(
    ("ASSEMBLY")
    (ASSEMBLY
      :value-type :assembly
      :title "Select Assembly"
      :prompt-text "Select assembly to scan.")

    ("DENSITY - EXACT MATCH")
    (DENSITY_INSTANCE
      :value-type :number
      :initial-value 1.0
      :title "Density Instance")

    (DENSITY_BASE
      :value-type :number
      :initial-value 304.0
      :title "Density Base")
  )
  :ok-action
  '(h871-pf-run
      assembly
      density_instance
      density_base)
)

;; LOAD:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER.lsp")
;; COMMAND:
;; H871_PART_FILTER
