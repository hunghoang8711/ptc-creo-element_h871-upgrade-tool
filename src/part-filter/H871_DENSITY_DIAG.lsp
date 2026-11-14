;; ============================================================
;; H871 DENSITY PROPERTY DIAGNOSTIC
;; Target: Creo Elements/Direct Modeling 18.1
;;
;; Purpose:
;; Inspect one known Part whose Part Properties dialog shows
;; Density Instance = 1 and Density Base = 304.
;;
;; This is diagnostic only. It does not modify model data.
;; Output: H871_DENSITY_DIAGNOSTIC.txt in user home directory.
;; Command: H871_DENSITY_DIAG
;; ============================================================

(in-package :oli)

(defun h871-density-diag-safe-call (fn)
  (multiple-value-bind (value condition)
      (ignore-errors (funcall fn))
    (if condition
        (list :error (princ-to-string condition))
      (list :value value :type (if value (type-of value) :nil)))))

(defun h871-density-diag-write-attributes (stream part attachment)
  (format stream "~%--- ITEM ATTRIBUTES (~A) ---~%" attachment)
  (if (not (fboundp 'sd-inq-item-attributes))
      (format stream "sd-inq-item-attributes: NOT AVAILABLE in this runtime.~%")
    (let ((attrs
            (h871-density-diag-safe-call
              (lambda ()
                (sd-inq-item-attributes part :attachment attachment)))))
      (format stream "ATTRIBUTE NAMES: ~S~%" attrs)
      (when (and (listp attrs) (eq (first attrs) :value))
        (dolist (name (second attrs))
          (format stream "~%ATTRIBUTE: ~S~%" name)
          (when (fboundp 'sd-inq-item-attribute)
            (format stream "VALUES: ~S~%"
              (h871-density-diag-safe-call
                (lambda ()
                  (sd-inq-item-attribute
                    part name :all :attachment attachment)))))))))

(defun h871-density-diag-run (part)
  (let ((report
          (merge-pathnames
            "H871_DENSITY_DIAGNOSTIC.txt"
            (user-homedir-pathname))))
    (with-open-file
      (s report
        :direction :output
        :if-exists :supersede
        :if-does-not-exist :create)
      (format s "H871 DENSITY PROPERTY DIAGNOSTIC~%")
      (format s "Creo version: ~S~%" (h871-density-diag-safe-call
        (lambda () (sd-inq-version))))
      (format s "Part name: ~A~%" (or (sd-inq-obj-basename part) "<NO NAME>"))
      (format s "Part path: ~A~%" (or (sd-inq-obj-pathname part) "<NO PATH>"))
      (format s "Part object type: ~S~%" (type-of part))
      (format s "~%--- SD-INQ-PART-DENSITY CALLS ---~%")
      (format s "Default / realized: ~S~%"
        (h871-density-diag-safe-call
          (lambda () (sd-inq-part-density part))))
      (format s "Instance argument: ~S~%"
        (h871-density-diag-safe-call
          (lambda () (sd-inq-part-density part :instance))))
      (format s "Contents argument: ~S~%"
        (h871-density-diag-safe-call
          (lambda () (sd-inq-part-density part :contents))))
      (h871-density-diag-write-attributes s part :instance)
      (h871-density-diag-write-attributes s part :contents)
      (format s "~%--- END ---~%"))
    (display
      (format nil
        "Density diagnostic completed.~%Report: ~A"
        (namestring report)))
    report))

(sd-defdialog 'h871_density_diag
  :dialog-title "H871 - DENSITY PROPERTY DIAGNOSTIC"
  :variables
  '((PART
      :value-type :part
      :title "Select known Part"
      :prompt-text "Select one Part whose Properties show Density Instance 1 and Base 304."))
  :ok-action
  '(h871-density-diag-run part))

;; Load:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_DENSITY_DIAG.lsp")
;; Command:
;; H871_DENSITY_DIAG
