---
name: blind-ssrf
description: >-
  Use when authorized testing involves server-side fetchers whose responses
  are not returned to the caller - webhooks, "test connection" buttons, link
  previews, RSS/Atom readers, importers, document converters, screenshot
  services, antivirus scanners, OAuth/OIDC discovery endpoints, image
  proxies, or any backend that consumes a URL the user supplies.
---

# Blind SSRF

Blind SSRF is server-side request forgery where the HTTP response body is not
exposed to the tester. Evidence comes from an out-of-band callback, a timing
oracle, or an authoritative DNS log. Treat callback attribution and scope
discipline as harder than payload generation.

## Workflow

1. Read `../../references/scope-safety.md`, the SSRF section of
   `../../references/high-signal-must-tests.md`, and `../oast-testing/SKILL.md`.
2. Enumerate every URL-accepting input: form fields, JSON keys, multipart
   parts, headers, file imports (XML, JSON, YAML, markdown), and per-tenant
   integration settings.
3. For each input, classify the fetcher: client library, follows redirects,
   honored schemes, header forwarding, request identity, egress path.
4. Send one Category B marker per (input, scheme, redirect-strategy) cell.
   Append each marker to the per-program OAST log before sending.
5. When a callback arrives, attribute it via the marker log. Capture source
   IP, user-agent, headers, TLS fingerprint if available, and timing offset
   from the request.
6. Determine whether the callback was DNS-only or HTTP. DNS-only is still
   proof of reachability; do not escalate to HTTP unless program scope and the
   evidence requirement justify it.
7. Write the finding with `../../references/finding-output.md`. Include the
   input, payload, fetcher identity, callback log entry, and the boundary
   that was crossed.

## Where To Look

- Webhook URL fields, "test webhook" buttons, OAuth/OIDC issuer or JWKS URL
  inputs, SAML metadata import, SCIM endpoints, alert delivery URLs.
- Avatar, logo, attachment, image, and video import-by-URL fields; document
  converters; PDF renderers; HTML-to-PDF services; screenshot generators.
- Link unfurling and preview pipelines (chat, ticketing, social, marketing).
- Anti-malware, content scanning, indexing, or transcoding workers that fetch
  uploaded content from object storage by URL.
- Per-tenant integrations: Jira/Slack/GitHub-style "enter server URL" flows.

## Common Patterns

- Validator and fetcher use different URL parsers. Validator sees
  `https://allowed.example`; fetcher follows a redirect to a private IP.
- Validation runs at submit time; the fetch runs in a queue worker with a
  different network identity and different egress.
- DNS rebinding between validation and fetch: the validator resolves to a
  public IP, the fetcher resolves to a private one.
- IPv6, alternate IPv4 notations (decimal, octal, hex), trailing dots, mixed
  case, userinfo, IDNA, and `0.0.0.0`/`127.x` ranges slip past naive checks.
- Cloud metadata services reachable from the fetcher network when the
  application has no metadata-token enforcement.

## Protection And Bypass Themes

- Use OAST callbacks to prove reachability before attempting any internal
  target. The first successful callback already qualifies as evidence.
- If only DNS exfil works, use a DNS-only oracle and stop. DNS is enough for
  most reports; chasing HTTP exfil adds risk without adding novelty.
- For redirect handling, send a 302 from your callback host to a second
  unique marker. If the second marker fires, redirects are followed without
  revalidation.
- For DNS rebinding, prepare a record that returns a benign public IP first
  and then your callback IP. Confirm with two markers minutes apart, not by
  pointing at real internal services.
- For metadata access, only attempt when explicitly in scope; prefer a single
  proof request to a well-known harmless metadata path and stop.

## Safe Validation

- Callback infrastructure must be self-owned and per-program tagged.
- Do not enumerate internal IP ranges, port-scan, or pivot. Reachability of
  one well-defined private endpoint plus an OAST hit is sufficient evidence.
- Do not request credentials, secrets, tokens, or session data from internal
  endpoints. A request log entry from the target's egress IP is the proof.
- For "test connection" flows, fire exactly enough requests to attribute the
  callback, then stop. Repeated firings often page on-call.

## Anti-Patterns

- Treating an inbound callback without a matching marker entry as proof.
- Sending generic public OAST payloads borrowed from other engagements;
  attribution is impossible.
- Pivoting from a confirmed callback into broad internal scanning. Scope and
  blast-radius rules apply even after impact is proven.
- Confusing browser-side fetch (which would be CSRF/CORS-bounded) with the
  server-side fetcher; verify which identity actually emitted the callback.
