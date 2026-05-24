---
name: client-side-path-traversal
description: >-
  Use when authorized testing involves client-side code that builds API
  request paths, fetch/XHR URLs, GraphQL operation names, websocket
  subscription IDs, or any client-built URL where attacker-controlled input
  is concatenated into a path segment. Use for CSPT discovery, impact chains
  (JSON injection, response-body confusion, ATO via OAuth redirect rewrites,
  cache poisoning), and safe validation.
---

# Client-Side Path Traversal (CSPT)

CSPT is a client-side bug where attacker input flows through JavaScript into
the *path* portion of a same-origin request the browser then makes. Unlike
server-side path traversal, the goal is rarely file read - it is to redirect
the client to a *different API endpoint* whose response then drives a
sensitive action (state update, redirect, token exchange, render).

## Workflow

1. Read `../../references/scope-safety.md` and the XSS, access-control, and
   open-redirect sections of `../../references/high-signal-must-tests.md`.
2. Map every client source that feeds a path: query string, fragment,
   `postMessage`, local/session storage, server-supplied JSON, URL path
   segments parsed by the client router, websocket messages.
3. Identify sinks: `fetch`, `XMLHttpRequest`, `axios`/`ky`/`got`-style
   helpers, generated SDK calls, `Image().src` for tracking, `<link rel=>`
   prefetch, service-worker `caches.match`, websocket subscribe URLs.
4. For each (source, sink), trace whether the user input lands in a path
   segment without canonicalization. `/api/users/${id}/profile` where `id`
   accepts `..%2F` or `..%5C` is the canonical CSPT shape.
5. Build a chain: which API endpoint can the client be tricked into calling
   instead? What does the client *do* with the response? Common impact
   chains: account takeover via OAuth callback rewriting, JSON response
   confusion (response from endpoint A interpreted as schema B), cache
   poisoning via service worker, CSRF-token disclosure.
6. Validate with owned accounts and harmless target endpoints; confirm the
   client made the diverted request and reacted to its response.
7. Write the finding with `../../references/finding-output.md`. Include the
   source-to-sink trace, the diverted endpoint, the client behavior on the
   diverted response, and the security boundary that was crossed.

## Where To Look

- Single-page apps using path templates like `/api/${tenant}/users/${id}`
  with values from query string, hash, or server JSON.
- OAuth/OIDC clients that build callback paths from response fields, query
  parameters, or `state`.
- Generated API SDKs and OpenAPI clients that string-concatenate path
  parameters without URL-encoding.
- Service workers that intercept and rewrite paths based on URL parts.
- Mobile WebViews bridging native data into web fetches.
- Analytics, error reporters, and feature-flag clients that path-segment
  user identifiers.

## Common Patterns

- Encoded slashes (`%2F`, `%5C`, `%252F`, double-encoded variants) survive
  client routers but collapse to `/` in the browser's fetch path.
- URL constructors normalize `..` segments before the request is sent. The
  attacker exploits exactly that normalization to climb to a different API
  route.
- Path-built URLs are assumed same-origin and therefore "safe", so the
  client trusts the response schema without re-validating identity.
- The client uses the response of the diverted request to populate trusted
  state: user identity, role, redirect target, CSRF token, public key, OAuth
  client config.

## Protection And Bypass Themes

- Test inputs with `..%2F`, `..%5C`, `%2e%2e%2f`, `;`, `#`, `?`, and raw
  whitespace. The client URL constructor handles each differently.
- Look for sinks that build paths *before* a known-good prefix; the prefix
  protects nothing if `..` traversal lands above it.
- For OAuth/OIDC, check whether the callback's path comes from response
  data; a forged path can swap the client into a different tenant's callback
  handler and leak the code.
- For service workers, a poisoned cache key persists across reloads; treat
  this as higher severity than a one-shot CSPT.
- For SDKs, find the templating helper and grep for missing
  `encodeURIComponent` around path parameters.

## Safe Validation

- Use two owned accounts (or one owned account against an owned tenant
  endpoint) so the diverted request stays within scope.
- Prove client behavior, not just network divergence: capture the network
  call *and* the DOM/state change the client made because of the diverted
  response.
- Avoid sending the diverted client at production endpoints that mutate
  shared state. Pick a read endpoint, or a write endpoint scoped to your
  own account.
- Stop after the chain is demonstrated end-to-end once.

## Anti-Patterns

- Confusing CSPT with server-side path traversal. The fix and the impact
  chain are different; do not file as LFI.
- Reporting a path-divergence proof of concept with no client-side
  consequence. CSPT is only impactful when the *client trusts* the
  diverted response.
- Driving a victim browser at endpoints that mutate other users' data.
- Forgetting to URL-encode in your own proof code; you may end up testing
  your harness rather than the application.
