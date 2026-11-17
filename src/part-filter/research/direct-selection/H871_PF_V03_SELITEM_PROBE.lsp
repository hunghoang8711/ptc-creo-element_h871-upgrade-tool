;; ============================================================================
;; H871 PART FILTER - DIRECT SELECTION RESEARCH
;; Stage 1: SEL_ITEM handle probe (NON-MUTATING)
;; Target: Creo Elements/Direct Modeling 18.1
;;
;; Load this file AFTER H871_PART_FILTER_VER_03.lsp.
;; Select one or more rows in a VER-03 Results tab, then run:
;;   H871_PF_V03_SELITEM_PROBE
;;
;; This revision does not depend on *h871-pf-v03-current-page*.
;; It scans the registered VER-03 pages and reports every page that has
;; selected rows. This avoids assuming that the current-page variable is
;; bound in the callback's runtime context.
;;
;; It DOES NOT create BrowserNodes, open a browser, change model geometry,
;; change Modeling's active selection, or replace the VER-03 Apply Bridge.
;;
;; SEL_ITEM-P is deliberately NOT used. A previous Modeling 18.1 test
;; reported it as undefined, so this probe relies on TYPE-OF and the
;; existing Part/path inquiry functions.
;; ============================================================================

(in-package :oli)

(defun h871-pf-v03-probe-trace-file ()
  (merge-pathnames
    "H871_PF_V03_SELITEM_PROBE.txt"
    (user-homedir-pathname)))

(defun h871-pf-v03-probe-page (entry stream total)
  (let* ((page-name (getf entry :page))
         (table-name (getf entry :table))
         (selection (and (stringp table-name)
                         (sd-get-display-table-selection table-name)))
         (columns (if selection (cadr selection) nil))
         (parts (if columns (getf columns :part-object) nil))
         (index 0))
    (when parts
      (incf (car total) (length parts))
      (format stream "PAGE: ~S~%" page-name)
      (format stream "  Table: ~S~%" table-name)
      (format stream "  Selection container type: ~S~%"
        (type-of selection))
      (format stream "  Columns container type: ~S~%"
        (and columns (type-of columns)))
      (format stream "  Selected Part count: ~S~%"
        (length parts))
      (dolist (part parts)
        (incf index)
        (let* ((path (ignore-errors (sd-inq-obj-pathname part)))
               (part-p (ignore-errors (sd-inq-part-p part)))
               (roundtrip
                 (and (stringp path)
                      (ignore-errors (sd-pathname-to-obj path))))
               (roundtrip-part-p
                 (and roundtrip
                      (ignore-errors (sd-inq-part-p roundtrip))))
               (roundtrip-path
                 (and roundtrip
                      (ignore-errors
                        (sd-inq-obj-pathname roundtrip))))
               (path-match
                 (and (stringp path)
                      (stringp roundtrip-path)
                      (equal path roundtrip-path))))
          (format stream "  PART ~A~%" index)
          (format stream "    RAW TYPE-OF: ~S~%" (type-of part))
          (format stream "    SD-INQ-PART-P: ~S~%" part-p)
          (format stream "    PATHNAME: ~S~%" path)
          (format stream "    PATHNAME-TO-OBJ TYPE-OF: ~S~%"
            (and roundtrip (type-of roundtrip)))
          (format stream "    ROUNDTRIP SD-INQ-PART-P: ~S~%"
            roundtrip-part-p)
          (format stream "    ROUNDTRIP PATHNAME: ~S~%" roundtrip-path)
          (format stream "    PATH MATCH: ~S~%" path-match)))
      (terpri stream))))

(defun h871-pf-v03-probe-run ()
  (let* ((pages-bound-p (boundp '*h871-pf-v03-pages*))
         (pages (and pages-bound-p *h871-pf-v03-pages*))
         (current-page-bound-p (boundp '*h871-pf-v03-current-page*))
         (current-page
           (and current-page-bound-p *h871-pf-v03-current-page*))
         (trace-file (h871-pf-v03-probe-trace-file))
         (total (list 0)))
    (with-open-file
      (stream trace-file
        :direction :output
        :if-exists :supersede
        :if-does-not-exist :create)
      (format stream "H871 VER-03 SEL_ITEM PROBE~%")
      (format stream "Current page variable bound: ~S~%"
        current-page-bound-p)
      (format stream "Current page value: ~S~%" current-page)
      (format stream "Page registry bound: ~S~%" pages-bound-p)
      (format stream "Registered page count: ~S~%"
        (if pages (length pages) 0))
      (terpri stream)
      (cond
        ((not pages-bound-p)
          (format stream
            "RESULT: VER-03 page registry is unbound. Confirm VER-03 was loaded in this Modeling session before the probe.~%"))
        ((null pages)
          (format stream
            "RESULT: No registered Results pages. Run a Part Filter search first, then select rows and retry.~%"))
        (t
          (dolist (entry pages)
            (h871-pf-v03-probe-page entry stream total))
          (if (= (car total) 0)
              (format stream
                "RESULT: No selected Part rows found on any registered Results page. Select rows and retry.~%")
            (format stream
              "RESULT: Probe inspected ~A selected Part row(s).~%"
              (car total))))))
    (sd-display-message
      (format nil
        "H871 SEL_ITEM probe finished. Selected rows inspected: ~A. Report: ~A"
        (car total)
        (namestring trace-file)))
    trace-file))

(sd-defdialog 'h871_pf_v03_selitem_probe
  :dialog-title "H871 - SEL_ITEM Probe"
  :dialog-control :sequential
  :variables '()
  :ok-action
    '(h871-pf-v03-probe-run))

;; Command: H871_PF_V03_SELITEM_PROBE
