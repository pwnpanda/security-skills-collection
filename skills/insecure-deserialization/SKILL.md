---
name: insecure-deserialization
description: >-
  Use when authorized testing involves serialized objects, signed blobs,
  sessions, queues, caches, cookies, tokens, workflow state, or language-native
  serialization formats.
---

# Insecure Deserialization

OWASP mapping: A8:2017 Insecure Deserialization. Related to Software and Data
Integrity Failures in 2021 and 2025.

## Workflow

1. Read `../../references/scope-safety.md` and the relevant section of
   `../../references/high-signal-must-tests.md`.
2. Inventory serialization formats and trust boundaries.
3. Check whether integrity, type allowlists, versioning, and object construction
   are enforced before deserialization.
4. Validate with harmless object confusion, state manipulation, or controlled
   marker behavior.
5. Write findings with `../../references/finding-output.md`.

## Where To Look

- Session cookies, remember-me tokens, password reset state, shopping carts,
  workflow state, wizard state, queues, cache entries, signed URLs, and exports.
- Java, .NET, PHP, Python, Ruby, Node, and framework-specific object formats.
- Message brokers, background job payloads, webhook retry queues, and cache
  stores shared across trust boundaries.

## Common Patterns

- Signed data treated as safe even when attackers can choose object type or
  fields.
- Encryption without authentication or key separation.
- Deserializing before signature, schema, tenant, or role checks.
- Legacy gadget-capable libraries left reachable through compatibility code.

## Protection And Bypass Themes

- Distinguish tamper-proofing from type safety and capability safety.
- Check key reuse, weak secrets, algorithm confusion, and missing purpose binding.
- Look for alternate serializers, fallback parsers, legacy versions, and queue
  consumers that skip web-layer validation.
- Test field-level trust assumptions with self-owned records and reversible
  state changes.

## Safe Validation

- Do not execute commands or use destructive gadget chains. Demonstrate impact
  with safe type confusion, privilege-relevant state changes, or controlled
  callback behavior in a lab or owned account.
