---
name: cache-poisoning
description: >-
  Use when authorized testing involves HTTP caches - CDNs, reverse proxies,
  application caches, browser caches - and whether attacker-controlled
  unkeyed inputs (headers, cookies, parameters) can poison a cached response
  served to other users, or whether path/extension confusion (web cache
  deception) can route sensitive responses into a public cache.
---

# Cache Poisoning

Cache poisoning has two main shapes: classic poisoning where an unkeyed
input changes the cached response, and web cache deception where the cache
keys on the URL but serves a sensitive response under a benign-looking key.
Both pivot small server-side bugs into impact across many users, so blast
radius and scope discipline are critical.

## Workflow

1. Read `../../references/scope-safety.md` and the Request Smuggling And
   Cache Poisoning section of `../../references/high-signal-must-tests.md`.
2. Map cache layers: CDN, reverse proxy, application cache, framework
   page cache, browser cache. For each, identify the cache key (URL,
   method, Vary headers, cookie tier).
3. Identify candidate unkeyed inputs the server still echoes into a
   response: `X-Forwarded-Host`, `X-Original-URL`, `X-Forwarded-Proto`,
   custom client hints, accept variants.
4. For each unkeyed input, change it and observe whether the response
   changes and whether the change is then served to a clean request.
5. For web cache deception, find paths that route to sensitive
   responses but appear cacheable (e.g. user profile at
   `/profile.css`).
6. Validate by poisoning an owned cache key and reading the poisoned
   response from a clean session.
7. Write findings with `../../references/finding-output.md`. Include
   the cache layer, key, unkeyed input, and the smallest impact proof
   on an owned key.

## Where To Look

- CDN-fronted apps (Cloudflare, Akamai, Fastly, CloudFront,
  Cloudfront, Vercel, Netlify).
- API gateways with response caching.
- Server-side framework caches (Rails `caches_action`, Next.js ISR,
  Nuxt's payload cache).
- Cached error pages (404, 500) that include attacker-controlled
  inputs.
- "Public-by-default" file extensions that bypass auth or are cached
  even on authenticated routes: `.css`, `.js`, `.png`, `.json`,
  `.txt`, `.map`.

## Common Patterns

- Cache keys on path + query string but not on `Host` /
  `X-Forwarded-Host` while the server uses those headers in absolute
  URL generation (links, OAuth callback display) - see
  `../host-header-injection/SKILL.md`.
- Cache keys exclude `Accept-Language`, `Accept-Encoding`, `User-
  Agent` even when the response varies by them.
- Server reflects `X-Forwarded-Proto` into rendered absolute URLs;
  attacker poisons `https`->`http` for a shared cached page.
- 404/500 pages echo path or referrer back to the user without
  encoding; cache stores the malformed response.
- Web cache deception: `/profile` returns user-specific content;
  `/profile.css` is treated as a static asset by the CDN and cached
  under that key, exposing one user's profile to anyone who requests
  the same `.css` path.

## Protection And Bypass Themes

- Probe unkeyed headers systematically: `X-Forwarded-Host`,
  `X-Forwarded-Proto`, `X-Forwarded-Server`, `X-Original-URL`,
  `X-Original-Host`, `X-Host`, `Forwarded`, custom `X-*` headers the
  app uses internally.
- Combine with parameter pollution: duplicate query params, casing
  changes (`?utm=`), and parameter encoding to find variants ignored
  by the cache key but used by the app.
- For web cache deception, try common static-asset extensions
  appended to authenticated routes; observe both the response body
  and the cache-control headers.
- For 4xx/5xx poisoning, send a request that triggers a malformed
  response (oversized headers, malformed Accept) and check whether
  that response is cached.

## Safe Validation

- Use a unique-marker request and an owned cache key. The proof is:
  poison key `X` with marker `M`, then request key `X` from a clean
  session and observe `M`.
- Never poison shared cache keys for paths that real users visit.
- Pick paths under your own tenant, your own user, or a clearly
  attacker-only path (`?marker=<uuid>` not part of any real flow).
- Stop after one reproduction on an owned key.

## Anti-Patterns

- Poisoning the home page, login page, or any high-traffic asset.
- Reporting "header reflected in response" without verifying the
  response is actually cached and served to a different request.
- Web cache deception PoCs that read another real user's data; use
  two owned accounts instead.
