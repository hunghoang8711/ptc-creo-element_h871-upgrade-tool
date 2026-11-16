;; ============================================================================
;; H871 ver-03 DIALOG GENERATOR SELECTION DIAGNOSTIC
;; Target: Creo Elements/Direct Modeling 18.1
;;
;; Purpose:
;;   Test whether a Dialog Generator :part selection variable initialized from
;;   the active UICT Results page's SEL_ITEM list can persistently highlight
;;   those Parts without displaying a second dialog window.
;;
;; Prerequisite:
;;   Load H871_PART_FILTER_VER_03.lsp first.
;;
;; Test:
;;   1. Select one or more rows in the active H871 Results page.
;;   2. Run H871_PF_V03_DG_SELECTION_DIAG in the Modeling command line.
;;   3. While the command is active, inspect the 3D viewport:
;;        - Are the requested Parts highlighted?
;;        - Is there any second dialog/browser window?
;;   4. Press Enter in the Modeling command line to finish the diagnostic.
;;   5. Inspect H871_PART_FILTER_VER_03_TRACE.txt.
;;
;; Important:
;;   - :persistent-highlight is documented to highlight Part values held by
;;     a Dialog Generator selection variable. This tests highlight feedback,
;;     not automatically the global Modeling selection list.
;;   - :without-show t suppresses the parallel dialog UI. The command is
;;     expected to remain active until accepted; if it does not, record that.
;;   - This file does not modify production Apply or any Results UI behavior.
;; ============================================================================

(in-package :oli)

(defvar *h871-pf-v03-dg-test-parts* nil)
(defvar *h871-pf-v03-dg-test-page* nil)

(defun h871-pf-v03-dg-selection-initial-parts ()
  (let* ((page-name *h871-pf-v03-current-page*)
         (entry (and (stringp page-name)
                     (h871-pf-v03-page-by-name page-name)))
         (selection (and entry
                         (sd-get-display-table-selection
                           (getf entry :table))))
         (columns (and selection (cadr selection)))
         (parts (and columns (getf columns :part-object))))
    (setf *h871-pf-v03-dg-test-page* page-name)
    (setf *h871-pf-v03-dg-test-parts* parts)
    (h871-pf-v03-trace "DG-SELECTION-DIAG/INITIAL-VALUE"
      (list page-name
            (and parts (length parts))
            (and parts (mapcar #'type-of parts))))
    parts))

(defun h871-pf-v03-dg-selection-after-init (parts)
  (h871-pf-v03-trace "DG-SELECTION-DIAG/AFTER-INITIALIZATION"
    (list *h871-pf-v03-dg-test-page*
          (and parts (length parts))
          (and parts (mapcar #'type-of parts))))
  (unless (and (listp parts) parts)
    (sd-display-message
      "H871 DG diagnostic: No selected Part rows were supplied. Cancel the command.")))

(defun h871-pf-v03-dg-selection-ok (parts)
  (h871-pf-v03-trace "DG-SELECTION-DIAG/OK-ACTION"
    (list *h871-pf-v03-dg-test-page*
          (and parts (length parts))
          (and parts (mapcar #'type-of parts))))
  (h871-pf-v03-trace "DG-SELECTION-DIAG/PART-CHECKS"
    (and parts (mapcar #'sd-inq-part-p parts)))
  (sd-display-message
    (format nil
      "H871 DG diagnostic finished. Dialog received ~A Part selection item(s). Check the trace. Viewport highlight must be checked while the command is active."
      (if parts (length parts) 0)))
  t)

(defun h871-pf-v03-dg-selection-cancel (parts)
  (h871-pf-v03-trace "DG-SELECTION-DIAG/CANCEL"
    (list *h871-pf-v03-dg-test-page*
          (and parts (length parts))))
  nil)

(sd-defdialog 'h871_pf_v03_dg_selection_diag
  :dialog-title "H871 DG Selection Diagnostic"
  :dialog-control :parallel
  :without-show t
  :top-prompt-text
    "H871 DG diagnostic active: inspect Part highlight in the 3D viewport, then press Enter to finish."
  :variables
    '((parts
        :value-type :part
        :multiple-items t
        :persistent-highlight t
        :modifies nil
        :initial-optional t
        :initial-value (h871-pf-v03-dg-selection-initial-parts)
        :title "Diagnostic Parts"))
  :after-initialization
    '(h871-pf-v03-dg-selection-after-init parts)
  :ok-action
    '(h871-pf-v03-dg-selection-ok parts)
  :cancel-action
    '(h871-pf-v03-dg-selection-cancel parts))

;; Modeling command:
;; H871_PF_V03_DG_SELECTION_DIAG
