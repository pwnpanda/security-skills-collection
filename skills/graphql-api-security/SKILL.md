---
name: graphql-api-security
description: >-
  Use when authorized testing involves GraphQL APIs - introspection,
  schema discovery, query/mutation/subscription endpoints, node IDs and
  global IDs, batched and aliased queries, depth and complexity limits,
  fragment-based field selection, per-field authorization, or custom
  scalar handling.
---

# GraphQL API Security

GraphQL bugs cluster around four areas: schema exposure, per-field/per-edge
authorization, batching/alias/depth DoS, and the same classes that hit REST
(mass assignment, IDOR, injection) but with GraphQL-specific shapes.

## Workflow

1. Read `../../references/scope-safety.md` and the API, GraphQL, Mass
   Assignment, And Prototype Pollution section of
   `../../references/high-signal-must-tests.md`.
2. Discover the schema via introspection (`{__schema{...}}`), suggestions
   ("did you mean"), error messages, persisted-query lists, or
   client-bundle introspection.
3. Map types, queries, mutations, subscriptions, custom scalars, input
   objects, and directives.
4. For each entry point, test authorization at the **resolver** level,
   per-edge for relations, and per-field for sensitive scalars.
5. Test batching (array of operations), aliases (same field requested
   multiple times under different names), and fragments.
6. Validate with owned accounts and minimal queries; do not flood the
   server.
7. Write findings with `../../references/finding-output.md`. State the
   resolver, the field, and the authorization layer that was missing.

## Where To Look

- `/graphql`, `/api/graphql`, `/v1/graphql`, `/playground`, `/graphiql`,
  `/voyager`.
- Persisted-query stores and APQ (Automatic Persisted Queries) hash
  endpoints.
- Mobile and CLI clients that ship the schema or generated SDK.
- Federation gateways (Apollo Federation, GraphQL Mesh) where access
  control may live in the gateway, not the subgraph.

## Common Patterns

- Authorization at the route level (`/graphql`) but not per-resolver;
  any authenticated user reaches all queries.
- Per-resolver auth but not per-field; sensitive fields like `email`,
  `phoneNumber`, `apiKey`, `roleSlug` are accessible on any object the
  user can read.
- Global IDs (Relay-style) that are base64 of `Type:id`; trivial to
  enumerate or substitute across tenants.
- Mutations expose more fields than the UI uses (mass assignment via
  GraphQL).
- Introspection enabled in production, leaking the full schema.
- No depth/complexity limit; nested queries can DoS the server or its
  database.
- Aliases used to call the same expensive resolver multiple times in
  one request, bypassing per-operation rate limits.
- Subscriptions over WebSocket lacking auth on the upgrade or the
  per-message handler.

## Protection And Bypass Themes

- Combine introspection with alias enumeration to map all reachable
  fields per role.
- For node IDs, decode and substitute the numeric/UUID portion across
  tenants and across types.
- For batched queries, look for first-query auth that gates subsequent
  ones in the same batch.
- For persisted queries, try sending a new operation with a fake hash;
  some servers fall back to executing the supplied query.
- For custom scalars (DateTime, JSON, Upload), test injection through
  the scalar serializer.
- Federation: verify that the gateway's auth covers all subgraph
  fields, not just public ones.

## Safe Validation

- Use owned accounts in two roles or two tenants. Read or modify only
  your own data.
- Use small batches and small queries; do not run complexity bombs
  against production.
- For introspection, read the schema once and stop; do not loop.

## Anti-Patterns

- Sending nested-fragment depth bombs as proof of DoS.
- Reporting "introspection enabled" without showing a sensitive
  schema element it exposes that maps to a real authorization gap.
- Confusing field selection with field-level authorization; "the field
  is queryable" only matters if its value crosses an access boundary.
