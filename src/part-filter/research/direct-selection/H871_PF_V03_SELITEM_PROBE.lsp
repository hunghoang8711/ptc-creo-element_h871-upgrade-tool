;; ============================================================================
;; H871 PART FILTER - DIRECT SELECTION RESEARCH
;; Stage 1: SEL_ITEM handle probe - isolated V2 command
;; Target: Creo Elements/Direct Modeling 18.1
;;
;; IMPORTANT: This file defines a NEW command:
;;   H871_PF_V03_SELITEM_PROBE_V2
;; It intentionally uses new function/dialog symbols so Modeling cannot
;; dispatch the previously registered V1 dialog action by name.
;;
;; Load this file AFTER VER-03. Select rows in any Results tab, then run V2.
;;
;; Non-mutating: no BrowserNodes, no browser, no geometry changes, and no
;; changes to Modeling's active selection. It only reads the UICT result
;; tables and writes a report in the user's home folder.
;;
;; No reference is made to the VER-03 current-page variable.
;; ============================================================================

(in-package :oli)

(defun h871-pf-v03-probe-v2-trace-file ()
  (merge-pathnames
    "H871_PF_V03_SELITEM_PROBE_V2.txt"
    (user-homedir-pathname)))

(defun h871-pf-v03-probe-v2-page (entry stream total)
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
      (format stream "  Selected Part count: ~S~%" (length parts))
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
          (format stream "    ROUNDTRIP TYPE-OF: ~S~%"
            (and roundtrip (type-of roundtrip)))
          (format stream "    ROUNDTRIP SD-INQ-PART-P: ~S~%"
            roundtrip-part-p)
          (format stream "    ROUNDTRIP PATHNAME: ~S~%" roundtrip-path)
          (format stream "    PATH MATCH: ~S~%" path-match)))
      (terpri stream))))

(defun h871-pf-v03-probe-run-v2 ()
  (let* ((registry-bound-p (boundp '*h871-pf-v03-pages*))
         (pages (and registry-bound-p *h871-pf-v03-pages*))
         (trace-file (h871-pf-v03-probe-v2-trace-file))
         (total (list 0)))
    (with-open-file
      (stream trace-file
        :direction :output
        :if-exists :supersede
        :if-does-not-exist :create)
      (format stream "H871 VER-03 SEL_ITEM PROBE V2~%")
      (format stream "Page registry bound: ~S~%" registry-bound-p)
      (format stream "Registered page count: ~S~%"
        (if pages (length pages) 0))
      (terpri stream)
      (cond
        ((not registry-bound-p)
          (format stream
            "RESULT: VER-03 page registry is unbound. Load VER-03 first in this Modeling session.~%"))
        ((null pages)
          (format stream
            "RESULT: No Results pages registered. Run a Part Filter search first.~%"))
        (t
          (dolist (entry pages)
            (h871-pf-v03-probe-v2-page entry stream total))
          (if (= (car total) 0)
              (format stream
                "RESULT: No selected Part rows found. Select rows in Results and retry.~%")
            (format stream
              "RESULT: Inspected ~A selected Part row(s).~%"
              (car total))))))
    (sd-display-message
      (format nil
        "H871 SEL_ITEM probe V2 finished. Rows inspected: ~A. Report: ~A"
        (car total)
        (namestring trace-file)))
    trace-file))

(sd-defdialog 'h871_pf_v03_selitem_probe_v2
  :dialog-title "H871 - SEL_ITEM Probe V2"
  :dialog-control :sequential
  :variables '()
  :ok-action
    '(h871-pf-v03-probe-run-v2))

;; Command: H871_PF_V03_SELITEM_PROBE_V2
