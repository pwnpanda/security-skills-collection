---
name: request-smuggling
description: >-
  Use when authorized testing involves reverse proxies, CDNs, load balancers,
  API gateways, or front-end/back-end pairs where ambiguous HTTP/1.1 framing,
  HTTP/2-to-HTTP/1.1 downgrade, or header parser differentials may let one
  request smuggle a second request to the back-end or another user.
---

# Request Smuggling

Request smuggling is a parser-differential bug between a fronting proxy and
a back-end server. Because the impact pivots into hijacking other users'
requests, cache poisoning, or auth bypass, these tests carry above-average
blast radius and demand strict scope and safety discipline.

## Workflow

1. Read `../../references/scope-safety.md` and the Request Smuggling And
   Cache Poisoning section of `../../references/high-signal-must-tests.md`.
   Confirm explicit program permission to test smuggling before sending
   ambiguous requests.
2. Map the stack: front-end (CDN, WAF, proxy, gateway), back-end (origin
   server, application server), and connection reuse behavior.
3. Probe for CL.TE, TE.CL, TE.TE, CL.CL ambiguity (HTTP/1.1) and H2.CL,
   H2.TE downgrade (HTTP/2).
4. Confirm a differential with a non-destructive probe (e.g. a "smuggled"
   request that hits a 404 path) before attempting impact.
5. For impact, prefer routing a smuggled request to an owned response or
   poisoning a cache entry for an owned URL; avoid hijacking real user
   requests.
6. Write findings with `../../references/finding-output.md`. Include the
   exact parser differential, the front-end behavior, and the back-end
   behavior.

## Where To Look

- Multi-hop topologies: CDN -> WAF -> origin; API gateway -> service
  mesh -> app server.
- HTTP/2 front-ends terminating to HTTP/1.1 back-ends; this is the
  modern hot zone (H2 desync).
- Anywhere connection reuse is enabled between the front-end and the
  back-end.
- Differences in how proxies handle: duplicate Content-Length,
  Transfer-Encoding casing/quoting, chunked vs identity, malformed
  chunk sizes, trailing whitespace, multiple Host headers, obsolete
  line folding, header continuation.

## Common Patterns

- CL.TE: front-end uses Content-Length, back-end uses Transfer-Encoding.
- TE.CL: front-end uses Transfer-Encoding, back-end uses
  Content-Length.
- TE.TE: both use Transfer-Encoding, but obfuscated TE header is
  ignored by one of them.
- H2.CL: HTTP/2 request with a smuggled HTTP/1.1 framing in the body,
  downgraded by a translating proxy that uses the body's CL.
- CRLF in HTTP/2 pseudo-headers passed through to HTTP/1.1 verbatim.

## Protection And Bypass Themes

- Try `Transfer-Encoding: chunked` with whitespace, casing, or
  encoded variants (`Transfer-Encoding : chunked`, `chunked, identity`).
- Try multiple Content-Length headers, multiple Transfer-Encoding
  headers.
- For H2 desync, test header injection through pseudo-headers and
  through header field values containing CRLF.
- For impact, prefer cache poisoning of an owned URL or a "404 to
  attacker-marker" proof over arbitrary request hijacking.
- If a WAF normalizes HTTP/1.1 traffic, check whether HTTP/2 paths
  bypass the WAF entirely.

## Safe Validation

- Test only when program rules explicitly accept smuggling tests.
- Use a private/owned URL for impact proofs (e.g. cache poison an
  owned cache key, route a smuggled request to your own session-bound
  URL).
- Never hijack real user requests, never poison shared caches for
  paths real users access.
- Stop after the first reproducible differential plus the smallest
  impact demonstration.

## Anti-Patterns

- Mass-scanning targets with smuggling payloads; almost always out of
  scope.
- Demonstrating impact by hijacking another user's authenticated
  request.
- Poisoning a production cache entry for a high-traffic page.
