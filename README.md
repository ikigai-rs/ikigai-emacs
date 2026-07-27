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
- **`ikigai-org-email-invite`** — once a heading has a Zoom (`:URL:` join link) and `:ATTENDEES:`,
  email each attendee a proper **iMIP calendar invite** (`METHOD:REQUEST`) via `urn:email:send`,
  carrying an RFC 5545 `VCALENDAR` as the `ics` argument — so their mail client shows an
  add-to-calendar / RSVP card, with the join link as an RFC 7986 `CONFERENCE` property. The event
  `UID` is the heading's org `:ID:` (created if absent), so re-sending *updates* the meeting rather
  than duplicating it. Delivery needs a reachable mailer: if this machine has no local SMTP, route
  `urn:email:` to one that does via `ikigai-mounts` (same pattern as the calendar mount).
- **`ikigai-eval-dwim`** — evaluate the region (or the current line) as an ikigai command; the result
  goes to the echo area *and* onto the kill ring (so `C-y` pastes it anywhere), or `C-u` also inserts
  it after point. E.g. a line reading `describe urn:meeting:zoom:schedule` → the endpoint's
  self-description, inline.

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
        '((:prefix "urn:personal:" :alias "urn:cal:"
           :target "quic://localhost:4444"
           :cert-dir "~/.config/ikigai/quic/calendar")))
  ```

  The `:alias` is load-bearing: a mount rewrites `<mount-prefix>rest` → `urn:rest` on the remote, so
  it can't win a prefix the *local* kernel already serves (it serves `urn:personal:`). The client
  mounts the remote at the non-colliding `:alias` and rewrites `urn:personal:` → `urn:cal:` on the
  wire, so you keep writing canonical `urn:personal:…` in buffers (errors echo the alias — that's the
  wire address). Keychain-backed resources (Zoom scheduling) need no mount — they key on the signing
  identity, not the launcher. (Prefix routing is also the seam URI completion will grow from: the
  daemon already knows its catalog.)

## Building blocks (for your own commands)

- `ikigai-eval` — run an ikigai command string via `ikigai -c`; clean stdout, errors surfaced.
- `ikigai-invoke` — `(ikigai-invoke 'sink "urn:…" "name" "value" …)`, which builds a Lisp
  `(invoke 'sink "urn:…" …)` so values with spaces are safe.
- `ikigai-schedule-zoom` — `topic`, `start` (ISO 8601) → the parsed meeting envelope (`join_url`,
  `passcode`, `id`, …).

## Status

Early, and useful. Working: ad-hoc Zoom scheduling from org (meetings not booked through the
website), and emailing the attendees a calendar invite. Next: contacts autocomplete for attendee
addresses; URI completion off the mounted daemon's catalog. Part of the ikigai ecosystem —
[ikigai-rs.dev](https://ikigai-rs.dev).

License: MIT OR Apache-2.0
