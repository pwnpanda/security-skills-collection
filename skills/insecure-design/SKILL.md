---
name: insecure-design
description: >-
  Use when authorized testing involves missing security controls, unsafe
  business rules, flawed trust boundaries, abuse cases, workflow bypasses, or
  design-level risk.
---

# Insecure Design

OWASP mapping: A04:2021 and A06:2025 Insecure Design.

## Workflow

1. Read `../../references/scope-safety.md` and the relevant section of
   `../../references/high-signal-must-tests.md`.
2. Model the business workflow, assets, actors, trust boundaries, and abuse cases.
3. Identify missing controls, unsafe assumptions, weak invariants, and unhandled
   negative paths.
4. Validate with controlled workflow evidence, not broad exploitation.
5. Write findings with `../../references/finding-output.md`.

## Where To Look

- Payments, billing, discounts, promotions, account recovery, invite flows,
  tenant onboarding, approvals, content moderation, rate-limited resources, and
  entitlement checks.
- Multi-step workflows where state can be skipped, repeated, replayed, or
  reordered.
- Features that rely on user honesty, UI-only restrictions, support trust, or
  delayed reconciliation.

## Common Patterns

- Business rule exists in documentation but not in enforceable server logic.
- Workflow assumes steps happen in order.
- Abuse is prevented by rate limits only after harm occurs.
- No secure default for tenant, role, approval, or entitlement state.

## Protection And Bypass Themes

- Check state machine transitions: skip, repeat, parallelize, reorder, expire,
  revoke, and restore.
- Test boundaries between user roles, tenants, billing states, and lifecycle
  states.
- Look for hidden assumptions in background jobs, webhooks, retries, support
  tooling, and reconciliation.
- Review whether controls are preventive, detective, or manual-only.

## Safe Validation

- Use low-value, reversible actions and owned accounts.
- Avoid financial, operational, or data-impacting changes unless explicitly
  permitted and safely reversible.
