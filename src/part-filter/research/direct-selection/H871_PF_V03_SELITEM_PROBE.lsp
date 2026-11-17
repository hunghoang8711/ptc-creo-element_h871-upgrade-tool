;; ============================================================================
;; H871 PART FILTER - DIRECT SELECTION RESEARCH
;; Stage 1B: SEL_ITEM structure/API probe (NON-MUTATING)
;; Target: Creo Elements/Direct Modeling 18.1
;;
;; Load after VER-03 and run:
;;   H871_PF_V03_SELITEM_PROBE_V3
;;
;; V3 scans selected rows and tests the documented SEL_ITEM structure
;; accessors by resolving their symbols in :ELAN and :OLI. It does not
;; modify the model, active selection, Results UI, or Apply Bridge.
;; ============================================================================

(in-package :oli)

(defun h871-pf-v03-probe-v3-trace-file ()
  (merge-pathnames
    "H871_PF_V03_SELITEM_PROBE_V3.txt"
    (user-homedir-pathname)))

(defun h871-pf-v03-probe-v3-call (package-name function-name item)
  (let* ((package (find-package package-name))
         (symbol (and package (find-symbol function-name package)))
         (available (and symbol (fboundp symbol)))
         (value (and available
                     (ignore-errors
                       (funcall (symbol-function symbol) item)))))
    (list package-name
          (and symbol (symbol-name symbol))
          (and symbol (symbol-package symbol)
               (package-name (symbol-package symbol)))
          available
          value)))

(defun h871-pf-v03-probe-v3-page (entry stream total)
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
      (format stream "TABLE: ~S~%" table-name)
      (format stream "SELECTED COUNT: ~S~%" (length parts))
      (dolist (part parts)
        (incf index)
        (format stream "~%PART ~A~%" index)
        (format stream "  TYPE-OF: ~S~%" (type-of part))
        (format stream "  SEL_ITEM-P :ELAN: ~S~%"
          (h871-pf-v03-probe-v3-call :elan "SEL_ITEM-P" part))
        (format stream "  SEL_ITEM-TYPE :ELAN: ~S~%"
          (h871-pf-v03-probe-v3-call :elan "SEL_ITEM-TYPE" part))
        (format stream "  SEL_ITEM-P :OLI: ~S~%"
          (h871-pf-v03-probe-v3-call :oli "SEL_ITEM-P" part))
        (format stream "  SEL_ITEM-TYPE :OLI: ~S~%"
          (h871-pf-v03-probe-v3-call :oli "SEL_ITEM-TYPE" part))
        (format stream "  SD-INQ-PART-P: ~S~%"
          (ignore-errors (sd-inq-part-p part)))
        (format stream "  BASENAME: ~S~%"
          (ignore-errors (sd-inq-obj-basename part)))
        (format stream "  PATHNAME: ~S~%"
          (ignore-errors (sd-inq-obj-pathname part)))
        (format stream "  SYSID: ~S~%"
          (ignore-errors (sd-inq-obj-sysid part))))
      (terpri stream))))

(defun h871-pf-v03-probe-run-v3 ()
  (let* ((registry-bound-p (boundp '*h871-pf-v03-pages*))
         (pages (and registry-bound-p *h871-pf-v03-pages*))
         (trace-file (h871-pf-v03-probe-v3-trace-file))
         (total (list 0)))
    (with-open-file
      (stream trace-file
        :direction :output
        :if-exists :supersede
        :if-does-not-exist :create)
      (format stream "H871 VER-03 SEL_ITEM PROBE V3~%")
      (format stream "Registry bound: ~S~%" registry-bound-p)
      (format stream "Registered page count: ~S~%"
        (if pages (length pages) 0))
      (cond
        ((not registry-bound-p)
          (format stream "RESULT: Registry symbol unbound in :OLI.~%"))
        ((null pages)
          (format stream "RESULT: No Results pages registered.~%"))
        (t
          (dolist (entry pages)
            (h871-pf-v03-probe-v3-page entry stream total))
          (format stream "~%RESULT: Inspected ~A selected row(s).~%"
            (car total)))))
    (sd-display-message
      (format nil
        "H871 SEL_ITEM probe V3 finished. Rows inspected: ~A. Report: ~A"
        (car total) (namestring trace-file)))
    trace-file))

(sd-defdialog 'h871_pf_v03_selitem_probe_v3
  :dialog-title "H871 - SEL_ITEM Probe V3"
  :dialog-control :sequential
  :variables '()
  :ok-action
    '(h871-pf-v03-probe-run-v3))

;; Command: H871_PF_V03_SELITEM_PROBE_V3
