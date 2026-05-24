---
name: injection
description: >-
  Use when authorized testing involves SQL, NoSQL, OS command, LDAP, template,
  expression-language, search, filter, query-builder, shell, or other
  interpreter injection.
---

# Injection

OWASP mapping: A1:2017 Injection, A03:2021 Injection, A05:2025 Injection.

## Workflow

1. Read `../../references/scope-safety.md` and the relevant section of
   `../../references/high-signal-must-tests.md`.
2. Identify every interpreter boundary: database query, shell, template engine,
   expression parser, search DSL, LDAP query, XPath, GraphQL resolver, or
   deserialization hook that executes expressions.
3. Trace user-controlled data into the boundary and note validation,
   normalization, escaping, parameterization, and privilege separation.
4. Prefer code review and single-request probes before active fuzzing.
5. Write findings with `../../references/finding-output.md`.

## Where To Look

- Search, sort, filter, export, report, analytics, admin, and bulk-action paths.
- Login, password reset, registration, invite, SSO, and tenant-selection inputs.
- API parameters that accept operators, JSON objects, arrays, field names, or raw
  snippets of query language.
- Background jobs, webhook processors, importers, CSV/XML/JSON parsers, and
  integrations that turn data into commands or queries.

## Common Patterns

- String-built queries with partial parameterization.
- Escaped values mixed with unescaped identifiers, operators, order clauses, or
  field names.
- ORM escape hatches such as raw SQL, dynamic scopes, raw filters, or unsafe
  aggregation pipelines.
- Shell wrappers that concatenate arguments or pass user data through a shell.
- Template or expression engines exposed through user-controlled content.

## Protection And Bypass Themes

- Confirm whether protections apply to values only or also to identifiers,
  operators, paths, and clauses.
- Check canonicalization order: decode, normalize, validate, then execute.
- Look for parser differentials between frontend validation, backend validation,
  proxies, ORMs, and the final interpreter.
- Test type confusion, array/object parameters, duplicate parameters, nested
  objects, nulls, and alternate content types where the app already supports them.
- Check whether allowlists are applied before or after aliases, joins,
  projections, or framework-specific expansion.

## Safe Validation

- Use benign predicates, timing-safe indicators only when allowed, self-owned
  records, and reversible state changes.
- Do not dump data. Prove boundary crossing with a marker, count difference, role
  change, or controlled command effect.
