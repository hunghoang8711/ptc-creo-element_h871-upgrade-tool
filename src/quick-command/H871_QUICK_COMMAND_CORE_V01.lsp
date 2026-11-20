;; ============================================================
;; H871 QUICK COMMAND - CORE V0.1
;; Target: Creo Elements/Direct Modeling 18.1
;;
;; Scope of this first source revision:
;; - Command registry (name, aliases, description, action)
;; - Case-insensitive prefix search
;; - Exact command lookup
;; - Safe callback dispatch
;;
;; Deliberately NOT included yet:
;; - Ctrl+Space global shortcut registration
;; - Cursor-following popup
;; - Live autocomplete UI / keyboard event handling
;;
;; Those UI capabilities must be verified against the installed
;; Modeling 18.1 APIs before they are connected to this core.
;; No mouse or selection behavior is hooked by this file.
;; ============================================================

(in-package :oli)

(defvar *h871-qc-command-registry* nil
  "Registered H871 Quick Command entries.")

(defun h871-qc-normalize (value)
  (if (stringp value)
      (string-upcase value)
      ""))

(defun h871-qc-prefix-p (prefix candidate)
  "Case-insensitive prefix comparison."
  (let ((p (h871-qc-normalize prefix))
        (c (h871-qc-normalize candidate)))
    (and (<= (length p) (length c))
         (string= p c :end2 (length p)))))

(defun h871-qc-register (name description action &optional aliases)
  "Register or replace a command.
ACTION must be a function symbol. Arbitrary strings are not evaluated."
  (let* ((normalized-name (h871-qc-normalize name))
         (normalized-aliases
           (mapcar #'h871-qc-normalize aliases))
         (entry
           (list :name normalized-name
                 :description (or description "")
                 :action action
                 :aliases normalized-aliases)))
    (unless (> (length normalized-name) 0)
      (error "H871 Quick Command: command name cannot be empty."))
    (unless (and (symbolp action) (fboundp action))
      (error "H871 Quick Command: action must name an existing function."))
    (setf *h871-qc-command-registry*
          (cons entry
                (remove normalized-name
                        *h871-qc-command-registry*
                        :key (lambda (item) (getf item :name))
                        :test #'equal)))
    entry))

(defun h871-qc-search (text)
  "Return commands whose name or alias begins with TEXT."
  (let ((query (h871-qc-normalize text)))
    (if (equal query "")
        (copy-list *h871-qc-command-registry*)
        (remove-if-not
         (lambda (entry)
           (or (h871-qc-prefix-p query (getf entry :name))
               (some (lambda (alias)
                       (h871-qc-prefix-p query alias))
                     (getf entry :aliases))))
         *h871-qc-command-registry*))))

(defun h871-qc-find-exact (text)
  "Find one command by exact name or exact alias."
  (let ((query (h871-qc-normalize text)))
    (find-if
     (lambda (entry)
       (or (equal query (getf entry :name))
           (member query (getf entry :aliases) :test #'equal)))
     *h871-qc-command-registry*)))

(defun h871-qc-run (text)
  "Run only an exact registered command."
  (let ((entry (h871-qc-find-exact text)))
    (if entry
        (funcall (getf entry :action))
        (progn
          (format t "~%[H871 QC] No exact command registered for: ~A~%"
                  (h871-qc-normalize text))
          nil))))

(defun h871-qc-list (text)
  "Print prefix matches to the Modeling Lisp output."
  (let ((matches (h871-qc-search text)))
    (format t "~%[H871 QC] Matches for '~A':~%"
            (h871-qc-normalize text))
    (if matches
        (dolist (entry matches)
          (format t "  ~A  |  ~A~%"
                  (getf entry :name)
                  (getf entry :description)))
        (format t "  (no matches)~%"))
    matches))

(defun h871-qc-self-test-action ()
  (format t "~%[H871 QC] Self-test action executed.~%")
  t)

;; Harmless internal test command. It does not modify model geometry.
(h871-qc-register
 "H871-QC-SELFTEST"
 "Internal test command; writes a confirmation to the Lisp output."
 'h871-qc-self-test-action
 '("HQC" "QC-TEST"))

(format t "~%[H871 QC] Core V0.1 loaded. Registry entries: ~A~%"
        (length *h871-qc-command-registry*))
(format t "[H871 QC] Try: (h871-qc-list \"H\")~%")
(format t "[H871 QC] Try: (h871-qc-run \"HQC\")~%")
