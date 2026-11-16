;; ============================================================================
;; H871 ver-03 GET_SELECTION / NAMED-PART DIAGNOSTIC
;; Target: Creo Elements/Direct Modeling 18.1
;;
;; Purpose:
;;   Test whether the documented GET_SELECTION interrupt action can resolve a
;;   known Part pathname through the native SELECT :PART name-selection path.
;;   This is an isolated, non-model-modifying diagnostic.
;;
;; Prerequisite:
;;   Load H871_PART_FILTER_VER_03.lsp first.
;;
;; Test:
;;   1. Select exactly one row in the active H871 Results page.
;;   2. Load this file.
;;   3. Run H871_PF_V03_GET_SELECTION_DIAG.
;;   4. Observe the viewport while the command is active and after it finishes.
;;   5. Inspect H871_PART_FILTER_VER_03_TRACE.txt for GET-SELECTION-DIAG/.
;;
;; Important:
;;   - This does not call the Graphical Browser.
;;   - It does not change geometry or production Apply.
;;   - The command reference documents SELECT :PART name selection and
;;     GET_SELECTION :select as the programmatic SELECT subaction entry point.
;;   - A returned SEL_ITEM is not by itself proof of global Modeling selection.
;; ============================================================================

(in-package :oli)

(defvar *h871-pf-v03-get-selection-result* nil)
(defvar *h871-pf-v03-get-selection-path* nil)

(defun h871-pf-v03-get-selection-run (parts)
  (let* ((part (car parts))
         (path (and part (h871-pf-v03-path part)))
         (result nil)
         (status nil))
    (setf *h871-pf-v03-get-selection-path* path)
    (setf *h871-pf-v03-get-selection-result* nil)
    (h871-pf-v03-trace "GET-SELECTION-DIAG/BEGIN"
      (list (length parts) path (and part (type-of part))))
    (when (or (null part) (not (stringp path)))
      (sd-display-message
        "H871 GET_SELECTION diagnostic: Select exactly one valid Part row first.")
      (return-from h871-pf-v03-get-selection-run nil))
    (setf status
      (sd-call-cmds
        (get_selection
          :focus-type *sd-part-seltype*
          :select :part path)
        :success
          (progn
            (setf result *sd-action-result*)
            (h871-pf-v03-trace
              "GET-SELECTION-DIAG/SUCCESS-CONTEXT"
              (list (type-of result)
                    (and (listp result) (length result))
                    (and result (mapcar #'type-of
                                  (if (listp result) result (list result))))))
            :success)
        :failure
          (progn
            (h871-pf-v03-trace
              "GET-SELECTION-DIAG/FAILURE"
              (sd-inq-error-obj :all))
            :failure)))
    (setf *h871-pf-v03-get-selection-result* result)
    (h871-pf-v03-trace "GET-SELECTION-DIAG/STATUS" status)
    (h871-pf-v03-trace "GET-SELECTION-DIAG/RESULT"
      (list (type-of result)
            (and result (listp result) (length result))
            (and result
                 (mapcar #'sd-inq-part-p
                   (if (listp result) result (list result))))
            (and result
                 (mapcar (lambda (item)
                           (ignore-errors (sd-inq-obj-pathname item)))
                   (if (listp result) result (list result))))))
    (sd-display-message
      (format nil
        "H871 GET_SELECTION diagnostic finished. Status: ~A. Result type: ~A. Check viewport and trace."
        status (if result (type-of result) "NIL")))
    status))

(defun h871-pf-v03-get-selection-initial-parts ()
  (let* ((page-name *h871-pf-v03-current-page*)
         (entry (and (stringp page-name)
                     (h871-pf-v03-page-by-name page-name)))
         (selection (and entry
                         (sd-get-display-table-selection
                           (getf entry :table))))
         (columns (and selection (cadr selection)))
         (parts (and columns (getf columns :part-object))))
    (h871-pf-v03-trace "GET-SELECTION-DIAG/INITIAL-PARTS"
      (list page-name (and parts (length parts))))
    parts))

(sd-defdialog 'h871_pf_v03_get_selection_diag
  :dialog-title "H871 GET_SELECTION Diagnostic"
  :dialog-control :parallel
  :without-show t
  :variables
    '((parts
        :value-type :part
        :multiple-items t
        :persistent-highlight t
        :modifies nil
        :initial-optional t
        :initial-value (h871-pf-v03-get-selection-initial-parts)
        :title "Diagnostic Parts"))
  :ok-action
    '(h871-pf-v03-get-selection-run parts))

;; Modeling command:
;; H871_PF_V03_GET_SELECTION_DIAG
