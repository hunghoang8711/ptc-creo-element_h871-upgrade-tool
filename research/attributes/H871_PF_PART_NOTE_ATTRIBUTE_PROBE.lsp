;; ============================================================
;; H871 PART FILTER - Per-Part Note Attribute Probe
;; Target: Creo Elements/Direct Modeling 18.1
;;
;; PURPOSE:
;; Isolated feasibility test for storing a note on a Part using a
;; native User-Defined Attribute (UDA). This file does NOT modify
;; the VER-06 production source.
;;
;; TEST ONLY ON A DISPOSABLE/COPIED PART OR ASSEMBLY.
;; Save the test model to a new file, close it, reopen it, and run
;; the read command again to verify persistence.
;;
;; Evidence boundary:
;; sd-attach-item-attribute / sd-mod-item-attribute /
;; sd-inq-item-attributes / sd-inq-item-attribute are documented
;; in later Integration Kit references. Exact 18.1 runtime behavior
;; must be confirmed by the user before production integration.
;; ============================================================

(in-package :oli)

(defvar *h871-pf-note-attribute-name* "H871_PART_FILTER_NOTE")

(defun h871-pf-note-probe-write (part note)
  (let ((attached
          (member *h871-pf-note-attribute-name*
                  (sd-inq-item-attributes part :attachment :instance)
                  :test #'string=)))
    (if attached
        (sd-mod-item-attribute
          part
          *h871-pf-note-attribute-name*
          :attachment :instance
          :filing :sd-file
          :values (list :note note))
      (sd-attach-item-attribute
        part
        *h871-pf-note-attribute-name*
        :attachment :instance
        :filing :sd-file
        :values (list :note note)))
    (let ((stored
            (sd-inq-item-attribute
              part
              *h871-pf-note-attribute-name*
              :note
              :attachment :instance)))
      (sd-display-message
        (format nil
          "H871 note write probe finished.~%Part: ~A~%Expected: ~A~%Read back: ~A~%Attribute value matches: ~A"
          (or (sd-inq-obj-basename part) "<NO NAME>")
          note
          stored
          (equal note stored))))))

(defun h871-pf-note-probe-read (part)
  (let* ((attributes
           (sd-inq-item-attributes part :attachment :instance))
         (stored
           (sd-inq-item-attribute
             part
             *h871-pf-note-attribute-name*
             :note
             :attachment :instance)))
    (sd-display-message
      (format nil
        "H871 note read probe.~%Part: ~A~%Attribute exists: ~A~%Stored note: ~A"
        (or (sd-inq-obj-basename part) "<NO NAME>")
        (not (null (member *h871-pf-note-attribute-name* attributes
                            :test #'string=)))
        (or stored "<NO NOTE>")))))

(sd-defdialog 'h871_pf_note_probe_write
  :dialog-title "H871 - Part Note Attribute WRITE TEST"
  :variables
  '((PART
      :value-type :part
      :title "Test Part"
      :prompt-text "Select one disposable Part to attach the test note.")
    (NOTE
      :value-type :string
      :title "Test Note"
      :initial-value "H871 attribute persistence test"))
  :ok-action
  '(progn
     (h871-pf-note-probe-write PART NOTE)
     (sd-return-from-ok-action)))

(sd-defdialog 'h871_pf_note_probe_read
  :dialog-title "H871 - Part Note Attribute READ TEST"
  :variables
  '((PART
      :value-type :part
      :title "Test Part"
      :prompt-text "Select the Part whose saved note should be read."))
  :ok-action
  '(progn
     (h871-pf-note-probe-read PART)
     (sd-return-from-ok-action)))

;; LOAD:
;; (load "D:/.../H871_PF_PART_NOTE_ATTRIBUTE_PROBE.lsp")
;; WRITE COMMAND:
;; H871_PF_NOTE_PROBE_WRITE
;; READ COMMAND:
;; H871_PF_NOTE_PROBE_READ
