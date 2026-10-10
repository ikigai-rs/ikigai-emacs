;;; ikigai-test.el --- ERT tests for ikigai.el -*- lexical-binding: t; -*-

;; Run in batch, with no kernel and no init file:
;;   emacs -Q --batch -L . -l test/ikigai-test.el -f ert-run-tests-batch-and-exit
;;
;; `ikigai-refresh-aliases' is driven end to end with `ikigai-eval' stubbed to
;; return a fixture prelude, so nothing here starts or reaches an `ikigai'.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'ikigai)

(defconst ikigai-test--fixtures
  (expand-file-name "fixtures"
                    (file-name-directory (or load-file-name buffer-file-name)))
  "Directory holding the fixture preludes.")

(defconst ikigai-test--alias-names
  '(ikigai-fn-toUpper ikigai-text-head ikigai-host-history ikigai-host-history!)
  "Every function any fixture defines, cleared after each test.")

(defun ikigai-test--fixture (name)
  "The text of fixture NAME, as the kernel would return it."
  (with-temp-buffer
    (insert-file-contents (expand-file-name name ikigai-test--fixtures))
    (buffer-string)))

(defun ikigai-test--refresh (fixture)
  "Run `ikigai-refresh-aliases' with the kernel answering FIXTURE."
  (let ((text (ikigai-test--fixture fixture)))
    (cl-letf (((symbol-function 'ikigai-eval)
               (lambda (command)
                 (should (equal command
                                "source urn:lisp:aliases as=text/x-emacs-lisp"))
                 text)))
      (ikigai-refresh-aliases))))

(defmacro ikigai-test--with-aliases (&rest body)
  "Run BODY with a fresh aliases file and no alias functions bound.
`load-history' is rebound so one test's loads cannot claim another's functions:
provenance is exactly what the unbinding guard reads."
  (declare (indent 0))
  `(let ((load-history load-history)
         (ikigai-aliases-file (make-temp-file "ikigai-aliases" nil ".el"))
         (ikigai--alias-files nil)
         (ikigai-aliases-report-buffer " *ikigai-aliases-test*"))
     (mapc #'fmakunbound ikigai-test--alias-names)
     (unwind-protect (progn ,@body)
       (mapc #'fmakunbound ikigai-test--alias-names)
       (when (get-buffer ikigai-aliases-report-buffer)
         (kill-buffer ikigai-aliases-report-buffer))
       (delete-file ikigai-aliases-file))))

(defun ikigai-test--report-text ()
  "The contents of the report buffer."
  (with-current-buffer ikigai-aliases-report-buffer
    (buffer-substring-no-properties (point-min) (point-max))))

(ert-deftest ikigai-refresh-reports-skipped-names ()
  "A name the generator refused is returned, listed, and counted in the message."
  (ikigai-test--with-aliases
    (let* ((report (ikigai-test--refresh "aliases-before.el"))
           (skipped (plist-get report :skipped)))
      (should (equal (sort (copy-sequence (plist-get report :defined)) #'string<)
                     '(ikigai-fn-toUpper ikigai-host-history ikigai-host-history!
                                         ikigai-text-head)))
      (should (equal skipped
                     '((:iri "urn:text:head" :verb "Source"
                             :reason "`ikigai-text-head` is already defined above — two IRIs, one name"
                             :reach "(ikigai-invoke 'source \"urn:text:head\")")
                       (:iri "urn:demo:odd" :verb "Frobnicate"
                             :reason "`Frobnicate` is not a kernel verb"
                             :reach "(ikigai-invoke 'frobnicate \"urn:demo:odd\")"))))
      (let ((text (ikigai-test--report-text)))
        (should (string-match-p "4 defined, 2 skipped, 0 removed" text))
        (should (string-match-p "urn:text:head (Source)" text))
        (should (string-match-p (regexp-quote "(ikigai-invoke 'source \"urn:text:head\")")
                                text)))
      (should (string-match-p "; 2 skipped, 0 removed"
                              (ikigai--report-aliases report))))))

(ert-deftest ikigai-refresh-unbinds-aliases-that-left ()
  "An alias the previous refresh defined and this one does not is unbound."
  (ikigai-test--with-aliases
    (ikigai-test--refresh "aliases-before.el")
    (should (fboundp 'ikigai-host-history!))
    (let ((report (ikigai-test--refresh "aliases-after.el")))
      (should (equal (plist-get report :removed) '(ikigai-host-history!)))
      (should (null (plist-get report :skipped)))
      (should-not (fboundp 'ikigai-host-history!))
      ;; What the new file still defines stays, at its NEW definition.
      (should (fboundp 'ikigai-fn-toUpper))
      (should (fboundp 'ikigai-host-history))
      (let (called)
        (cl-letf (((symbol-function 'ikigai-invoke)
                   (lambda (&rest args) (setq called args) "")))
          (ikigai-text-head "x"))
        (should (equal called '(source "urn:text:head" "in" "x"))))
      (should (string-match-p "Removed.*\n  ikigai-host-history!"
                              (ikigai-test--report-text)))
      ;; And the package itself is untouched.
      (dolist (f '(ikigai-eval ikigai-invoke ikigai-refresh-aliases ikigai-repl))
        (should (fboundp f))))))

(ert-deftest ikigai-refresh-unbinds-after-an-init-file-load ()
  "The aliases an init file loaded before any refresh are tracked too."
  (ikigai-test--with-aliases
    (with-temp-file ikigai-aliases-file
      (insert (ikigai-test--fixture "aliases-before.el")))
    ;; What the README tells an init file to do.
    (load ikigai-aliases-file t t)
    (should (fboundp 'ikigai-host-history!))
    (let ((report (ikigai-test--refresh "aliases-after.el")))
      (should (equal (plist-get report :removed) '(ikigai-host-history!)))
      (should-not (fboundp 'ikigai-host-history!)))))

(ert-deftest ikigai-refresh-never-unbinds-what-it-did-not-define ()
  "A function some other file defined since the last refresh is left alone."
  (ikigai-test--with-aliases
    (ikigai-test--refresh "aliases-before.el")
    (let ((mine (make-temp-file "ikigai-user" nil ".el"
                                "(defun ikigai-host-history! (x) (list 'mine x))\n")))
      (unwind-protect
          (progn
            (load mine nil t)
            (let ((report (ikigai-test--refresh "aliases-after.el")))
              (should (null (plist-get report :removed)))
              (should (equal (ikigai-host-history! 1) '(mine 1)))))
        (delete-file mine)))))

(ert-deftest ikigai-refresh-quiet-when-nothing-skipped-or-removed ()
  "The message is the plain count when there is nothing else to say."
  (ikigai-test--with-aliases
    (let ((report (ikigai-test--refresh "aliases-after.el")))
      (should (equal (plist-get report :removed) nil))
      (should (equal (plist-get report :skipped) nil))
      (should (equal (ikigai--report-aliases report)
                     (format "ikigai: 3 aliases loaded from %s"
                             (abbreviate-file-name ikigai-aliases-file)))))))

(provide 'ikigai-test)
;;; ikigai-test.el ends here
