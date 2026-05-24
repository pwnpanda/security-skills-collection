---
name: cors-misconfiguration
description: >-
  Use when authorized testing involves cross-origin response headers -
  Access-Control-Allow-Origin, Access-Control-Allow-Credentials, preflight
  handling, exposed headers, allowed methods, or origin allowlists that may
  reflect or weakly match attacker origins.
---

# CORS Misconfiguration

CORS bugs matter when an authenticated user's data is reachable from a
malicious origin's JavaScript. The bug is almost always a permissive
`Access-Control-Allow-Origin` (especially reflected) combined with
`Access-Control-Allow-Credentials: true`.

## Workflow

1. Read `../../references/scope-safety.md` and the Security
   Misconfiguration, CORS, And Host Headers section of
   `../../references/high-signal-must-tests.md`.
2. Enumerate every cross-origin-relevant endpoint: authenticated APIs,
   user-data endpoints, settings, billing, exports, search.
3. Test which `Origin` values are allowed: arbitrary attacker origins,
   `null`, registered partners, regex/suffix matches.
4. For each accepted origin, check whether
   `Access-Control-Allow-Credentials: true` is also returned.
5. Validate impact with an owned attacker page reading owned user data
   from the program (cross-origin fetch).
6. Write findings with `../../references/finding-output.md`. State the
   exact origin acceptance pattern and the data class exposed.

## Where To Look

- All authenticated APIs that return user-specific data: profile,
  settings, billing, payment methods, addresses, ticket history, file
  lists, search results, notifications.
- Public-but-cookie-authenticated endpoints (often part of mobile
  bootstrap or feature-flag APIs).
- Subdomain-level CORS allowlists shared with marketing/preview/staging
  domains; can a marketing-domain XSS pivot into app data via CORS?
- API gateways and reverse proxies that add CORS headers independently
  of the upstream app.

## Common Patterns

- `Access-Control-Allow-Origin` reflects the request `Origin` for any
  value, combined with `Allow-Credentials: true`.
- Origin allowlist by suffix: `endsWith(".example.com")` matched by
  `example.com.evil.example`.
- Origin allowlist by substring: matched by attacker-controlled subpath.
- `null` origin allowed (sandboxed iframes, `file://`, redirected
  fetches produce `Origin: null`).
- Wildcard `*` with credentials - browsers reject the combo, but some
  servers respond with both, indicating a configuration error worth
  reporting separately.
- Preflight cache (`Access-Control-Max-Age`) holds a permissive answer
  for an attacker for hours.

## Protection And Bypass Themes

- Test with `Origin: null` from a sandboxed iframe or `data:` URL.
- Test with `Origin: https://attacker.example` (exact attacker origin).
- Test suffix/substring confusion: `https://app.example.com.attacker.example`,
  `https://attacker.example/app.example.com`.
- Test scheme mismatch (`http://` vs `https://`).
- For API gateways, check whether the upstream's CORS policy is
  shadowed by the gateway's, and whether internal headers are exposed.

## Safe Validation

- Two owned user accounts and an attacker page on a domain you own.
  Have the victim browser log in to the program, then load the attacker
  page and prove cross-origin fetch reads private data.
- Do not target real users. Do not exfiltrate beyond the smallest
  proof-of-read.

## Anti-Patterns

- Reporting `Allow-Origin: *` on a public endpoint that returns only
  public data - no impact.
- Reporting reflected `Allow-Origin` without `Allow-Credentials: true`
  unless the endpoint exposes user data via a non-cookie auth that the
  browser sends automatically.
- Reporting CORS as the cause of a CSRF; CORS does not prevent CSRF -
  see `../csrf/SKILL.md`.
