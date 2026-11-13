;; ============================================================
;; H871 PART FILTER - Density Instance/Base exact match
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Searches all Parts recursively below a selected Assembly.
;; A Part matches only when BOTH Density values match exactly.
;; Matching Parts are passed to Creo's standard selection action
;; (GET_SELECTION), so they become a native selection set for
;; subsequent commands such as Add to Drawlist.
;;
;; Density inquiry:
;;   :instance -> Density Instance
;;   :contents -> Density Base
;;
;; Verification status:
;;   Static source review only. Must be tested in Creo 18.1.
;; ============================================================

(in-package :oli)

(defvar *h871-pf-requested-instance* nil)
(defvar *h871-pf-requested-base* nil)

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
    (and actual-instance
         actual-base
         (= actual-instance requested-instance)
         (= actual-base requested-base))))

;; GET_SELECTION check function.
;; Return :OK to retain the Part in Creo's selection list,
;; or :FILTER to exclude it.
(defun h871-pf-selection-check (part)
  (if
    (h871-pf-density-pair-match
      part
      *h871-pf-requested-instance*
      *h871-pf-requested-base*)
    :ok
    :filter))

(defun h871-pf-write-report
       (assembly matches requested-instance requested-base)
  (let ((report
          (merge-pathnames
            "H871_PART_FILTER_RESULT.txt"
            (user-homedir-pathname))))
    (with-open-file
      (s report
        :direction :output
        :if-exists :supersede
        :if-does-not-exist :create)
      (format s "H871 PART FILTER - EXACT DENSITY PAIR~%")
      (format s "Assembly: ~A~%" (h871-pf-path assembly))
      (format s "Requested Density Instance: ~A~%" requested-instance)
      (format s "Requested Density Base: ~A~%" requested-base)
      (format s "Match rule: Instance AND Base must both match exactly.~%")
      (dolist (part matches)
        (format s "~%----------------------------------------~%")
        (format s "PART: ~A~%" (h871-pf-name part))
        (format s "PATH: ~A~%" (h871-pf-path part))
        (format s "DENSITY INSTANCE: ~A~%"
          (sd-inq-part-density part :instance))
        (format s "DENSITY BASE: ~A~%"
          (sd-inq-part-density part :contents)))
      (format s "~%========================================~%")
      (format s "Matching parts: ~A~%" (length matches)))
    report))

(defun h871-pf-run (assembly requested-instance requested-base)
  (let* ((*h871-pf-requested-instance* requested-instance)
         (*h871-pf-requested-base* requested-base)
         (matches nil)
         (report nil))

    ;; Ask Creo's native selector to select every matching Part
    ;; under the selected Assembly. The check function rejects
    ;; every Part whose Instance/Base pair is not an exact match.
    (setf matches
      (sd-call-cmds
        (get_selection
          :focus_type *sd-part-seltype*
          :check_function #'h871-pf-selection-check
          :select
          :in_assembly assembly)))

    (setf report
      (h871-pf-write-report
        assembly matches requested-instance requested-base))

    (display
      (format nil
        "H871 Part Filter completed.~%Density Instance: ~A~%Density Base: ~A~%Matching Parts selected: ~A~%Report: ~A~%~%The matching Parts are now in Creo's selection list."
        requested-instance
        requested-base
        (length matches)
        (namestring report)))

    matches))

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

;; LOAD:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER.lsp")
;; COMMAND:
;; H871_PART_FILTER
