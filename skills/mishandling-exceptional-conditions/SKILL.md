---
name: mishandling-exceptional-conditions
description: >-
  Use when authorized testing involves fail-open behavior, error handling,
  partial failures, race edges, timeout handling, retries, rollback, parser
  errors, or abnormal workflow states.
---

# Mishandling Of Exceptional Conditions

OWASP mapping: A10:2025 Mishandling of Exceptional Conditions.

## Workflow

1. Read `../../references/scope-safety.md` and the relevant section of
   `../../references/high-signal-must-tests.md`.
2. Identify abnormal states the system can encounter: timeout, retry, duplicate,
   partial commit, parse error, dependency failure, stale cache, and rollback.
3. Check whether the secure behavior is fail-closed, compensating, or explicitly
   recoverable.
4. Validate with controlled low-impact conditions where allowed.
5. Write findings with `../../references/finding-output.md`.

## Where To Look

- Payment callbacks, webhook retries, queue consumers, imports, exports, uploads,
  async jobs, approval workflows, signup, login, MFA, and provisioning.
- Error pages, exception handlers, transaction boundaries, retry loops, circuit
  breakers, and background reconciliation.
- Parser errors, malformed files, duplicate events, idempotency keys, and
  timeouts between services.

## Common Patterns

- Authorization, payment, MFA, or validation failure is treated as unknown but
  workflow continues.
- Partial failure creates privileged, paid, verified, or approved state.
- Retry or duplicate handling bypasses one-time checks.
- Error messages reveal sensitive internals or skip cleanup.

## Protection And Bypass Themes

- Test fail-open versus fail-closed for each security decision.
- Check transactionality across database, cache, queue, email, and third-party
  service boundaries.
- Review idempotency, duplicate event handling, retry ordering, and rollback
  semantics.
- Look for parser error recovery that accepts partially validated input.

## Safe Validation

- Use low-impact test objects and program-approved abnormal inputs.
- Do not cause service disruption. Stop at proof of unsafe state transition.
