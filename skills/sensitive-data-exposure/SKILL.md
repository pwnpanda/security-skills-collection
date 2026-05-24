---
name: sensitive-data-exposure
description: >-
  Use when authorized testing involves sensitive data exposure in transport,
  storage, logs, caches, exports, backups, client state, analytics, or error
  messages.
---

# Sensitive Data Exposure

OWASP mapping: A3:2017 Sensitive Data Exposure. Related to 2021 and 2025
Cryptographic Failures.

## Workflow

1. Read `../../references/scope-safety.md` and the relevant section of
   `../../references/high-signal-must-tests.md`.
2. Identify the sensitive data class and where it is collected, transmitted,
   stored, transformed, cached, logged, exported, and deleted.
3. Trace exposure paths across server, client, third-party services, and support
   tooling.
4. Validate with your own data or clearly synthetic markers.
5. Write findings with `../../references/finding-output.md`.

## Where To Look

- API responses, HTML source, JavaScript state, local/session storage, cookies,
  logs, analytics events, crash reports, emails, exports, backups, and caches.
- Search, autocomplete, object metadata, audit logs, support panels, and admin
  dashboards.
- CDN, object storage, debug endpoints, tracing systems, and monitoring tools.

## Common Patterns

- Hidden fields or client state include data the user should not see.
- Logs or analytics collect tokens, secrets, reset links, PII, or payment data.
- Export endpoints ignore field-level permissions.
- Cached or archived views preserve data after access is revoked.

## Protection And Bypass Themes

- Check whether redaction happens before all sinks, not just before UI display.
- Test role, tenant, sharing, deletion, and retention changes against cached and
  exported data.
- Review HTTP caching, CDN keys, browser storage, referrer leakage, and file
  metadata.
- Check whether masking is cosmetic or enforced at the data retrieval layer.

## Safe Validation

- Use synthetic or self-owned sensitive data.
- Do not collect third-party data. Capture the minimum evidence needed to prove
  exposure.
