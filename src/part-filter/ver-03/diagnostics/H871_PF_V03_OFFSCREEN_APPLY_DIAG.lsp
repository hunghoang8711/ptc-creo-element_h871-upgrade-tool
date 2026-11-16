;; ============================================================================
;; H871 ver-03 OFFSCREEN APPLY DIAGNOSTIC
;; Target: Creo Elements/Direct Modeling 18.1
;;
;; Purpose:
;;   Isolate the hidden Graphical Browser visibility failure without changing
;;   the production ver-03 source or Results UI.
;;
;; Prerequisite:
;;   Load H871_PART_FILTER_VER_03.lsp first.
;;
;; Test:
;;   1. Select one or more rows in the active UICT Results tab.
;;   2. Do NOT press the production Apply button for this test.
;;   3. Run H871_PF_V03_OFFSCREEN_APPLY_DIAG in the Modeling command line.
;;   4. Inspect H871_PART_FILTER_VER_03_TRACE.txt.
;;   5. Check whether the corresponding Part(s) become selected in the viewport.
;;
;; The temporary Graphical Browser is shown at a large negative offset relative
;; to the Results shell. This is a diagnostic positioning technique, NOT a
;; documented hidden-window API. If the window is visible on-screen, close it
;; and stop; do not continue testing with a visible second window.
;;
;; This file does not alter the production Apply implementation.
;; ============================================================================

(in-package :oli)

