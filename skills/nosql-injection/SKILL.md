---
name: nosql-injection
description: >-
  Use when authorized testing involves MongoDB, CouchDB, DynamoDB, Cassandra,
  Elasticsearch/OpenSearch, Redis, or any document/search store where user
  input is mapped into a query object - filters, aggregation pipelines,
  query DSLs, or JS evaluation contexts.
---

# NoSQL Injection

NoSQL injection is rarely about quote-breaking; it is about *shape*. JSON
APIs that accept user input as part of a query object can change the
semantics of a filter by adding operator keys, switching scalars to
objects, or exploiting permissive parsers that allow expression evaluation.

## Workflow

1. Read `../../references/scope-safety.md` and the Injection section of
   `../../references/high-signal-must-tests.md`.
2. Identify the store and its query model: Mongo BSON filter, Elastic
   query DSL, Couch Mango, Redis command parser, DynamoDB expression
   language, Cassandra CQL.
3. Enumerate every input that maps into the query: filter values, sort,
   projection, aggregation stages, full-text search, scripted fields.
4. Probe for type/shape changes: scalar -> object, scalar -> array,
   operator-key injection (`$ne`, `$gt`, `$regex`, `$where`), and
   expression evaluation when the engine permits it.
5. Validate with bounded blind oracles (boolean, regex match, or time-
   based via `$where` / scripted fields) using owned tenant data.
6. Write findings with `../../references/finding-output.md`. State the
   shape change and the security boundary that broke.

## Where To Look

- Login endpoints accepting JSON: `{"username":"x","password":"y"}` -
  try `{"username":"x","password":{"$ne":null}}`.
- Search/filter APIs that accept structured filters.
- Aggregation pipelines where stages can be supplied or extended from
  user input.
- Scripted field features (Mongo `$where`, Elastic `script_fields`,
  Couch `_view` with map functions).
- Bulk APIs and import jobs that accept query objects.
- GraphQL resolvers that pass filter objects directly to the store.

## Common Patterns

- Endpoint parses JSON then forwards values into a `find()` call without
  rejecting nested object operands.
- Frontend strips operator keys client-side; the server trusts the body.
- Sanitizer removes `$` at the top level but misses nested objects or
  encoded keys (`$ne`).
- Authorization filter built as an object that the attacker can append
  to via array merging.
- Engine permits arbitrary script evaluation in queries (Mongo `$where`,
  old CouchDB list functions) when not explicitly disabled.

## Protection And Bypass Themes

- Try changing a scalar to an object: `username=admin` becomes
  `username[$ne]=` (form encoding) or `{"username":{"$ne":null}}` (JSON).
- Try `$regex` for boolean inference: `{"username":{"$regex":"^a"}}`.
- For Elasticsearch, try `query_string` with Lucene injection that
  changes field scope, or `script` clauses if `inline` scripts are
  enabled.
- For Redis, look for raw command construction from user input (CRLF in
  values can split commands).
- For DynamoDB, look for expression-attribute-name/value injection in
  filter or condition expressions.
- Unicode-escaped operator keys may bypass naive `$`-strippers.

## Safe Validation

- Prefer boolean or regex oracles over data extraction. Show the bug
  with a 1-vs-many result delta on owned data.
- For scripted-field execution, prefer an OAST callback
  (`../oast-testing/SKILL.md`) over data dumps.
- Time-based: use bounded operations only.

## Anti-Patterns

- Reporting `{"username":{"$ne":null}}` against a login endpoint without
  showing authentication actually bypassed (some endpoints reject the
  shape change).
- Dumping collections or indexes when boolean inference would have
  proven the primitive.
- Confusing client-side filter mismatch with server-side injection.
