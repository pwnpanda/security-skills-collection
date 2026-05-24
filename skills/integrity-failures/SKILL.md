---
name: integrity-failures
description: >-
  Use when authorized testing involves signed cookies, signed URLs, JWT-like
  state, workflow state blobs, cache restores, webhook events, queue
  messages, import/export artifacts, feature-flag bundles, plugin or update
  artifacts, or any data trusted by the consumer without integrity
  verification.
---

# Integrity Failures

OWASP mapping: consolidates A08:2021 Software and Data Integrity Failures
and A08:2025 Software or Data Integrity Failures. For low-level
deserialization gadget chains use `../insecure-deserialization/SKILL.md`.
For build/CI/CD/registry integrity use `../software-supply-chain-failures/
SKILL.md`.

## Workflow

1. Read `../../references/scope-safety.md` and the Deserialization And
   Integrity section of `../../references/high-signal-must-tests.md`.
2. List every artifact that crosses a trust boundary: signed cookies,
   session blobs, remember-me tokens, workflow state, cache entries, queue
   messages, webhook payloads, mobile sync state, import/export files.
3. For each artifact, identify producer, transport, storage, and **every**
   consumer (including replay, restore, and queue paths).
4. Verify integrity checks happen at the consumer before the artifact
   influences security, money, identity, access, or code execution.
5. Validate tampering only with owned artifacts and reversible state.
6. Write findings with `../../references/finding-output.md`.

## Where To Look

- Cookie payloads (`session`, `auth`, `remember`, `cart`, `wizard`), signed
  URLs, signed query parameters, encrypted-but-not-authenticated state.
- Workflow/wizard state passed back as base64 or JSON blobs (multi-step
  signup, checkout, invite acceptance, onboarding wizards).
- Webhook events, queue messages, async job inputs, retry payloads, dead-
  letter replays, cache restores, import files.
- Client-side feature flags, prices, roles, entitlements, or policy data
  sent back to the server.
- Mobile/offline sync state and "last known good" caches.

## Common Patterns

- Signed data lacks purpose, audience, tenant, user, or freshness binding.
- Integrity verified at ingestion but not at later replay/restore.
- Encrypted-but-not-authenticated data ("MAC-then-encrypt" or no MAC at
  all) allowing CBC-style tampering or oracle attacks.
- Producer signs only payload bytes; metadata (cookie name, key id, header)
  is excluded from signature coverage.
- Client-supplied workflow state trusted for role/price/entitlement
  decisions without server reconciliation.

## Protection And Bypass Themes

- Distinguish "came from our app" from cryptographic integrity. Origin
  cookies and CSRF tokens prove neither.
- Check replay, downgrade, cross-tenant reuse, cross-environment reuse,
  cross-user reuse, and missing expiry.
- Test alternate encodings, duplicate fields, missing fields, version
  downgrade behavior, and canonicalization differences between signer and
  verifier.
- Inspect async and offline paths where validation may differ from
  request-time validation.
- Check that the key used to verify cannot be selected by the attacker
  (kid lookup, JWK injection - see `../jwt-jose/SKILL.md`).

## Safe Validation

- Use owned artifacts, owned accounts, owned tenants. Demonstrate tamper
  acceptance with harmless field changes - e.g. a non-financial flag, a
  display-only field, or your own role.
- Do not modify real payments, real role assignments, or production
  deployment state.

## Anti-Patterns

- Reporting "the cookie is base64-decodable" as impact. The bug is when
  modifying the decoded fields changes a security decision.
- Confusing transport security (TLS) with artifact integrity. TLS protects
  the wire; it does not stop a consumer trusting tampered cached data.
- Reporting only on producer behavior. The bug usually lives at the
  consumer, often in a different service.