(defun h871-pf-v03-offscreen-apply-diagnostic ()
  (let* ((page-name *h871-pf-v03-current-page*)
         (entry (and (stringp page-name)
                     (h871-pf-v03-page-by-name page-name)))
         (selection (and entry
                         (sd-get-display-table-selection
                           (getf entry :table))))
         (columns (and selection (cadr selection)))
         (parts (and columns (getf columns :part-object)))
         (tree-created nil)
         (browser-created nil)
         (shown nil)
         (handoff nil))
    (h871-pf-v03-trace "OFFSCREEN-DIAG/BEGIN"
      (list page-name (and parts (length parts))))
    (unless (and entry (listp parts) parts)
      (sd-display-message
        "H871 diagnostic: Select one or more result rows in the active tab first.")
      (return-from h871-pf-v03-offscreen-apply-diagnostic nil))

    (setf *h871-pf-v03-apply-parts* parts)
    (setf *h871-pf-v03-pending-apply-page* page-name)
    (setf *h871-pf-v03-apply-nodes* nil)

    (ignore-errors
      (sd-hide-graphical-browser *h871-pf-v03-apply-browser* :ignore-pin t))
    (ignore-errors
      (sd-destroy-graphical-browser *h871-pf-v03-apply-browser*))
    (ignore-errors
      (sd-destroy-browser-tree *h871-pf-v03-apply-tree*))

    (setf tree-created
      (sd-create-browser-tree
        *h871-pf-v03-apply-tree*
        :update-events oli:*SD-CHANGE-OBJECT-TREE-EVENT*
        :update-func 'h871-pf-v03-build-apply-tree))
    (h871-pf-v03-trace "OFFSCREEN-DIAG/TREE-CREATED" tree-created)
    (unless tree-created
      (sd-display-message
        "H871 diagnostic: Could not create the temporary browser tree.")
      (return-from h871-pf-v03-offscreen-apply-diagnostic nil))

    (setf browser-created
      (sd-create-graphical-browser
        *h871-pf-v03-apply-browser*
        :tree *h871-pf-v03-apply-tree*
        :topLabel "H871 - Offscreen Apply Diagnostic"
        :minHeight 120
        :maxWidth 480
        :maxHeight 220
        :okButtonLabel "Apply"))
    (h871-pf-v03-trace "OFFSCREEN-DIAG/BROWSER-CREATED" browser-created)
    (unless browser-created
      (sd-display-message
        "H871 diagnostic: Could not create the temporary Graphical Browser.")
      (return-from h871-pf-v03-offscreen-apply-diagnostic nil))

    (sd-browser-exec-cmd *h871-pf-v03-apply-browser* :set-table-mode)

    ;; PTC documents the same position format for Graphical Browser and
    ;; Display Table placement: (reference-widget attachment x-offset y-offset).
    ;; The large negative offset is deliberately used to keep the diagnostic
    ;; browser outside the visible desktop area.
    (setf shown
      (sd-show-graphical-browser
        *h871-pf-v03-apply-browser*
        :position
          (list *h871-pf-v03-shell* :topleft -10000 -10000)))
    (h871-pf-v03-trace "OFFSCREEN-DIAG/SHOW-RETURN" shown)
    (unless shown
      (sd-display-message
        "H871 diagnostic: Could not show the offscreen browser. See trace.")
      (ignore-errors
        (sd-hide-graphical-browser
          *h871-pf-v03-apply-browser* :ignore-pin t))
      (return-from h871-pf-v03-offscreen-apply-diagnostic nil))

    (let ((root
            (sd-get-browsernode-struct *h871-pf-v03-apply-tree* :root)))
      (h871-pf-v03-trace "OFFSCREEN-DIAG/ROOT-TYPE" (type-of root))
      (unless root
        (sd-display-message
          "H871 diagnostic: Browser root was not built.")
        (ignore-errors
          (sd-hide-graphical-browser
            *h871-pf-v03-apply-browser* :ignore-pin t))
        (return-from h871-pf-v03-offscreen-apply-diagnostic nil))
      (h871-pf-v03-trace "OFFSCREEN-DIAG/CHANGE-TABLE-ROOT"
        (sd-browser-exec-cmd
          *h871-pf-v03-apply-browser* :change-table-root root t)))

    (let ((displayed-count 0)
          (selected-count 0))
      (dolist (node-id *h871-pf-v03-apply-nodes*)
        (let* ((node
                 (sd-get-browsernode-struct
                   *h871-pf-v03-apply-tree* node-id))
               (displayed
                 (and node
                      (sd-query-browser
                        *h871-pf-v03-apply-browser*
                        :is-object-displayed node)))
               (selected
                 (and displayed
                      (sd-browser-exec-cmd
                        *h871-pf-v03-apply-browser*
                        :set-object-selection node t))))
          (when displayed (incf displayed-count))
          (when selected (incf selected-count))
          (h871-pf-v03-trace "OFFSCREEN-DIAG/NODE"
            (list node-id (type-of node) displayed selected))))
      (h871-pf-v03-trace "OFFSCREEN-DIAG/COUNTS"
        (list (length *h871-pf-v03-apply-nodes*)
              displayed-count selected-count))
      (if (and (= displayed-count (length parts))
               (= selected-count (length parts)))
          (setf handoff
            (sd-call-cmds
              (sd-browser-exec-cmd
                *h871-pf-v03-apply-browser* :select-and-execute)
              :success
                (progn
                  (h871-pf-v03-trace
                    "OFFSCREEN-DIAG/HANDOFF-SUCCESS-CONTEXT"
                    *sd-action-result*)
                  :success)
              :failure
                (progn
                  (h871-pf-v03-trace
                    "OFFSCREEN-DIAG/HANDOFF-ERROR"
                    (sd-inq-error-obj :all))
                  :error)))
        (setf handoff :not-all-nodes-displayed-or-selected))
      (h871-pf-v03-trace "OFFSCREEN-DIAG/HANDOFF-STATUS" handoff))

    (ignore-errors
      (sd-hide-graphical-browser
        *h871-pf-v03-apply-browser* :ignore-pin t))
    (h871-pf-v03-trace "OFFSCREEN-DIAG/END" handoff)
    (when (eq handoff :success)
      (h871-pf-v03-update-status page-name))
    handoff))

(sd-defdialog 'h871_pf_v03_offscreen_apply_diag
  :dialog-title "H871 Offscreen Apply Diagnostic"
  :dialog-control :sequential
  :variables '()
  :ok-action '(h871-pf-v03-offscreen-apply-diagnostic))

;; Modeling command:
;; H871_PF_V03_OFFSCREEN_APPLY_DIAG
