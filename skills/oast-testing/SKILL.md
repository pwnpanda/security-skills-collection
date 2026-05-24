---
name: oast-testing
description: >-
  Use when authorized testing relies on out-of-band callbacks for evidence -
  blind injection, blind SSRF/XSS/SSTI/XXE, log4shell-style sinks, deferred
  jobs, webhooks, exports, mail rendering, or any vulnerability where the only
  signal is a DNS/HTTP/SMTP request back to attacker-controlled infrastructure.
---

# OAST Testing

Out-of-band Application Security Testing turns "no visible response" into
evidence. The skill is not the payload; it is the discipline that makes a
callback attributable to one target, one request, and one payload family.

## Workflow

1. Read `../../references/scope-safety.md` and any program rules that mention
   external callbacks, scanners, or third-party infrastructure.
2. Confirm callback infrastructure is allowed and pick a per-program callback
   subdomain or per-program slug embedded in every marker.
3. Run a Category A preflight (`TEST_<UUID>`) against your own callback to
   prove the listener works. Never send Category A markers to a target.
4. Plan a payload-family x field matrix before sending Category B markers to
   targets. Every cell is either "marker UUID sent" or an explicit rejection
   note.
5. Send each request with a unique Category B marker and append the marker to
   the per-program marker log before the request leaves.
6. Attribute every inbound callback by looking up its marker in the log. If a
   marker is not in any log, treat the callback as suspicious noise, not proof.
7. Write findings with `../../references/finding-output.md` and include the
   marker, callback log entry, source IP, and the request that triggered it.

## Marker Discipline

Two marker categories with opposite locality rules:

- Category A - infrastructure preflight. Prefix `TEST_` plus a UUID. Resolve
  locally to prove the listener works. Tag as `preflight`. Never embed in
  target payloads.
- Category B - target payload markers. Globally unique per request, written
  once, sent only to the target. Never resolve them locally; a local resolution
  looks identical to a real hit and destroys attribution.

Per-program marker log columns:

```
marker_uuid    sent_at_iso8601    target_host    endpoint    parameter    payload_family    request_id
```

Append the row before the request is sent, not after.

## Where To Look

- Webhooks, callback URLs, "test connection" buttons, OAuth/SAML callback
  registration, link previews, RSS readers, screenshot services, PDF/HTML
  renderers, document converters, importers, exporters.
- Stored content rendered later in admin, support, moderation, email, billing,
  audit, ticketing, mobile WebView, or export contexts (blind XSS).
- Logging and search pipelines that interpret structured fields (log4shell-
  style sinks, template engines, expression languages).
- Deferred or asynchronous jobs: queue consumers, scheduled exports, antivirus
  scanners, indexing, transcoding, retry handlers.

## Common Patterns

- Multiple parsers and renderers handle the same input. The visible response
  uses one; the callback comes from another later in the pipeline.
- Validation happens at submit time; the dangerous render happens minutes,
  hours, or days later in another service identity.
- Sanitizers strip non-alphanumerics or truncate. The payload that arrived at
  the sink may be shorter than the one that left.
- Egress is partially filtered. DNS may exit when HTTP does not, or HTTPS may
  exit when HTTP does not.

## Protection And Bypass Themes

- DNS-only egress is still a callback. Use DNS-only oracles when HTTP egress
  is blocked.
- Many WAFs allow lookups of subdomains under common providers. Use callback
  domains that do not match obvious scanner fingerprints when stealth is not
  required, and stay within scope when it is.
- Truncation defenses: keep marker UUIDs short enough to survive (8 random
  bytes hex-encoded is usually safe), and log both the full UUID and the
  truncated prefix you actually sent.
- Encoding defenses: many sinks accept payloads through HTML, URL, JSON,
  base64, or templating layers. Plan the matrix per encoding.

## Safe Validation

- Use self-owned callback infrastructure or program-approved Interactsh-style
  services only.
- Do not exfiltrate credentials, tokens, environment variables, or files. A
  callback with a unique marker, source IP, and timestamp is enough proof.
- Stop after one confirmed callback per finding. Do not loop or stress the
  pipeline once the issue is proven.
- Avoid mass scanning, persistence, beaconing, or any payload that continues
  after the test window.

## Anti-Patterns

- Resolving Category B markers locally "to test DNS" - destroys attribution.
- Reusing a marker across requests when the sink fires asynchronously - you
  cannot tell which request fired.
- Sharing one callback domain across programs without per-program subdomains
  or in-marker slugs - cross-program attribution becomes impossible.
- Treating an inbound callback without a matching marker entry as proof.
