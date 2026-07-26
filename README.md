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
  `describe urn:meeting:zoom:schedule` → the endpoint's self-description, inline.

  Quick grammar (the kernel tells you if you get it wrong): a **template** parameter goes *in the
  IRI* (`urn:personal:availability:today`, `…:2026-08`); a **by-value** arg is *space-separated*
  `key=value` (`source urn:fn:toUpper in=hello`) — **not** `?key=value` (the `?k=v` form is only for
  compose contexts like `with=…?as=text/turtle`).

  **Note on calendar/TCC-gated resources.** macOS attributes calendar access to the *launching* app,
  so an `ikigai` spawned by Emacs runs under Emacs's (absent) grant, not the daemon's — `source
  urn:personal:availability:week` would otherwise report "calendar access was denied." Route those
  *through the daemon* with `ikigai-mounts`, which composes a remote kernel at a URN prefix on every
  call — so the freebusy daemon (which holds the grant *and* caches the result) answers, not the cold
  local process:

  ```elisp
  (setq ikigai-mounts
        '((:prefix "urn:personal:"
           :target "quic://localhost:4444"
           :cert-dir "~/.config/ikigai/quic/calendar")))
  ```

  Keychain-backed resources (Zoom scheduling) need no mount — they key on the signing identity, not
  the launcher. (Prefix routing is also the seam URI completion will grow from: the daemon already
  knows its catalog.)

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
