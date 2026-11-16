;; ============================================================================
;; H871 TRACE WRITER VALIDATION TEST
;; Target: PTC Creo Elements/Direct Modeling 18.1
;;
;; Purpose:
;; Validate plain Common Lisp file output independently of the ver-03 UICT
;; code. This file does not load, modify, or call the Part Filter.
;;
;; Usage:
;;   1. Load this file in Modeling 18.1.
;;   2. Run command: H871_PF_V03_TRACE_WRITE_TEST
;;   3. Read the exact pathname shown in the success message.
;;   4. Confirm the file contains the test line and is not 0 KB.
;;
;; Errors are intentionally NOT swallowed. If open/write/flush/close fails,
;; Modeling should report the actual LISP error instead of false success.
;; ============================================================================

(in-package :oli)

(defun h871-pf-v03-trace-write-test ()
  (let* ((file
           (merge-pathnames
             "H871_TRACE_WRITE_TEST.txt"
             (user-homedir-pathname)))
         (line
           "H871 TRACE WRITE TEST OK - Modeling 18.1"))
    (with-open-file
      (stream file
        :direction :output
        :if-exists :supersede
        :if-does-not-exist :create)
      (format stream "~A~%" line)
      (force-output stream))
    ;; The stream has been closed by WITH-OPEN-FILE before success is shown.
    (sd-display-message
      (format nil
        "H871 trace writer test completed.~%File: ~A~%Expected content: ~A"
        (namestring file) line))
    (namestring file)))

(sd-defdialog 'h871_pf_v03_trace_write_test
  :dialog-title "H871 - TRACE WRITE TEST"
  :variables '()
  :ok-action
    '(progn
       (h871-pf-v03-trace-write-test)
       (sd-return-from-ok-action)))

;; LOAD:
;; (load "D:/path/to/H871_TRACE_WRITE_TEST.lsp")
;; COMMAND:
;; H871_PF_V03_TRACE_WRITE_TEST
