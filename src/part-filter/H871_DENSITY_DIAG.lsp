;; ============================================================
;; H871 DENSITY PROPERTY DIAGNOSTIC
;; Target: Creo Elements/Direct Modeling 18.1
;; Select one known Part and inspect density inquiry return values.
;; This diagnostic does not modify model data.
;; Output: H871_DENSITY_DIAGNOSTIC.txt in user home directory.
;; Command: H871_DENSITY_DIAG
;; ============================================================

(in-package :oli)

(defun h871-dd-safe (label thunk stream)
  (format stream "~%~A: " label)
  (let ((result (ignore-errors (funcall thunk))))
    (if result
        (format stream "~S  TYPE=~S~%" result (type-of result))
      (format stream "NIL or inquiry raised an error.~%"))))

(defun h871-dd-run (part)
  (let ((report (merge-pathnames "H871_DENSITY_DIAGNOSTIC.txt"
                                 (user-homedir-pathname))))
    (with-open-file (stream report
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
      (format stream "H871 DENSITY DIAGNOSTIC~%")
      (format stream "Part: ~A~%" (or (sd-inq-obj-basename part) "<NO NAME>"))
      (format stream "Path: ~A~%" (or (sd-inq-obj-pathname part) "<NO PATH>"))
      (h871-dd-safe "Default density" (lambda () (sd-inq-part-density part)) stream)
      (h871-dd-safe "Instance density" (lambda () (sd-inq-part-density part :instance)) stream)
      (h871-dd-safe "Contents density" (lambda () (sd-inq-part-density part :contents)) stream)
      (h871-dd-safe "Instance attributes"
                    (lambda () (sd-inq-item-attributes part :attachment :instance)) stream)
      (h871-dd-safe "Contents attributes"
                    (lambda () (sd-inq-item-attributes part :attachment :contents)) stream)
      (format stream "~%END OF REPORT~%"))
    (display (format nil "Diagnostic report written to: ~A" (namestring report)))
    report))

(sd-defdialog 'h871_density_diag
  :dialog-title "H871 - DENSITY PROPERTY DIAGNOSTIC"
  :variables
  '(
    ("SELECT PART")
    (PART
      :value-type :part
      :title "Known Part"
      :prompt-text "Select one Part whose Properties show Density Instance 1 and Density Base 304.")
  )
  :ok-action
  '(h871-dd-run part))

;; Load:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_DENSITY_DIAG.lsp")
;; Then run command: H871_DENSITY_DIAG
