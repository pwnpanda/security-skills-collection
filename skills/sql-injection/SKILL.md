---
name: sql-injection
description: >-
  Use when authorized testing involves SQL or SQL-like query construction
  from user input - search/filter/sort/order parameters, identifiers, field
  selection, custom-query builders, reporting/analytics, batch operations,
  importers, or any endpoint where user input may reach a SQL parser even
  through an ORM.
---

# SQL Injection

SQL injection is alive and well in 2026: ORMs protect *values* but rarely
protect *identifiers*, *operators*, *clauses*, or *raw fragments*. Modern
findings hide in sort orders, field selection, computed columns, reporting
builders, and second-order paths (a value that was stored cleanly but is
later interpolated into a query).

## Workflow

1. Read `../../references/scope-safety.md` and the Injection section of
   `../../references/high-signal-must-tests.md`.
2. Enumerate every input class: scalar values, identifiers (table/column
   names), operators, order/group clauses, JSON/array values, multi-value
   filters, raw-SQL fields, reporting expressions, importer column maps.
3. Classify the sink: parameterized query, ORM expression builder, raw
   string interpolation, query builder with identifier helpers, search DSL
   that compiles to SQL.
4. Choose probes appropriate to the sink: classic quote-break for
   string values, type coercion for numeric, identifier-list smuggling for
   sort/group, boolean/time-based blind for non-reflective sinks.
5. Validate with bounded blind proof (time delays, boolean inference, or
   error-based) using owned tenant data.
6. Write findings with `../../references/finding-output.md`. State which
   parameter class is vulnerable and which protection layer failed.

## Where To Look

- Search, filter, sort, order, group-by, limit, offset, page, cursor.
- Field-selection parameters (`fields=`, `include=`, `expand=`,
  `select=`).
- Reporting and analytics builders with user-supplied expressions.
- Importer column maps, custom queries in admin tools, scheduled-report
  definitions.
- Bulk endpoints that accept arrays of IDs or filter objects.
- Second-order: a stored field that is later used as part of a query
  (display name in an audit query, tag in a saved-filter query).

## Common Patterns

- ORM parameterizes values but builds the order clause from a request
  parameter string.
- "Safe" identifier helpers that allow alphanumerics plus underscore but
  still accept comma-separated column lists used as injection vectors.
- JSON-shaped query inputs (e.g. `{"status": {"$in": [...]}}`) where the
  query builder accepts operator keys from user input.
- Numeric ID handling that calls `int(x)` after the value has been used
  in a string concat.
- Backend that switches between database engines for different tenants,
  exposing engine-specific syntax differences.

## Protection And Bypass Themes

- For identifiers, test quoted vs unquoted, schema-qualified, alternate
  case, leading whitespace, comment markers (`/* */`, `--`, `#`).
- For order clauses, send a function (`,(SELECT SLEEP(2))`) or a CASE
  expression for blind inference.
- For numeric coercion, test floats, scientific notation, hex literals,
  embedded comments, and database-specific operators.
- Stacked queries (`; DROP TABLE ...`) rarely work in modern drivers - do
  not propose destructive proofs.
- Out-of-band SQLi: some engines support DNS/HTTP exfil via UDF or
  load_file/UNC paths - use OAST (`../oast-testing/SKILL.md`) when
  available.

## Safe Validation

- For boolean blind, use a clear two-value oracle (`AND 1=1` vs
  `AND 1=2`) and stop at confirmation.
- For time-based, use bounded sleeps (1-3 seconds) and verify a
  reproducible delta; do not chain dozens of inferences against
  production.
- Read only your own tenant's data; do not dump tables or extract other
  users' rows. Schema disclosure plus a one-row test is enough.

## Anti-Patterns

- Running `sqlmap` against production with default `--dump` flags. Most
  programs reject this as out-of-scope automated testing.
- Reporting "ORM not used here" as a finding without a working injection
  primitive.
- Destructive proofs (`DROP`, `DELETE`, `UPDATE`) even when allowed by
  the parameter - find a read primitive instead.
