;;; ikigai.el --- A thin Emacs client for the ikigai kernel -*- lexical-binding: t; -*-

;; A command surface over the ikigai kernel: evaluate resources from a buffer, and
;; (first use case) schedule a Zoom for an org heading that doesn't have one. It shells
;; to the `ikigai' CLI and nothing heavier — a bounded front-end, not a fork of anything.
;;
;; Load it and bind what you like, e.g.:
;;   (with-eval-after-load 'org
;;     (define-key org-mode-map (kbd "C-c z") #'ikigai-org-schedule-zoom))
;;   (global-set-key (kbd "C-c i e") #'ikigai-eval-dwim)

;;; Code:

(require 'org)
(require 'org-element)
(require 'json)
(require 'subr-x)

(defgroup ikigai nil "Talk to the ikigai kernel from Emacs." :group 'tools)

(defcustom ikigai-program "ikigai"
  "The ikigai CLI executable (found on `exec-path')."
  :type 'string :group 'ikigai)

(defcustom ikigai-default-meeting-minutes 30
  "Default meeting length when a heading's timestamp carries no end time."
  :type 'integer :group 'ikigai)

(defcustom ikigai-mounts nil
  "Remote kernels to compose into every `ikigai-eval' call.
A list of plists, each `(:prefix PFX :target TGT :cert-dir DIR)', becoming
`--mount PFX=TGT --cert-dir DIR' on the ikigai command line.  Routing a
prefix to a daemon that holds the resource lets Emacs reach it through that
daemon's grants and cache instead of the (grant-less, cold) process Emacs
spawns.  On macOS calendar access is pinned to the launching app, so
`urn:personal:*' must resolve through the freebusy daemon, e.g.:

  (setq ikigai-mounts
        \\='((:prefix \"urn:personal:\"
            :target \"quic://localhost:4444\"
            :cert-dir \"~/.config/ikigai/quic/calendar\")))"
  :type '(repeat
          (plist :key-type symbol :value-type string
                 :options ((:prefix string) (:target string) (:cert-dir directory))))
  :group 'ikigai)

;;; --- the wrapper: call the kernel -------------------------------------------

(defun ikigai--mount-args ()
  "Build the `--mount'/`--cert-dir' flags from `ikigai-mounts'."
  (apply #'append
         (mapcar (lambda (m)
                   (append
                    (list "--mount" (format "%s=%s"
                                            (plist-get m :prefix)
                                            (plist-get m :target)))
                    (when-let ((dir (plist-get m :cert-dir)))
                      (list "--cert-dir" (expand-file-name dir)))))
                 ikigai-mounts)))

(defun ikigai--quote (s)
  "Escape S as an ikigai/Steel string literal (quotes and backslashes)."
  (concat "\"" (replace-regexp-in-string "[\"\\]" "\\\\\\&" s) "\""))

(defun ikigai-eval (command)
  "Run ikigai COMMAND (a resolution string or a Lisp form) via `ikigai -c'.
Return trimmed stdout on success; signal `user-error' with stderr on failure.
Cache tags (`[uncacheable]' etc.) go to stderr, so stdout stays clean."
  (let ((errfile (make-temp-file "ikigai-err")))
    (unwind-protect
        (with-temp-buffer
          (let ((status (apply #'call-process ikigai-program nil
                               (list (current-buffer) errfile) nil
                               (append (ikigai--mount-args) (list "-c" command)))))
            (if (eq status 0)
                (string-trim (buffer-string))
              (user-error "ikigai: %s"
                          (string-trim
                           (with-temp-buffer
                             (insert-file-contents errfile)
                             (buffer-string)))))))
      (delete-file errfile))))

