---
name: open-redirect
description: >-
  Use when authorized testing involves features that accept a destination URL,
  path, route, callback, or return location - login/logout returns, OAuth
  redirect_uri, SAML RelayState, password reset/invite/verification links,
  link shorteners, payment/download/share redirects, marketing links, or any
  SSRF-capable URL fetcher that follows redirects after validation.
---

# Open Redirect

Open redirect is not a top-line OWASP category, but it is a top-line bug-bounty
finding because it chains into account takeover, OAuth code/token theft, SSRF
allowlist bypass, phishing impact, and CSP/CSRF assumption breaks.

## Workflow

1. Read `../../references/scope-safety.md` and the Open Redirects section of
   `../../references/high-signal-must-tests.md`.
2. Enumerate every parameter, header, JSON field, or path segment that
   eventually causes an HTTP 3xx, a `Location` header, a meta-refresh, a
   client-side `window.location` assignment, or a server-side fetcher to
   follow a user-supplied URL.
3. For each candidate, classify the surface: server-side 3xx, server-side
   internal fetcher, client-side navigation, or downstream OAuth/SAML
   continuation.
4. Test allowlist, denylist, encoding, scheme, host, path, userinfo,
   fragment, and final-URL-after-redirect handling.
5. Decide whether the impact is standalone (phishing) or a chain (OAuth
   token theft, SSRF bypass, CSP/CSRF assumption break).
6. Validate with self-owned destinations and a unique marker. Do not collect
   tokens or third-party data.
7. Write findings with `../../references/finding-output.md`. State both the
   redirect primitive and the chain (or absence of chain).

## Where To Look

- Authentication flows: login `next`/`return_to`, logout redirect,
  registration confirm, invite acceptance, email verification, password
  reset, MFA continuation.
- OAuth/OIDC/SAML: `redirect_uri`, `RelayState`, `state`, callback,
  post-logout redirect, federation continuation.
- Commerce and content: payment checkout return, download link, link
  shortener, "open in app" deeplink, marketing tracker, support article
  links.
- SSRF-capable URL fetchers that revalidate after redirects (webhook,
  importer, link preview - see `../blind-ssrf/SKILL.md`).
- High-signal parameter names: `redirect`, `redirect_url`, `redirect_uri`,
  `return`, `return_to`, `next`, `url`, `target`, `destination`, `continue`,
  `callback`, `goto`, `RelayState`, `back`, `r`, `u`, `to`, `forward`,
  `dest`, `success_url`, `cancel_url`.

## Common Patterns

- Suffix or substring allowlist: `endsWith("trusted.com")` matched by
  `trusted.com.evil.example`; `contains("trusted.com")` matched by
  `evil.com/trusted.com`.
- Path-based redirects that become external after URL decoding,
  normalization, or proxy rewriting.
- Allowlist applied to the input URL but not to the final URL after a
  followed redirect.
- Scheme-based allowlist that only checks `http`/`https` and misses
  `javascript:`, `data:`, or app-specific schemes in client-side sinks.
- Validator and fetcher use different URL parsers.

## Protection And Bypass Themes

- Absolute URLs, scheme-relative `//evil.example`, protocol-relative with
  whitespace `/\\evil.example`, backslashes, encoded slashes (`%2F`,
  `%252F`), and double-encoded values.
- Userinfo syntax: `https://trusted.com@evil.example`.
- Fragments and query-string smuggling: `https://trusted.com#@evil.example`,
  `https://trusted.com?@evil.example`.
- Mixed-case schemes (`HtTpS://`), trailing dots (`evil.example.`), IDNA
  homographs, and Unicode normalization.
- Path-segment traversal that climbs above an enforced prefix.
- For OAuth `redirect_uri`, test exact match vs prefix match vs registered-
  base match; chain into code/token theft when prefix matching is used.

## Safe Validation

- Self-owned destination domain with a unique-per-test marker subpath or
  query.
- Prove redirect-control only - do not collect cookies, OAuth codes, or
  tokens that belonged to the program's users.
- For OAuth chains, use an attacker-controlled client/account; do not
  redirect real users.

## Anti-Patterns

- Reporting a `javascript:` URL accepted in a `Location` header as XSS.
  Browsers do not execute `Location: javascript:`. Look for client-side
  sinks instead.
- Reporting an internal allowlisted redirect as a finding when the only
  reachable destination is also program-owned.
- Sending real victims through your proof-of-concept URL.
