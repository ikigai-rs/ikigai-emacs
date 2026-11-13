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
| Last reviewed | 2026-11-12 |

## What it emits that people read

All of it is in `ikigai.el`:

- **The echo area.** `ikigai-eval-dwim` and `ikigai-eval-elisp-dwim` show the result (followed by
  `(copied)` without a prefix argument), and put the whole result on the kill ring; `ikigai-org-schedule-zoom` says `Zoom
  scheduled: <link>` and, when attendees are recorded, which command sends them an invitation;
  `ikigai-org-email-invite` says how many attendees the invitation went to and who they are;
  `ikigai-refresh-aliases` says how many aliases it loaded and from which file, and how many it
  skipped and removed. Emacs normally also logs these messages in `*Messages*`, subject to the user's
  `message-log-max` setting.
- **Errors** (`user-error`): a failed `ikigai` call is `ikigai: ` followed by the CLI's own stderr,
  with leading and trailing whitespace trimmed; the org commands say what is missing (`This heading has no timestamp to meet at`, `No
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
  `ansi-color-process-output`, so color the CLI sends would show. The client requests `--plain`;
  the CLI's actual output was not checked in this review.
- **Meaning is in words.** Counts are written out (`4 defined, 2 skipped, 0 removed`), each list
  in the report buffer has a heading that says what it is, and the confirmation before sending
  email is a full `yes-or-no-p` that names the recipients.
- **Keyboard only.** Every command is an interactive command reached by `M-x` or a key the user
  binds; nothing needs a mouse, and the package binds no key by default.
- **A result is not lost to the echo area.** A long result may be cut to the echo area's height,
  but the whole of it is put on the kill ring and inserted after point with `C-u`. Message
  logging depends on the user's Emacs settings.

These rules describe the client source. The checks below distinguish source inspection from
interactive use and do not establish accessibility of the CLI or a user's Emacs setup.

## How it is tested

Every named check has a result: Pass, Fail or Blocked. A Pass covers only the stated check,
not overall accessibility. Checks for this review ran on main at
`9b0f3f2a34767ddbb8f0f03a1ddf13e394142c6e` on 2026-11-12, before this documentation change.
Local tools: GNU Emacs 30.1, just 1.59.0 and ripgrep 15.2.0 on macOS 27.2.
CI repeats byte-compilation and ERT on Emacs 29.4 and 30.1 (`.github/workflows/ci.yml`).

| Check | Result | Evidence |
|---|---|---|
| Byte-compilation and ERT suite | Pass | `just gates` (Emacs 30.1, just 1.59.0): byte-compilation and all five tests in `test/ikigai-test.el`. Tests stub `ikigai-eval`; no live kernel, Zoom or mail delivery is exercised. |
| Alias report counts, skipped names and reaching calls, echo summary | Pass | Same `just gates` run: `ikigai-refresh-reports-skipped-names` checks the report's counts, skipped resource and reaching call, plus the summary returned for the echo area. `ikigai-refresh-quiet-when-nothing-skipped-or-removed` checks the plain summary. Does not test how Emacs displays or announces them. |
| Client-defined color, text labels, command entry points and result retention (source inspection) | Pass | Read `ikigai.el`, located with `rg -n -e interactive -e message -e user-error -e kill-new -e yes-or-no-p -e ansi-color -e plain -e When: ikigai.el` (ripgrep 15.2.0). No client-defined faces or active key bindings; report headings/counts and recipient confirmation use words; commands have interactive entry points; both evaluation commands copy results and support prefix insertion. This is source inspection, not a keyboard, contrast or assistive technology test. |
| Actionable errors and readable invitation time (source inspection) | Fail | Read `ikigai-eval`, `ikigai--org-when`, `ikigai-org-schedule-zoom` and `ikigai--invite-body` in `ikigai.el`, located by the same ripgrep command. Empty stderr leaves only `ikigai: `; missing join URL prints a Lisp list; missing timestamp gives no repair instruction; invitation time is UTC ISO 8601. These source findings remain limitations below, not a WCAG conformance determination. |
| Manual keyboard workflow | Blocked | No person performed an interactive pass through commands, minibuffer prompts, report navigation or the REPL in this review. Batch ERT and interactive declarations do not establish keyboard usability. |
| REPL input echo and live CLI plain output | Blocked | The `ikigai-repl-mode` source comment records an empirical batch-comint run against `ikigai --plain`; its run date, command and tool versions were not recorded. The previous accessibility review is dated 2026-10-31; that is not a recorded date for the empirical run. CI does not repeat that run; no live CLI run was performed for this update. |
| Theme contrast, text enlargement and display behavior | Blocked | No interactive Emacs theme, contrast, text-scaling or long-output display pass was performed. User themes and CLI ANSI output affect presentation. |
| Automated accessibility checker or browser evaluation | Blocked | No automated accessibility checker or browser has been used on this output in this review; none is configured by this repository. ERT is not an accessibility checker. Markdown rendering and mail/calendar presentation were not evaluated. |
| Screen reader | Blocked | No Emacspeak or system screen reader session was used for commands, prompts, reports or the REPL; no screen reader session was available for this update. |
| Screen magnifier | Blocked | No screen magnifier session was used or available for this update. |
| Speech input | Blocked | No speech-input session was used or available for this update. |
| Switch access | Blocked | No switch-access session was used or available for this update. |
| Braille display | Blocked | No braille display was used or available for this update. |

## Known limitations

Found by reading the source on 2026-10-31 and rechecked on 2026-11-12, not by testing with
people or assistive technology:

- A failed `ikigai` call whose stderr is empty reports `ikigai: ` and nothing else: it names
  neither the command that failed nor its exit status.
- `Zoom returned no join URL: …` prints the answer as a raw Lisp list.
- `This heading has no timestamp to meet at` does not say what to add (an active timestamp or
  `SCHEDULED`).
- The invitation's plain-text body gives the start as an ISO 8601 time in UTC
  (`2026-07-30T22:00:00Z (UTC)`), not in the reader's time zone or in words, so the reader converts
  it.
- The REPL buffer renders any ANSI color it receives and does not consult `NO_COLOR`; the CLI's
  `--plain` is requested but was not verified here. Emacs's own `ansi-color-for-comint-mode` can
  filter ANSI color.

## Contributing

Read this file before changing any output listed above: a message, a prompt, a buffer's text or
the invitation. Keep meaning in words, define no color that carries meaning alone, and keep every
command reachable from the keyboard. In the pull request, give each check a
`Check | Result | Evidence` table row with Pass, Fail or Blocked and its test or command, tool
and version, or why it could not run. Keep unrun checks as Blocked, including assistive
technology nobody used. A historical run CI does not repeat is Blocked with its date (or an
explicit statement that the date was not recorded), never a current Pass.

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
| 2026-11-12 | Record Pass, Fail and Blocked evidence, scope and unrun assistive technology checks; recheck source limitations. |
