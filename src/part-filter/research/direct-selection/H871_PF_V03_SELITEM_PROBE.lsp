;; ============================================================================
;; H871 PART FILTER - DIRECT SELECTION RESEARCH
;; Stage 1: SEL_ITEM handle probe (NON-MUTATING)
;; Target: Creo Elements/Direct Modeling 18.1
;;
;; Load this file AFTER H871_PART_FILTER_VER_03.lsp.
;; In the active VER-03 Results tab, select one or more rows, then run:
;;   H871_PF_V03_SELITEM_PROBE
;;
;; This probe reads the active UICT table selection and records:
;; - the type of each hidden :part-object value;
;; - whether SD-INQ-PART-P accepts that value;
;; - its object pathname;
;; - the result of converting that pathname back with SD-PATHNAME-TO-OBJ.
;;
;; It DOES NOT create BrowserNodes, open a browser, change model geometry,
;; change Modeling's active selection, or replace the VER-03 Apply Bridge.
;;
;; SEL_ITEM-P is deliberately NOT used. A previous Modeling 18.1 test
;; reported it as undefined, so this probe relies on the existing, already
;; working inquiry functions and TYPE-OF instead.
;; ============================================================================

(in-package :oli)

(defun h871-pf-v03-probe-trace-file ()
  (merge-pathnames
    "H871_PF_V03_SELITEM_PROBE.txt"
    (user-homedir-pathname)))

(defun h871-pf-v03-probe-run ()
  (let* ((page-name *h871-pf-v03-current-page*)
         (entry (and (stringp page-name)
                     (h871-pf-v03-page-by-name page-name)))
         (selection (and entry
                         (sd-get-display-table-selection
                           (getf entry :table))))
         (columns (if selection (cadr selection) nil))
         (parts (if columns (getf columns :part-object) nil))
         (trace-file (h871-pf-v03-probe-trace-file))
         (index 0))
    (with-open-file
      (stream trace-file
        :direction :output
        :if-exists :supersede
        :if-does-not-exist :create)
      (format stream "H871 VER-03 SEL_ITEM PROBE~%")
      (format stream "Page: ~S~%" page-name)
      (format stream "Table: ~S~%" (and entry (getf entry :table)))
      (format stream "Selection container type: ~S~%"
        (and selection (type-of selection)))
      (format stream "Columns container type: ~S~%"
        (and columns (type-of columns)))
      (format stream "Selected Part count: ~S~%"
        (if parts (length parts) 0))
      (terpri stream)
      (if (null parts)
          (format stream
            "RESULT: No selected Part rows. Select rows in the active Results tab and run the probe again.~%")
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
                          (sd-inq-obj-pathname roundtrip)))))
            (format stream "PART ~A~%" index)
            (format stream "  RAW TYPE-OF: ~S~%" (type-of part))
            (format stream "  SD-INQ-PART-P: ~S~%" part-p)
            (format stream "  PATHNAME: ~S~%" path)
            (format stream "  PATHNAME-TO-OBJ TYPE-OF: ~S~%"
              (and roundtrip (type-of roundtrip)))
            (format stream "  ROUNDTRIP SD-INQ-PART-P: ~S~%"
              roundtrip-part-p)
            (format stream "  ROUNDTRIP PATHNAME: ~S~%" roundtrip-path)
            (format stream "  PATH MATCH: ~S~%"
              (and (stringp path)
                   (stringp roundtrip-path)
                   (equal path roundtrip-path)))
            (terpri stream)))))
    (sd-display-message
      (format nil
        "H871 SEL_ITEM probe finished. Selected rows: ~A. Report: ~A"
        (if parts (length parts) 0)
        (namestring trace-file)))
    trace-file))

(sd-defdialog 'h871_pf_v03_selitem_probe
  :dialog-title "H871 - SEL_ITEM Probe"
  :dialog-control :sequential
  :variables '()
  :ok-action
    '(h871-pf-v03-probe-run))

;; Command: H871_PF_V03_SELITEM_PROBE
