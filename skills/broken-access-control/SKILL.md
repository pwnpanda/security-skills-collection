---
name: broken-access-control
description: >-
  Use when authorized testing involves access control, IDOR, privilege
  escalation, force browsing, tenant isolation, object ownership, or
  function-level authorization gaps.
---

# Broken Access Control

OWASP mapping: A5:2017, A01:2021, and A01:2025 Broken Access Control.

## Workflow

1. Read `../../references/scope-safety.md` and the relevant section of
   `../../references/high-signal-must-tests.md`.
2. Build a role, tenant, and object matrix before testing.
3. Identify where authorization decisions are made and whether they are enforced
   server-side for every read, write, delete, export, and admin action.
4. Validate with self-owned accounts and objects across roles or tenants.
5. Write findings with `../../references/finding-output.md`.

## Where To Look

- Direct object IDs in URLs, JSON bodies, GraphQL variables, file paths, exports,
  invoices, messages, projects, organizations, and teams.
- Admin, support, billing, invite, sharing, and workflow transition endpoints.
- Mobile/API endpoints that differ from web UI authorization.
- Batch endpoints, search endpoints, autocomplete, metadata, and historical
  versions of resources.

## Common Patterns

- UI hides actions but API accepts them.
- Ownership checked on parent object but not nested child object.
- Read checks exist while write, delete, export, or state transition checks are
  missing.
- Tenant inferred from request parameters instead of authenticated context.

## Protection And Bypass Themes

- Try alternate identifiers: UUID, numeric ID, slug, email, external ID, import
  ID, invite token, and archived object ID.
- Check method override, alternate content type, GraphQL aliasing, batch requests,
  and secondary endpoints that call the same service.
- Test role transitions, deactivated users, invited users, pending membership,
  ownership transfer, and object sharing edge cases.
- Verify authorization after server-side object lookup, not before canonicalizing
  identifiers.

## Safe Validation

- Use two owned accounts and clearly labeled test objects.
- Avoid reading or modifying real user data. Prove impact with controlled objects
  and exact before/after role state.
