---
name: command-injection
description: >-
  Use when authorized testing involves server-side code that wraps a system
  command around user input - image conversion, video transcoding, archive
  extraction, hostname/DNS lookups, git/svn operations, shell wrappers in
  APIs, scheduled-task strings, or any endpoint that may shell out.
---

# Command Injection

Command injection happens when user input lands in a shell, subprocess
argument list, or interpreter command line. The bug is almost always one of:
shell-string interpolation, argument-list construction with a flag that
re-enables shell behavior, or a wrapper around a tool whose own parser
accepts injected operators.

## Workflow

1. Read `../../references/scope-safety.md` and the Injection section of
   `../../references/high-signal-must-tests.md`.
2. Enumerate every input that might reach a subprocess: filenames, URLs,
   hostnames, repo URLs, image dimensions, conversion options, cron
   expressions, command names.
3. Classify the sink: shell (`/bin/sh -c "..."`), argv list, interpreter
   eval, library that internally shells out (ImageMagick, ffmpeg,
   LibreOffice, Ghostscript, git, gzip wrappers).
4. Choose probes appropriate to the sink: shell metacharacters,
   argument-injection flags, tool-specific operators (e.g.
   `--upload-pack=` in git, `-define` in ImageMagick, `-config` in OpenSSL).
5. Validate blind execution with an OAST callback (`../oast-testing/
   SKILL.md`) or a deterministic timing oracle.
6. Write findings with `../../references/finding-output.md`. State the
   sink, the parser layer that accepted the injection, and the privilege
   it ran with.

## Where To Look

- Image/video/document conversion features and any endpoint that takes a
  URL to fetch and convert.
- Repo-URL inputs (git clone, svn checkout, hg clone), package URLs, npm
  install URLs, container image references.
- Hostname/IP lookup, ping, traceroute, DNS query, whois, certificate
  fetch, port check.
- Backup/export jobs that build shell pipelines, log archival, scheduled-
  task strings, cron-style entries.
- Admin or "advanced" fields that pass through a templating step into a
  command line.

## Common Patterns

- Python `subprocess.run(cmd, shell=True)` or Node.js `exec` from
  `child_process` with concatenated user input.
- Argv-list construction that still allows the called tool's own option
  parser to interpret a leading `-` or `--` in user input as a flag
  (argument injection).
- Library wrappers (e.g. ImageMagick `-process`/`-define`, git
  `--upload-pack`, curl `-K`, ssh `-o ProxyCommand=`).
- Filename or URL with shell metacharacters reaching a logging or
  archival shell pipeline later.

## Protection And Bypass Themes

- Shell metacharacters: `;`, `&`, `&&`, `|`, `||`, backticks, `$()`,
  `\n`, `\r`, glob characters, redirections `<`/`>`.
- IFS abuse, brace expansion, parameter expansion, here-strings.
- For argv-only sinks, look for argument injection: `--`, `-T`, `-o`,
  `--upload-pack=`, `--config=`, depending on tool.
- For tools with their own DSL: ImageMagick's `MSL`/`-process`,
  Ghostscript PostScript, Pandoc raw HTML, ffmpeg `concat:`.
- Validation that strips known characters but not Unicode lookalikes,
  long-form options, or environment-variable expansion.

## Safe Validation

- Prefer OAST callbacks over command output. A DNS lookup to your
  callback domain is proof; reading `/etc/passwd` is over-proof.
- For sleep/timing oracles, use bounded sleeps (1-5 seconds) and stop
  after one confirmation.
- Do not start reverse shells, persist artifacts, install packages, or
  modify production state.

## Anti-Patterns

- Spraying `;id` and expecting visible output. Most modern apps suppress
  stdout; use blind proof instead.
- Reporting an argv-style subprocess call as command injection without a
  tool-specific argument-injection vector.
- Pivoting from confirmed RCE into internal scanning, secret retrieval,
  or persistence.
