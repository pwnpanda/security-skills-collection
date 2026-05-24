---
name: mass-assignment
description: >-
  Use when authorized testing involves request bodies that the server binds
  directly to a model, document, or object - profile updates, admin/settings
  endpoints, REST/GraphQL mutations, multipart forms, XML imports, or any
  endpoint where the framework deserializes a payload into a typed object.
---

# Mass Assignment

Mass assignment lives where the framework offers an "easy" way to copy a
request body into a model - and the developer forgets to restrict which
fields are writable. Hidden writable fields include `role`, `is_admin`,
`owner_id`, `tenant_id`, `plan`, `price`, `verified`, `status`, `created_at`,
and any feature flag the UI hides.

## Workflow

1. Read `../../references/scope-safety.md` and the API, GraphQL, Mass
   Assignment, And Prototype Pollution section of
   `../../references/high-signal-must-tests.md`.
2. For each model touched by the API, list every field by reading the
   API responses, GraphQL schema, mobile responses, exports, and the
   admin UI source.
3. Compare the field set to the **legitimate** write surface (visible
   form fields). The delta is the candidate list for mass assignment.
4. Test each candidate field by adding it to the request body across
   all binding paths: JSON, form, multipart, XML, GraphQL variables.
5. Validate with owned accounts; confirm the field actually changed
   server-side (re-fetch, observe behavior).
6. Write findings with `../../references/finding-output.md`. Include
   the binding path and the privilege impact.

## Where To Look

- Profile, settings, organization, team, billing, member, integration,
  webhook, API key, and tenant endpoints.
- Sign-up, invite acceptance, and account-claim endpoints (high impact:
  set `tenant_id` or `role` at creation).
- Admin endpoints repurposed for user-facing flows (e.g. SCIM,
  partner APIs).
- GraphQL mutations with input types; the input type often has more
  fields than the UI form.
- Importers that accept JSON/CSV/XML records and map fields to model
  attributes.
- Mobile and partner APIs whose payloads include the full model.

## Common Patterns

- Rails `ActiveRecord` with `update(params[:user])` instead of
  permitted params; ASP.NET model binding without `[Bind]` allowlist;
  Java `BeanUtils.copyProperties` without exclusion; Django
  `Model(**data)` with raw POST data.
- GraphQL `UpdateUserInput` that accepts `role` but the UI never sets
  it.
- Endpoints accept additional fields from `application/json` even when
  the form variant rejects them.
- Nested objects: the top-level model is allowlisted but nested objects
  are bound recursively (e.g. `{"profile": {"role": "admin"}}`).
- Bulk endpoints accept arrays where authorization is checked per array
  but field allowlists are not.

## Protection And Bypass Themes

- Try injecting `role`, `is_admin`, `admin`, `superuser`, `owner_id`,
  `tenant_id`, `org_id`, `plan`, `price`, `amount`, `verified`,
  `email_verified`, `mfa_enabled`, `status`, `state`, `archived_at`,
  `deleted_at`, `created_at`, `last_login_at`.
- Try framework-specific magic fields: `_destroy` (Rails),
  `__typename` (GraphQL fragments), `id` overrides, `password_hash`,
  `salt`, `api_key`.
- Try alternate content types: convert JSON to form, multipart, XML,
  GraphQL - allowlists are often type-specific.
- Try nested injection through related objects.

## Safe Validation

- Use two owned accounts (one privileged, one not) and try to set the
  unprivileged account's hidden field. Confirm with a refetch and
  optionally with a privileged action that should now succeed.
- For cross-tenant escalation, use owned tenants only.
- Revert any change you made to your account before moving on.

## Anti-Patterns

- Reporting "field X accepted in request" without confirming the
  server actually persisted it.
- Modifying real production data on accounts you do not own.
- Reporting `id` field acceptance without confirming the server allows
  the id change to land (often the framework silently ignores it).
