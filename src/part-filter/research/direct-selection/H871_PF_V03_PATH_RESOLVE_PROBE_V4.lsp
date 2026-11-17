;; ============================================================================
;; H871 PART FILTER - PATHNAME RESOLUTION PROBE V4 (NON-MUTATING)
;; Target: Creo Elements/Direct Modeling 18.1
;;
;; Purpose:
;; Read selected row path strings from the visible :assembly-path column,
;; resolve fresh SEL_ITEM handles with SD-PATHNAME-TO-OBJ, and test only
;; documented object inquiry functions on those freshly resolved handles.
;;
;; SAFETY:
;; - Does not call SEL_ITEM-P or SEL_ITEM-TYPE.
;; - Does not call inquiry functions on the old hidden :part-object handles.
;; - Does not modify geometry, selection, Results UI, or Apply Bridge.
;; - Uses the page/table name reported by the user's V1 probe.
;;
;; Load after VER-03. Select rows in Results page 1, then run:
;;   H871_PF_V03_PATH_RESOLVE_PROBE_V4
;;
;; Report:
;;   H871_PF_V03_PATH_RESOLVE_PROBE_V4.txt
;; ============================================================================

(in-package :oli)

(defun h871-pf-v03-path-v4-report-file ()
  (merge-pathnames
    "H871_PF_V03_PATH_RESOLVE_PROBE_V4.txt"
    (user-homedir-pathname)))

(defun h871-pf-v03-path-v4-run ()
  (let* ((table-name "H871-PF-V03-PAGE-1-DISPLAY-TABLE")
         (selection (sd-get-display-table-selection table-name))
         (columns (if selection (cadr selection) nil))
         (paths (if columns (getf columns :assembly-path) nil))
         (old-parts (if columns (getf columns :part-object) nil))
         (report-file (h871-pf-v03-path-v4-report-file))
         (index 0)
         (resolved-count 0)
         (part-count 0))
    (with-open-file
      (stream report-file
        :direction :output
        :if-exists :supersede
        :if-does-not-exist :create)
      (format stream "H871 VER-03 PATHNAME RESOLUTION PROBE V4~%")
      (format stream "Table: ~S~%" table-name)
      (format stream "Selection container: ~S~%"
        (and selection (type-of selection)))
      (format stream "Columns container: ~S~%"
        (and columns (type-of columns)))
      (format stream "Selected path count: ~S~%"
        (if paths (length paths) 0))
      (format stream "Stored SEL_ITEM count: ~S~%"
        (if old-parts (length old-parts) 0))
      (terpri stream)
      (cond
        ((null selection)
          (format stream "RESULT: Display Table returned no selection data.~%"))
        ((null paths)
          (format stream "RESULT: No selected rows or :assembly-path column unavailable.~%"))
        (t
          (dolist (path paths)
            (incf index)
            (format stream "ROW ~A~%" index)
            (format stream "  STORED PATH TYPE: ~S~%" (type-of path))
            (format stream "  STORED PATH: ~S~%" path)
            (if (stringp path)
                (let* ((fresh-item
                         (ignore-errors (sd-pathname-to-obj path)))
                       (fresh-type
                         (and fresh-item (type-of fresh-item)))
                       (fresh-part-p
                         (and fresh-item
                              (ignore-errors (sd-inq-part-p fresh-item))))
                       (fresh-basename
                         (and fresh-item
                              (ignore-errors
                                (sd-inq-obj-basename fresh-item))))
                       (fresh-path
                         (and fresh-item
                              (ignore-errors
                                (sd-inq-obj-pathname fresh-item)))))
                  (when fresh-item (incf resolved-count))
                  (when (eq fresh-part-p t) (incf part-count))
                  (format stream "  FRESH ITEM TYPE: ~S~%" fresh-type)
                  (format stream "  FRESH SD-INQ-PART-P: ~S~%" fresh-part-p)
                  (format stream "  FRESH BASENAME: ~S~%" fresh-basename)
                  (format stream "  FRESH PATHNAME: ~S~%" fresh-path)
                  (format stream "  PATH MATCH: ~S~%"
                    (and (stringp fresh-path) (equal path fresh-path))))
              (format stream "  SKIPPED: path is not a string.~%"))
            (terpri stream)))))
    (sd-display-message
      (format nil
        "H871 Path Resolve V4 finished. Paths: ~A; resolved: ~A; Parts: ~A. Report: ~A"
        (if paths (length paths) 0)
        resolved-count part-count (namestring report-file)))
    report-file))

(sd-defdialog 'h871_pf_v03_path_resolve_probe_v4
  :dialog-title "H871 - Pathname Resolution Probe V4"
  :dialog-control :sequential
  :variables '()
  :ok-action
    '(h871-pf-v03-path-v4-run))

;; Command: H871_PF_V03_PATH_RESOLVE_PROBE_V4
