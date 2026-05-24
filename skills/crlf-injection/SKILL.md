---
name: crlf-injection
description: >-
  Use when authorized testing involves user input that may reach HTTP
  response headers, log entries, structured log fields, or any output where
  carriage-return / line-feed could split a record - Location/Set-Cookie
  headers built from request data, redirect handlers, log4j-style logging,
  CSV/JSON line exports, JSONL pipelines, or audit-trail fields. For SMTP/
  email header injection use `../email-testing/SKILL.md`; for HTTP request
  smuggling between proxies use `../request-smuggling/SKILL.md`.
---

# CRLF Injection

CRLF injection is the family of bugs where attacker-controlled `\r\n`
sequences split a record that the consumer treats as line-oriented. In
HTTP responses this becomes response splitting and Set-Cookie injection;
in log pipelines it becomes log forging or log4j-style misparses; in
JSONL/CSV it becomes record smuggling.

## Workflow

1. Read `../../references/scope-safety.md` and the Security
   Misconfiguration, CORS, And Host Headers section of
   `../../references/high-signal-must-tests.md`.
2. Enumerate sinks where user input lands in a line-oriented format:
   redirect handlers building `Location:`, cookie-setting endpoints,
   custom headers built from request fields, log lines, JSONL streams,
   CSV exports.
3. Test with raw CRLF (`\r\n`), URL-encoded `%0d%0a`, double-encoded
   `%250d%250a`, mixed-encoded, and Unicode line separators (U+2028,
   U+2029, U+0085).
4. For HTTP response splitting, inject a second header
   (`Set-Cookie:`, `Content-Length:`) or a full response body after
   the split.
5. Validate with owned accounts and a unique marker; observe both the
   raw response and any downstream consumer (cache, proxy, browser).
6. Write findings with `../../references/finding-output.md`. State the
   exact sink, the consumer that misparsed, and the security boundary
   that was crossed.

## Where To Look

- Redirect handlers that build `Location:` from a query parameter
  (`?next=`, `?return_to=`, `?url=`).
- Set-Cookie endpoints that take a cookie name or value from request
  input (auth callbacks, A/B test endpoints, language switchers).
- Custom response headers built from request fields:
  `X-Custom-User`, debug headers, language headers,
  `Content-Disposition` filename from user input.
- Application log lines: any field logged without sanitisation (search
  query, login username, error message, user agent).
- JSONL or CSV export pipelines where a user field becomes a row.
- Audit-trail writers that store user input as a structured-log row.
- Reverse-proxy header passthrough where the app concatenates header
  values from the request.

## Common Patterns

- Framework helper `redirect(user_input)` that does not strip CR/LF
  from the destination.
- Cookie setter that interpolates a name from `?lang=` directly.
- Logger that takes a string and writes one line per record without
  escaping embedded newlines.
- Custom error-page handler that echoes the request path into a
  header for debugging.
- CSV exporter that joins user fields with `,` and rows with `\n`
  without quoting/escaping fields containing newlines.

## Protection And Bypass Themes

- Try raw `\r\n`, then variants: `\r`, `\n`, `\r\r\n`, `\n\r`,
  `\xc4\x8a` style overlongs, Unicode line separators U+2028 / U+2029
  / U+0085 (NEL), vertical tab `\v`, form feed `\f`.
- Try double-encoding for layers that decode twice: `%250d%250a`,
  `%%30d%%30a`.
- For Location-header splitting, inject a complete response
  (`%0d%0aSet-Cookie: attacker=1` or `%0d%0aContent-Length: 0%0d%0a%0d%0a
  HTTP/1.1 200 OK%0d%0aContent-Type: text/html%0d%0aContent-Length:
  20%0d%0a%0d%0a<script>...`).
- For log injection, inject a forged record that downstream parsers
  treat as a real log line - useful for hiding malicious activity or
  framing other users.
- Modern frameworks usually strip CR/LF from response headers; the bug
  often lives in a wrapper or custom helper that bypasses the framework
  protection.
- WAFs commonly block raw CR/LF; encoded and Unicode variants frequently
  bypass.

## Safe Validation

- For Location splitting, prove with a single injected `Set-Cookie:
  marker=<uuid>` and observe the cookie set on an owned session - no
  full response-body smuggling, no XSS payload.
- For Set-Cookie injection, set a cookie scoped to your owned subpath
  only.
- For log forging, write one labelled forged line, screenshot or copy
  the log entry, and stop.
- For CSV/JSONL injection, prove that a downstream parser splits the
  record; do not include payloads that execute when the export is
  opened (e.g. CSV formula injection is its own class).

## Anti-Patterns

- Spraying CRLF payloads at every parameter and reporting every
  echo as a finding. The bug is when the consumer *splits* on the
  injected newline.
- Reporting Location-header echo without confirming the response
  actually splits in a browser or proxy.
- Confusing CRLF injection with request smuggling (server-to-server
  parser disagreement) - those are separate classes; see
  `../request-smuggling/SKILL.md`.
- Crashing log pipelines or exhausting log storage as "proof" of
  injection.
