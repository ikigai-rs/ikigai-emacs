# Accessibility

What `ikigai-emacs` shows that people read (Emacs buffers, the echo area, minibuffer prompts, and
the plain-text invitation it emails), the rules that output follows, how it is tested, and how to
report a barrier. It is not a conformance claim. Adapted from the
[ACCESSIBILITY.md template](https://github.com/mgifford/ACCESSIBILITY.md) (MIT).

| Field | Value |
|---|---|
| Target | WCAG 2.2 Level AA, for any page that presents this output; this repository writes no HTML or SVG, only text in Emacs and in email |
| Status | Evaluation in progress. No conformance claim. |
| Owner | the maintainers of this repository |
| Report a barrier | [a GitHub issue](https://github.com/ikigai-rs/ikigai-emacs/issues/new?labels=accessibility) with the `accessibility` label; anything security-sensitive through [private vulnerability reporting](https://github.com/ikigai-rs/ikigai-emacs/security/advisories/new) |
| Last reviewed | 2026-10-31 |

## What it emits that people read

All of it is in `ikigai.el`:

- **The echo area.** `ikigai-eval-dwim` and `ikigai-eval-elisp-dwim` show the result followed by
  `(copied)`, and put the whole result on the kill ring; `ikigai-org-schedule-zoom` says `Zoom
  scheduled: <link>` and, when attendees are recorded, which command sends them an invitation;
  `ikigai-org-email-invite` says how many attendees the invitation went to and who they are;
  `ikigai-refresh-aliases` says how many aliases it loaded and from which file, and how many it
  skipped and removed. Every `message` is also kept in Emacs's `*Messages*` buffer.
- **Errors** (`user-error`): a failed `ikigai` call is `ikigai: ` followed by the CLI's own stderr,
  verbatim; the org commands say what is missing (`This heading has no timestamp to meet at`, `No
  Zoom link in :URL: — run ikigai-org-schedule-zoom first`, `No :ATTENDEES: on this heading to
  invite`, `Zoom returned no join URL: …`).
- **Minibuffer prompts**: `Attendee emails (comma-separated, RET to skip): `, `Minutes: ` (with a
  prefix argument), and a `yes-or-no-p` confirmation, `Email an invite to N attendee(s): …? `,
  that names every address before anything is sent.
- **Buffers**: `*ikigai-aliases*`, a read-only `special-mode` report of what a refresh defined,
  skipped and removed, each skipped name with the `ikigai-invoke` call that still reaches it; and
  `*ikigai*`, the REPL, a `comint-mode` buffer over `ikigai --plain` with a read-only `ikigai> `
  prompt.
- **The invitation email** (`ikigai--invite-body`, `ikigai--ics-invite`): a plain-text body (the
  topic, `When: <start> (UTC)`, the join link, the passcode) and an RFC 5545 calendar attachment.

Not this repository's: the text inside a result, an error's stderr and the REPL's output (the
`ikigai` CLI's), the generated aliases file and the reasons a name was skipped (the CLI writes
them), and how a mail or calendar client presents the invitation.

## The rules that output follows

- **No color or face of its own.** The package defines no face and writes no color; buffers and
  the echo area look as the user's Emacs theme says. The REPL buffer renders ANSI escapes with
  `ansi-color-process-output`, so color the CLI sends would show, but the CLI's `--plain` REPL
  writes none.
- **Meaning is in words.** Counts are written out (`4 defined, 2 skipped, 0 removed`), each list
  in the report buffer has a heading that says what it is, and the confirmation before sending
  email is a full `yes-or-no-p` that names the recipients.
- **Keyboard only.** Every command is an interactive command reached by `M-x` or a key the user
  binds; nothing needs a mouse, and the package binds no key by default.
- **A result is not lost to the echo area.** A long result may be cut to the echo area's height,
  but the whole of it is on the kill ring, in `*Messages*`, and inserted after point with `C-u`.

These are followed by reading the source; only the report buffer's wording is pinned by a test.

## How it is tested

- `test/ikigai-test.el` (ERT, in batch, no kernel): `ikigai-refresh-reports-skipped-names` pins the
  report buffer's counts line, a skipped name's line and its reaching call, and the echo-area
  summary; `ikigai-refresh-quiet-when-nothing-skipped-or-removed` pins the plain summary when there
  is nothing else to say. CI byte-compiles the package and runs the suite on Emacs 29.4 and 30.1.
- **No automated accessibility checker, browser or assistive technology has been used on this
  output.** In particular, no Emacs screen reader (Emacspeak, or a system screen reader reading
  Emacs) has been used with these commands or the REPL buffer.

## Known limitations

Found by reading the source on 2026-10-31, not by testing with people or assistive technology:

- A failed `ikigai` call whose stderr is empty reports `ikigai: ` and nothing else: it names
  neither the command that failed nor its exit status.
- `Zoom returned no join URL: …` prints the answer as a raw Lisp list.
- `This heading has no timestamp to meet at` does not say what to add (an active timestamp or
  `SCHEDULED`).
- The invitation's plain-text body gives the start as an ISO 8601 time in UTC
  (`2026-07-30T22:00:00Z (UTC)`), not in the reader's time zone or in words, so the reader converts
  it.
- The REPL buffer renders any ANSI color it receives and does not consult `NO_COLOR`; the CLI's
  `--plain` sends none today, and Emacs's own `ansi-color-for-comint-mode` can filter it.

## Contributing

Read this file before changing any output listed above: a message, a prompt, a buffer's text or
the invitation. Keep meaning in words, define no color that carries meaning alone, and keep every
command reachable from the keyboard. Say in the pull request what was tested, with what, and what
was not.

## Reporting a barrier

[Open an issue](https://github.com/ikigai-rs/ikigai-emacs/issues/new?labels=accessibility) with the
`accessibility` label (the link sets it when GitHub lets you add labels; otherwise a maintainer
adds it): what you were doing, what happened, and your Emacs version and any assistive technology,
if you are comfortable sharing them. Anything security-sensitive goes through
[private vulnerability reporting](https://github.com/ikigai-rs/ikigai-emacs/security/advisories/new).
**We acknowledge a report within 7 days**, and promise nothing further.

## Change history

| Date | Change |
|---|---|
| 2026-10-31 | First version. |
