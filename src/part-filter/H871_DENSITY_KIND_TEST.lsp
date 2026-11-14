;; ============================================================
;; H871 DENSITY KIND ARGUMENT TEST
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Purpose:
;;   Directly test the optional :INSTANCE and :CONTENTS forms of
;;   SD-INQ-PART-DENSITY, independently and without wrappers.
;;
;; Commands:
;;   H871_DENSITY_TEST_INSTANCE
;;   H871_DENSITY_TEST_CONTENTS
;;
;; Each command writes its own report in the user home folder.
;; This file only reads model properties.
;; ============================================================

(in-package :oli)

(defun h871-dkt-write-header (stream test-name part call-text)
  (format stream "H871 DENSITY KIND ARGUMENT TEST~%")
  (format stream "Test: ~A~%" test-name)
  (format stream "Part name: ~A~%" (or (sd-inq-obj-basename part) "<NO NAME>"))
  (format stream "Part path: ~A~%" (or (sd-inq-obj-pathname part) "<NO PATH>"))
  (format stream "Lisp object type: ~S~%" (type-of part))
  (format stream "SD-INQ-PART-P: ~S~%" (sd-inq-part-p part))
  (format stream "SD-INQ-PART-DENSITY defined: ~S~%" (fboundp 'sd-inq-part-density))
  (format stream "~%CALLING: ~A~%" call-text)
  (finish-output stream))

(defun h871-dkt-test-instance (part)
  (let ((report (merge-pathnames "H871_DENSITY_INSTANCE_TEST.txt"
                                 (user-homedir-pathname))))
    (with-open-file (stream report
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
      (h871-dkt-write-header stream "INSTANCE KIND"
                             part "(sd-inq-part-density part :instance)")
      ;; Deliberately direct: do not wrap this API call in FUNCALL,
      ;; LAMBDA, IGNORE-ERRORS, or a generic safe-call helper.
      (let ((result (sd-inq-part-density part :instance)))
        (format stream "RETURN VALUE: ~S~%" result)
        (format stream "RETURN TYPE: ~S~%" (type-of result))
        (finish-output stream)))
    (display (format nil "Report written to: ~A" (namestring report)))
    report))

(defun h871-dkt-test-contents (part)
  (let ((report (merge-pathnames "H871_DENSITY_CONTENTS_TEST.txt"
                                 (user-homedir-pathname))))
    (with-open-file (stream report
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
      (h871-dkt-write-header stream "CONTENTS KIND"
                             part "(sd-inq-part-density part :contents)")
      ;; Deliberately direct: do not wrap this API call in FUNCALL,
      ;; LAMBDA, IGNORE-ERRORS, or a generic safe-call helper.
      (let ((result (sd-inq-part-density part :contents)))
        (format stream "RETURN VALUE: ~S~%" result)
        (format stream "RETURN TYPE: ~S~%" (type-of result))
        (finish-output stream)))
    (display (format nil "Report written to: ~A" (namestring report)))
    report))

(sd-defdialog 'h871_density_test_instance
  :dialog-title "H871 - TEST DENSITY INSTANCE"
  :variables
  '(
    ("SELECT KNOWN PART")
    (PART
      :value-type :part
      :title "Known Part"
      :prompt-text "Select 010-plate_2.1.1.2.1, whose Properties show Density Instance 1 and Base 304.")
  )
  :ok-action
  '(h871-dkt-test-instance part))

(sd-defdialog 'h871_density_test_contents
  :dialog-title "H871 - TEST DENSITY CONTENTS"
  :variables
  '(
    ("SELECT KNOWN PART")
    (PART
      :value-type :part
      :title "Known Part"
      :prompt-text "Select 010-plate_2.1.1.2.1, whose Properties show Density Instance 1 and Base 304.")
  )
  :ok-action
  '(h871-dkt-test-contents part))

;; Load this file using the same proven LISP loading method used for
;; the existing H871 tools. Launch each dialog from the Modeling
;; command/menu mechanism; do not enter Lisp expressions in User Input Line.
