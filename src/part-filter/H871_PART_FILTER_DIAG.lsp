
;; ============================================================
;; H871 PART FILTER v1
;; Creo Elements/Direct Modeling 18.1
;;
;; Current implementation:
;; - Select an assembly
;; - Fixed Material / Base Density / Instance Density rows
;; - Enable/disable each condition
;; - AND / OR logic
;; - Recursive assembly scan
;; - Density filtering
;; - Export matching results to a text report
;;
;; Material inquiry is intentionally not implemented yet.
;; ============================================================

(in-package :oli)

;; ------------------------------------------------------------
;; Utility functions
;; ------------------------------------------------------------

(defun h871-pf-name (obj)
  (or (sd-inq-obj-basename obj) "<NO NAME>"))

(defun h871-pf-path (obj)
  (or (sd-inq-obj-pathname obj) "<NO PATH>"))

(defun h871-pf-number-match (actual operator target)
  (if (null actual)
      nil
    (cond
      ((eq operator :equal)
       (= actual target))
      ((eq operator :not-equal)
       (/= actual target))
      ((eq operator :greater)
       (> actual target))
      ((eq operator :greater-equal)
       (>= actual target))
      ((eq operator :less)
       (< actual target))
      ((eq operator :less-equal)
       (<= actual target))
      (t nil))))

(defun h871-pf-density-match (part kind operator target)
  (let ((actual (sd-inq-part-density part kind)))
    (h871-pf-number-match actual operator target)))

;; ------------------------------------------------------------
;; Filter evaluation
;; ------------------------------------------------------------

(defun h871-pf-check-part
       (part
        use-base base-op base-value
        use-instance instance-op instance-value
        logic)

  (let ((checks nil))

    (when use-base
      (push
        (h871-pf-density-match
          part :contents base-op base-value)
        checks))

    (when use-instance
      (push
        (h871-pf-density-match
          part :instance instance-op instance-value)
        checks))

    (if (null checks)
        t
      (if (eq logic :and)
          (every #'identity checks)
        (some #'identity checks)))))

;; ------------------------------------------------------------
;; Recursive assembly scanning
;; ------------------------------------------------------------

(defun h871-pf-scan
       (obj stream counters
        use-base base-op base-value
        use-instance instance-op instance-value
        logic)

  (when (sd-inq-part-p obj)

    (incf (getf counters :parts))

    (when
      (h871-pf-check-part
        obj
        use-base base-op base-value
        use-instance instance-op instance-value
        logic)

      (incf (getf counters :matched))

      (format stream "~%----------------------------------------~%")
      (format stream "PART: ~A~%" (h871-pf-name obj))
      (format stream "PATH: ~A~%" (h871-pf-path obj))
      (format stream "BASE DENSITY: ~A~%"
        (sd-inq-part-density obj :contents))
      (format stream "INSTANCE DENSITY: ~A~%"
        (sd-inq-part-density obj :instance))))

  (dolist (child (sd-inq-obj-children obj))
    (h871-pf-scan
      child stream counters
      use-base base-op base-value
      use-instance instance-op instance-value
      logic))

  counters)

;; ------------------------------------------------------------
;; Main action
;; ------------------------------------------------------------

(defun h871-pf-run
       (assembly
        use-material material-value
        use-base base-op base-value
        use-instance instance-op instance-value
        logic)

  (let* ((report
           (merge-pathnames
             "H871_PART_FILTER_RESULT.txt"
             (user-homedir-pathname)))
         (counts
           (list :parts 0 :matched 0)))

    ;; Material is not yet connected to a verified 18.1 API.
    (when use-material
      (display
        "Material filter is not available in v1. Please turn it OFF.")
      (return-from h871-pf-run nil))

    (with-open-file
      (s report
        :direction :output
        :if-exists :supersede
        :if-does-not-exist :create)

      (format s "H871 PART FILTER - RESULT~%")
      (format s "Assembly: ~A~%" (h871-pf-path assembly))
      (format s "Logic: ~A~%" logic)
      (format s "Base Density Filter: ~A~%" use-base)
      (format s "Instance Density Filter: ~A~%" use-instance)

      (h871-pf-scan
        assembly s counts
        use-base base-op base-value
        use-instance instance-op instance-value
        logic)

      (format s "~%========================================~%")
      (format s "SUMMARY~%")
      (format s "Parts scanned: ~A~%" (getf counts :parts))
      (format s "Matching parts: ~A~%" (getf counts :matched)))

    (display
      (format nil
        "H871 Part Filter completed.~%Scanned: ~A~%Matched: ~A~%Report: ~A"
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

    ("FILTER LOGIC")
    (FILTER_LOGIC
      :range (:and :or)
      :initial-value :and
      :title "Combine enabled conditions")

    ("1. MATERIAL")
    (USE_MATERIAL
      :value-type :boolean
      :initial-value nil
      :title "Enable Material Filter")

    (MATERIAL_VALUE
      :value-type :string
      :initial-value ""
      :title "Material")

    ("2. BASE DENSITY")
    (USE_BASE
      :value-type :boolean
      :initial-value t
      :title "Enable Base Density")

    (BASE_OPERATOR
      :range (:equal :not-equal
              :greater :greater-equal
              :less :less-equal)
      :initial-value :equal
      :title "Condition")

    (BASE_VALUE
      :value-type :number
      :initial-value 0.0
      :title "Base Density")

    ("3. INSTANCE DENSITY")
    (USE_INSTANCE
      :value-type :boolean
      :initial-value nil
      :title "Enable Instance Density")

    (INSTANCE_OPERATOR
      :range (:equal :not-equal
              :greater :greater-equal
              :less :less-equal)
      :initial-value :equal
      :title "Condition")

    (INSTANCE_VALUE
      :value-type :number
      :initial-value 0.0
      :title "Instance Density")
  )

  :ok-action
  '(h871-pf-run
      assembly
      use_material material_value
      use_base base_operator base_value
      use_instance instance_operator instance_value
      filter_logic)
)

;; ============================================================
;; LOAD:
;; (load "D:/HH871/05-TEST-LISP-PTC/H871_PART_FILTER_v1.lsp")
;;
;; COMMAND:
;; H871_PART_FILTER
;; ============================================================
