---
name: xs-leaks
description: >-
  Use when authorized testing involves cross-site oracles - frame counting,
  error/load event timing, redirect oracles, COEP/COOP gaps, history
  length, Performance API timing, Cache API probes, or any browser-side
  side channel that leaks one bit of information about a victim's
  authenticated state on the target.
---

# XS-Leaks

Cross-site leaks (XS-Leaks) are oracles: bits of information about a
victim's session on a target that an attacker page in another origin can
observe through browser side channels. The classic primitives are frame
counting, load/error event timing, and Performance API entries. Impact
ranges from search-query disclosure to two-factor enumeration to
account-takeover preconditions when combined with other bugs. The
xsleaks.dev wiki catalogues the technique family.

## Workflow

1. Read `../../references/scope-safety.md` and the Cross-Site Scripting
   and access-control sections of
   `../../references/high-signal-must-tests.md`.
2. Identify candidate authenticated endpoints that *return different
   behaviour* based on the victim's state - search endpoints, profile
   endpoints, "did you mean" autocomplete, item-existence checks, MFA
   challenges, role-based content.
3. For each, look for a browser-observable side channel that reflects
   the difference:
   - **Frame count** (`window.length`) after loading the target in an
     iframe or popup.
   - **Load vs error event** when embedded as `<img>`, `<script>`,
     `<iframe>`, or `<link rel=stylesheet>`.
   - **Timing** of cross-origin requests via the Performance API or
     `fetch` timing.
   - **Redirect chain length** via `history.length` in a popup the
     attacker opened.
   - **COOP/COEP** behaviour: a missing `Cross-Origin-Opener-Policy`
     leaks the popup reference; a missing `Cross-Origin-Embedder-Policy`
     allows embedding.
   - **Cache probes**: prime the cache, observe whether the victim's
     next visit hits or misses.
4. Build an owned attacker page that probes the oracle and infers one
   bit per probe. Aggregate bits to disclose the underlying state.
5. Validate with owned victim and attacker accounts. Stop at one
   disclosed bit per finding.
6. Write findings with `../../references/finding-output.md`. State the
   oracle, the bit disclosed, and the impact (search query, friend
   list membership, role, etc.).

## Where To Look

- Search and autocomplete endpoints that return different result
  counts for matching vs non-matching queries.
- "User exists" or "email already registered" pre-checks that respond
  differently for known vs unknown identifiers.
- Item-existence checks under a path (e.g. invoice IDs, ticket IDs).
- MFA challenge endpoints that reveal whether the user has 2FA
  enabled.
- Role-conditional UI that loads more frames or scripts for admins.
- Authenticated downloads that succeed/fail based on permission.

## Common Patterns

- Endpoint returns a JSON response with `Content-Type:
  application/json` but missing CORS protection - cross-origin
  `<script>` inclusion fails differently (script onerror vs script
  parse error) depending on content.
- Endpoint sets a cookie or header that triggers a redirect when the
  user is logged out; iframe load timing differs.
- 200 vs 404 vs 403 leaks via `Content-Length` size differences
  observable via `<img>` natural width or Performance timing.
- Authenticated page contains N iframes when the user is in role X
  and M iframes when not.
- `Cross-Origin-Opener-Policy: same-origin` missing on the auth flow,
  so attacker popup keeps the reference and probes
  `popup.length`.

## Protection And Bypass Themes

- For frame counting, open the target in an iframe (if framing is
  allowed) or a popup (if COOP permits). Read `iframe.contentWindow.
  length` or `popup.length`.
- For redirect oracles, open the target in a popup and observe
  `popup.location` access errors (cross-origin) vs success (same-
  origin); the path length or final document title may leak.
- For Performance API oracles, use
  `performance.getEntriesByType('resource')` to read timing of
  cross-origin fetches the target page triggered.
- For cache oracles, prime the cache via a victim-triggered request
  and time a subsequent cross-origin request from the attacker
  context.
- COOP, COEP, CORP, and `Origin-Agent-Cluster` are the modern
  defences - check whether the target ships them on auth-sensitive
  paths.

## Safe Validation

- Owned attacker domain hosting the probe page. Owned victim browser
  with a known state. Probe to disclose one bit, then stop.
- Do not deploy the oracle against real users.
- For impact illustration, show the bit and explain its security
  meaning rather than enumerating many bits.

## Anti-Patterns

- Reporting "Cross-Origin-Opener-Policy not set" without an exploit
  that uses the missing header.
- Building large oracle chains that disclose many fields when one
  disclosed bit already proves the class.
- Confusing XS-Leaks with CORS; CORS controls cross-origin *read*,
  XS-Leaks measure side channels that exist regardless.