(defun ikigai-invoke (verb uri &rest name-value)
  "Invoke URI with VERB (a symbol, e.g. `sink') and NAME-VALUE string pairs.
Builds `(invoke (quote VERB) \"URI\" \"n\" \"v\" ...)' so values with spaces are safe."
  (ikigai-eval
   (format "(invoke '%s %s %s)"
           verb (ikigai--quote uri)
           (mapconcat #'ikigai--quote name-value " "))))

;;; --- evaluate a resource reference from a buffer ----------------------------

(defun ikigai-eval-dwim (arg)
  "Evaluate the region (or the current line) as an ikigai command; show the result.
The result is also pushed onto the kill ring, so \\[yank] pastes it anywhere.
With a prefix ARG, insert the result into the buffer after point as well."
  (interactive "P")
  (let* ((cmd (string-trim
               (if (use-region-p)
                   (buffer-substring-no-properties (region-beginning) (region-end))
                 (thing-at-point 'line t))))
         (out (ikigai-eval cmd)))
    (kill-new out)
    (when arg
      (save-excursion (end-of-line) (insert "\n" out)))
    (message "%s%s" out (if arg "" "  (copied)"))
    out))

;;; --- meeting scheduling -----------------------------------------------------

(defun ikigai-schedule-zoom (topic start &optional minutes timezone)
  "Schedule a Zoom via `urn:meeting:zoom:schedule'.
TOPIC and START (ISO 8601, e.g. \"2026-07-30T22:00:00Z\") are required.
Return an alist parsed from the JSON envelope: `id', `join_url', `start_url',
`passcode', `start_time', `duration'."
  (let* ((args (append (list "topic" topic "start" start "as" "application/json")
                       (when minutes (list "duration" (number-to-string minutes)))
                       (when timezone (list "timezone" timezone))))
         (json (apply #'ikigai-invoke 'sink "urn:meeting:zoom:schedule" args)))
    (json-parse-string json :object-type 'alist :null-object nil)))

;;; --- the org command --------------------------------------------------------

(defun ikigai--org-when ()
  "Return (ISO-START . MINUTES) for the org entry at point.
ISO-START is UTC ISO-8601 from the heading's timestamp (or SCHEDULED).
MINUTES is the timestamp's own duration when it is a range (e.g.
12:00-13:00 yields 60), else nil so the caller supplies a default.
Signals if the heading has no timestamp."
  (let ((ts (or (org-entry-get (point) "TIMESTAMP")
                (org-entry-get (point) "SCHEDULED"))))
    (unless ts (user-error "This heading has no timestamp to meet at"))
    (let* ((start (org-time-string-to-time ts))
           (obj (ignore-errors (org-timestamp-from-string ts)))
           (h1 (and obj (org-element-property :hour-start obj)))
           (m1 (and obj (org-element-property :minute-start obj)))
           (h2 (and obj (org-element-property :hour-end obj)))
           (m2 (and obj (org-element-property :minute-end obj)))
           ;; A range only when an end time exists AND differs from the start.
           (minutes (when (and h1 m1 h2 m2 (or (/= h1 h2) (/= m1 m2)))
                      (let ((d (- (+ (* h2 60) m2) (+ (* h1 60) m1))))
                        ;; A range that crosses midnight (end < start) wraps a day.
                        (if (<= d 0) (+ d 1440) d)))))
      (cons (format-time-string "%Y-%m-%dT%H:%M:%SZ" start t) minutes))))

(defun ikigai--org-attendees ()
  "The heading's `:ATTENDEES:' property, prompting (and storing) if absent.
Returns a possibly-empty string of comma-separated addresses."
  (or (org-entry-get (point) "ATTENDEES")
      (let ((a (string-trim (read-string "Attendee emails (comma-separated, RET to skip): "))))
        (unless (string-empty-p a) (org-entry-put (point) "ATTENDEES" a))
        a)))

;;;###autoload
(defun ikigai-org-schedule-zoom (&optional minutes)
  "Schedule a Zoom for the org heading at point and file the join link.
Reads the heading title (topic) and its timestamp (start), and the
`:ATTENDEES:' property (prompting for emails if absent). Files the join
URL into the `:URL:' drawer (which ikigai-org emits as `ical:description',
so it rides to Brian-Busy) and the passcode into `:ZOOM_PASSCODE:'.
With a prefix arg, prompt for MINUTES.

Attendees are RECORDED, not yet emailed; sending them the link is a
later slice (it needs an ikigai invite-send resource)."
  (interactive (list (when current-prefix-arg
                       (read-number "Minutes: " ikigai-default-meeting-minutes))))
  (save-excursion
    (org-back-to-heading t)
    (let* ((topic (org-get-heading t t t t))
           (sched (ikigai--org-when))
           (start (car sched))
           ;; A prefix arg wins; else the timestamp's own range; else the default.
           (mins (or minutes (cdr sched) ikigai-default-meeting-minutes))
           (attendees (ikigai--org-attendees))
           (meeting (ikigai-schedule-zoom topic start mins))
           (join (alist-get 'join_url meeting))
           (pass (alist-get 'passcode meeting)))
      (unless (and join (stringp join) (not (string-empty-p join)))
        (user-error "Zoom returned no join URL: %S" meeting))
      (org-entry-put (point) "URL" join)
      (when (and pass (stringp pass) (not (string-empty-p pass)))
        (org-entry-put (point) "ZOOM_PASSCODE" pass))
      (message "Zoom scheduled: %s%s" join
               (if (string-empty-p attendees) ""
                 (format "  (attendees noted, invites not sent: %s)" attendees)))
      join)))

(provide 'ikigai)
;;; ikigai.el ends here
