;; ============================================================
;; H871 DENSITY PROPERTY DIAGNOSTIC - ERROR DETAIL REVISION
;; Target: PTC Creo Elements/Direct Modeling 18.1
;; Select one known Part and capture both return values and errors.
;; This diagnostic does not modify model data.
;; Output: H871_DENSITY_DIAGNOSTIC.txt in user home directory.
;; Command: H871_DENSITY_DIAG
;; ============================================================

(in-package :oli)

(defun h871-dd-safe (label thunk stream)
  (format stream "~%~A: " label)
  ;; IGNORE-ERRORS returns (values NIL condition) on error.
  ;; Preserve the condition so NIL and a failed API call are distinct.
  (multiple-value-bind (result condition)
      (ignore-errors (funcall thunk))
    (cond
      (condition
       (format stream "ERROR: ~A~%ERROR TYPE: ~S~%"
               condition (type-of condition)))
      ((null result)
       (format stream "RETURNED NIL (no signaled error).~%"))
      (t
       (format stream "VALUE: ~S  TYPE: ~S~%"
               result (type-of result))))))

(defun h871-dd-function-status (symbol stream)
  (format stream "~A: ~A~%"
          symbol
          (if (fboundp symbol) "DEFINED" "NOT DEFINED")))

(defun h871-dd-run (part)
  (let ((report (merge-pathnames "H871_DENSITY_DIAGNOSTIC.txt"
                                 (user-homedir-pathname))))
    (with-open-file (stream report
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
      (format stream "H871 DENSITY DIAGNOSTIC - ERROR DETAIL REVISION~%")
      (format stream "Part: ~A~%" (or (sd-inq-obj-basename part) "<NO NAME>"))
      (format stream "Path: ~A~%" (or (sd-inq-obj-pathname part) "<NO PATH>"))
      (format stream "Object type: ~S~%" (type-of part))
      (h871-dd-safe "Part predicate" (lambda () (sd-inq-part-p part)) stream)
      (format stream "~%API SYMBOL AVAILABILITY~%")
      (h871-dd-function-status 'sd-inq-part-density stream)
      (h871-dd-function-status 'sd-inq-item-attributes stream)
      (format stream "~%DENSITY INQUIRIES~%")
      (h871-dd-safe "Default density (one argument)"
                    (lambda () (sd-inq-part-density part)) stream)
      (h871-dd-safe "Instance density (kind :instance)"
                    (lambda () (sd-inq-part-density part :instance)) stream)
      (h871-dd-safe "Contents density (kind :contents)"
                    (lambda () (sd-inq-part-density part :contents)) stream)
      (format stream "~%ATTRIBUTE INQUIRIES~%")
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
