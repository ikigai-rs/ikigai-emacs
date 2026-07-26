# ikigai-emacs

A thin Emacs client for the [ikigai](https://ikigai-rs.dev) kernel — a command surface over the
resource fabric. It shells to the `ikigai` CLI and nothing heavier: a bounded front-end, not a fork
of anything. Emacs becomes a two-way ikigai surface — run resources from a buffer, and act on your
notes/agenda through the kernel.

## Install

Requires the `ikigai` CLI on your `exec-path`. Clone and load:

```elisp
(add-to-list 'load-path "/path/to/ikigai-emacs")
(require 'ikigai)

(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c z") #'ikigai-org-schedule-zoom))
(global-set-key (kbd "C-c i e") #'ikigai-eval-dwim)
```

## Commands

- **`ikigai-org-schedule-zoom`** — on an org heading that has a timestamp but no meeting, schedule a
  Zoom via `urn:meeting:zoom:schedule`, prompt for `:ATTENDEES:` if the property is absent, and file
  the join link into the `:URL:` drawer (which `ikigai-org` emits as `ical:description`, so it rides
  to your derived calendar) and the passcode into `:ZOOM_PASSCODE:`. Duration comes from a ranged
  timestamp (`<… 12:00-13:00>` → 60 min), else `ikigai-default-meeting-minutes` (30); a prefix arg
  overrides. **Run it where the Zoom credentials live** (the schedule call reads them from the
  keystore).
- **`ikigai-eval-dwim`** — evaluate the region (or the current line) as an ikigai command; the result
  goes to the echo area, or `C-u` inserts it after point. E.g. a line reading
  `source urn:personal:availability:week` → your freebusy, inline. (Template endpoints capture their
  parameter *in the IRI* — `…:today`, `…:2026-08` — while by-value args are `key=value`; the kernel
  tells you which if you get it wrong.)

## Building blocks (for your own commands)

- `ikigai-eval` — run an ikigai command string via `ikigai -c`; clean stdout, errors surfaced.
- `ikigai-invoke` — `(ikigai-invoke 'sink "urn:…" "name" "value" …)`, which builds a Lisp
  `(invoke 'sink "urn:…" …)` so values with spaces are safe.
- `ikigai-schedule-zoom` — `topic`, `start` (ISO 8601) → the parsed meeting envelope (`join_url`,
  `passcode`, `id`, …).

## Status

Early, and useful. First feature: ad-hoc Zoom scheduling from org (meetings not booked through the
website). Next: emailing the attendees an invite with the link; contacts autocomplete for their
addresses. Part of the ikigai ecosystem — [ikigai-rs.dev](https://ikigai-rs.dev).

License: MIT OR Apache-2.0
