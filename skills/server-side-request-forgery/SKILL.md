---
name: server-side-request-forgery
description: >-
  Use when authorized testing involves server-side URL fetches, webhooks, remote
  media imports, link previews, callback validation, request proxies, cloud
  metadata, or internal service reachability.
---

# Server-Side Request Forgery

OWASP mapping: A10:2021 Server-Side Request Forgery (SSRF). In OWASP 2025,
SSRF is rolled into Broken Access Control, but this skill remains separate
because the 2021 entry is unique.

## Workflow

1. Read `../../references/scope-safety.md` and the relevant section of
   `../../references/high-signal-must-tests.md`.
2. Identify all server-side fetch primitives and the network identity they use.
3. Map input validation, URL parsing, redirects, DNS resolution, proxy behavior,
   cloud metadata controls, and egress restrictions.
4. Validate only with self-controlled endpoints or explicitly allowed internal
   proof targets.
5. Write findings with `../../references/finding-output.md`.

## Where To Look

- Webhooks, callback URLs, avatar/media importers, document converters, link
  previews, URL validators, screenshot services, RSS readers, and PDF renderers.
- Cloud integrations, CI/CD callbacks, image proxies, file importers, and
  "test connection" features.
- Backends that accept hostnames, IPs, URL paths, storage bucket URLs, or service
  names from users.

## Common Patterns

- Allowlist checks before redirects, DNS changes, proxy rewrites, or final socket
  connection.
- Different URL parsers in validation and request libraries.
- Private IP filtering that misses IPv6, alternate notations, DNS rebinding, or
  internal hostnames.
- Metadata service access without hop-limit, token, or network policy controls.

## Protection And Bypass Themes

- Compare scheme, host, port, path, userinfo, fragment, and redirect handling
  between the validator and fetcher.
- Check canonicalization order for URL decoding, IDNA, IPv6, mixed notation, and
  trailing dots.
- Test whether redirects are revalidated and whether DNS is pinned between
  validation and connection.
- Check whether proxies, service mesh, and cloud SDKs bypass application-level
  network restrictions.

## Safe Validation

- Prefer self-owned collaborator-style endpoints that log inbound requests.
- Do not scan internal networks or retrieve secrets. Prove reachability with a
  harmless request, unique marker, and captured source IP or headers.
