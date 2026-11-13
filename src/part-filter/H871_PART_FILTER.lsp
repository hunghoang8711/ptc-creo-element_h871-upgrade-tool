;; ============================================================
;; H871 PART FILTER - Density Instance/Base exact match
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Searches all Parts recursively below a selected Assembly.
;; A Part matches only when BOTH values are exact matches:
;;   Density Instance = requested Instance
;;   Density Base     = requested Base
;;
;; Creo inquiry mapping:
;;   :instance -> Instance density
;;   :contents -> Base density
;;
;; Results are written to H871_PART_FILTER_RESULT.txt
;; in the current user's home directory.
;;
;; Verification status:
;;   Static source review only. Must be loaded and tested in
;;   Creo Elements/Direct Modeling 18.1.
;; ============================================================

(in-package :oli)

;; ------------------------------------------------------------
;; Utility functions
;; ------------------------------------------------------------

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
    ;; Missing/unassigned values must never be treated as a match.
    (and actual-instance
         actual-base
         (= actual-instance requested-instance)
         (= actual-base requested-base))))

;; ------------------------------------------------------------
;; Recursive Assembly scan
;; ------------------------------------------------------------

(defun h871-pf-scan
       (obj stream counters requested-instance requested-base)

  (when (sd-inq-part-p obj)
    (incf (getf counters :parts))

    (let ((actual-instance
            (sd-inq-part-density obj :instance))
          (actual-base
            (sd-inq-part-density obj :contents)))

      (when
        (and actual-instance
             actual-base
             (= actual-instance requested-instance)
             (= actual-base requested-base))

        (incf (getf counters :matched))

        (format stream "~%----------------------------------------~%")
        (format stream "PART: ~A~%" (h871-pf-name obj))
        (format stream "PATH: ~A~%" (h871-pf-path obj))
        (format stream "DENSITY INSTANCE: ~A~%" actual-instance)
        (format stream "DENSITY BASE: ~A~%" actual-base))))

  (dolist (child (sd-inq-obj-children obj))
    (h871-pf-scan
      child stream counters requested-instance requested-base))

  counters)

;; ------------------------------------------------------------
;; Main Find action
;; ------------------------------------------------------------

(defun h871-pf-run (assembly requested-instance requested-base)

  (let* ((report
           (merge-pathnames
             "H871_PART_FILTER_RESULT.txt"
             (user-homedir-pathname)))
         (counts
           (list :parts 0 :matched 0)))

    (with-open-file
      (s report
        :direction :output
        :if-exists :supersede
        :if-does-not-exist :create)

      (format s "H871 PART FILTER - EXACT DENSITY PAIR~%")
      (format s "Assembly: ~A~%" (h871-pf-path assembly))
      (format s "Requested Density Instance: ~A~%"
        requested-instance)
      (format s "Requested Density Base: ~A~%"
        requested-base)
      (format s "Match rule: Instance AND Base must both match exactly.~%")

      (h871-pf-scan
        assembly s counts requested-instance requested-base)

      (format s "~%========================================~%")
      (format s "SUMMARY~%")
      (format s "Parts scanned: ~A~%" (getf counts :parts))
      (format s "Matching parts: ~A~%" (getf counts :matched)))

    (display
      (format nil
        "H871 Part Filter completed.~%Density Instance: ~A~%Density Base: ~A~%Parts scanned: ~A~%Matching parts: ~A~%Report: ~A"
        requested-instance
        requested-base
        (getf counts :parts)
        (getf counts :matched)
        (namestring report)))

    report))

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

;; ============================================================
;; LOAD:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER.lsp")
;;
;; COMMAND:
;; H871_PART_FILTER
;; ============================================================
