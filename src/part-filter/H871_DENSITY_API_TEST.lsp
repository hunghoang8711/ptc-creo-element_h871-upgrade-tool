;; ============================================================
;; H871 DENSITY API ISOLATION TEST
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Purpose:
;;   Isolate the two API calls without SEL_ITEM-P, FUNCALL,
;;   LAMBDA, IGNORE-ERRORS, or User Input Line expressions.
;;
;; Commands after loading this file:
;;   H871_DENSITY_TEST_PART_P
;;   H871_DENSITY_TEST_ONE_ARG
;;
;; Each command asks the user to select the known Part and writes
;; a report to H871_DENSITY_API_TEST.txt in the user home folder.
;;
;; This test only reads model properties. It does not modify them.
;; ============================================================

(in-package :oli)

(defun h871-dat-write-header (stream test-name part)
  (format stream "H871 DENSITY API ISOLATION TEST~%")
  (format stream "Test: ~A~%" test-name)
  (format stream "Part name: ~A~%"
          (or (sd-inq-obj-basename part) "<NO NAME>"))
  (format stream "Part path: ~A~%"
          (or (sd-inq-obj-pathname part) "<NO PATH>"))
  (format stream "Lisp object type: ~S~%" (type-of part))
  (format stream "SD-INQ-PART-P defined: ~S~%" (fboundp 'sd-inq-part-p))
  (format stream "SD-INQ-PART-DENSITY defined: ~S~%" (fboundp 'sd-inq-part-density))
  (finish-output stream))

(defun h871-dat-test-part-p (part)
  (let ((report (merge-pathnames "H871_DENSITY_API_TEST.txt"
                                 (user-homedir-pathname))))
    (with-open-file (stream report
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
      (h871-dat-write-header stream "SD-INQ-PART-P" part)
      (format stream "~%CALLING: (sd-inq-part-p part)~%")
      (finish-output stream)
      ;; Deliberately call the API directly. If Creo raises an error,
      ;; the exact runtime error remains visible instead of being
      ;; hidden by a generic error-catching wrapper.
      (let ((result (sd-inq-part-p part)))
        (format stream "RETURN VALUE: ~S~%" result)
        (format stream "RETURN TYPE: ~S~%" (type-of result))))
    (display (format nil "Report written to: ~A" (namestring report)))
    report))

(defun h871-dat-test-one-arg-density (part)
  (let ((report (merge-pathnames "H871_DENSITY_API_TEST.txt"
                                 (user-homedir-pathname))))
    (with-open-file (stream report
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
      (h871-dat-write-header stream "SD-INQ-PART-DENSITY (ONE ARGUMENT)" part)
      (format stream "~%CALLING: (sd-inq-part-density part)~%")
      (finish-output stream)
      ;; Deliberately test only the legacy one-argument form.
      (let ((result (sd-inq-part-density part)))
        (format stream "RETURN VALUE: ~S~%" result)
        (format stream "RETURN TYPE: ~S~%" (type-of result))))
    (display (format nil "Report written to: ~A" (namestring report)))
    report))

(sd-defdialog 'h871_density_test_part_p
  :dialog-title "H871 - TEST PART PREDICATE"
  :variables
  '(
    ("SELECT KNOWN PART")
    (PART
      :value-type :part
      :title "Known Part"
      :prompt-text "Select 010-plate_2.1.1.2.1, whose Properties show Density Instance 1 and Base 304.")
  )
  :ok-action
  '(h871-dat-test-part-p part))

(sd-defdialog 'h871_density_test_one_arg
  :dialog-title "H871 - TEST LEGACY DENSITY API"
  :variables
  '(
    ("SELECT KNOWN PART")
    (PART
      :value-type :part
      :title "Known Part"
      :prompt-text "Select 010-plate_2.1.1.2.1, whose Properties show Density Instance 1 and Base 304.")
  )
  :ok-action
  '(h871-dat-test-one-arg-density part))

;; Load this file using the same LISP file-loading method already
;; used successfully for H871_PART_FILTER.lsp.
;; Then run each command separately:
;;   H871_DENSITY_TEST_PART_P
;;   H871_DENSITY_TEST_ONE_ARG
;;
;; IMPORTANT:
;;   Do not enter these command names or Lisp expressions in the
;;   User Input Line. Start the dialogs from the Modeling command
;;   interface/menu mechanism used to launch other sd-defdialog tools.
