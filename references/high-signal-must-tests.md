# High-Signal Must Tests

Use this reference when a skill needs concrete test ideas, bypass themes, or
gotchas. Keep validation inside the scope and safety rules in `scope-safety.md`.

## Open Redirects

Open redirect coverage was missing from the first pass. Treat it as a must-test
class whenever a feature accepts a destination URL, path, route, callback, or
return location.

High-signal parameters:

- `redirect`
- `redirect_url`
- `redirect_uri`
- `return`
- `return_to`
- `next`
- `url`
- `target`
- `destination`
- `continue`
- `callback`
- `goto`
- `RelayState`

High-signal locations:

- login, logout, registration, password reset, invite acceptance, and email
  verification
- OAuth/OIDC/SAML `redirect_uri`, `state`, callback, and relay-state flows
- payment checkout, file download, link shortener, support, and marketing links
- SSRF-capable URL fetchers that follow redirects after validation

Protection and bypass themes:

- absolute URLs, scheme-relative URLs, backslashes, encoded slashes, and
  double-encoded values
- userinfo syntax, fragments, mixed case schemes, trailing dots, IDNA, and
  homograph-like domains
- suffix and substring allowlist mistakes such as `trusted.com.evil.example`
- path-based redirects that become external after decoding or proxy rewriting
- chained impact into OAuth account takeover, token leakage, phishing, SSRF, or
  CSP bypass

Safe validation:

- use a self-owned destination and a unique marker
- prove redirect control without collecting tokens or third-party data

## Broken Access Control, IDOR, And BOLA

High-signal must tests:

- object IDs in path, query, JSON body, GraphQL variables, headers, and batch
  requests
- parent object authorized but nested child object not authorized
- read allowed correctly, but write, delete, export, invite, transfer, or
  metadata access missing authorization
- tenant slug, organization ID, team ID, user ID, invoice ID, file ID, and
  external provider IDs
- archived, deleted, disabled, pending, transferred, invited, or shared objects
- alternate clients: mobile, API, GraphQL, admin, support, and old API versions
- hidden role or ownership fields accepted through mass assignment

Gotchas:

- check server-side authorization after object lookup and canonicalization
- test batch and search endpoints because they often bypass per-object checks
- verify negative cases with two owned accounts in different roles or tenants

## Authentication, OAuth, And JWT

High-signal must tests:

- session rotation after login, MFA, password reset, SSO linking, and role change
- token reuse after logout, password change, email change, MFA reset, and account
  deactivation
- account linking with unverified email, recycled email, wrong issuer, wrong
  tenant, or duplicate identity
- OAuth/OIDC `redirect_uri` exact matching, `state`, `nonce`, `aud`, `iss`,
  `sub`, `email_verified`, and PKCE handling
- JWT algorithm confusion, missing audience or issuer, weak key selection,
  untrusted key URLs, key ID lookup, and missing purpose binding
- recovery-code, magic-link, passkey, and device-trust downgrade paths

Gotchas:

- distinguish identity proofing from authentication strength
- check assurance level for high-risk actions, not only login
- test local-login fallback when SSO or MFA is configured

## Cross-Site Request Forgery

High-signal must tests:

- every authenticated state-changing action, including profile changes, email
  changes, password changes, MFA changes, payout changes, role changes, invites,
  deletes, exports, and integration changes
- GET endpoints that mutate state or trigger side effects
- JSON endpoints that also accept form, multipart, text, method override, or
  alternate content types
- CSRF tokens bound only to session but not action, user, tenant, method, or
  freshness where stronger binding is expected
- missing or weak `Origin` and `Referer` validation on sensitive actions
- SameSite assumptions weakened by subdomains, redirects, OAuth flows, old
  browsers, mobile WebViews, or cross-site top-level navigation
- login CSRF and account-linking CSRF where the attacker can bind a victim to an
  attacker-controlled account or integration

Gotchas:

- CORS does not prevent CSRF; it controls browser read access to responses
- custom headers usually force preflight, but alternate content types may bypass
  that assumption
- prove with owned accounts and harmless state changes only

## Injection

High-signal must tests:

- search, filter, sort, order, group, export, report, and analytics parameters
- JSON objects or arrays accepted where scalar values are expected
- raw SQL, NoSQL operators, aggregation pipelines, LDAP filters, XPath, template
  expressions, search DSLs, and command wrappers
- identifiers, field names, table names, order clauses, and operators, not only
  quoted values
- duplicate parameters, nested objects, alternate content types, nulls, booleans,
  and numeric/string type changes
- importers, webhook processors, background jobs, and admin-only tools

Gotchas:

- "parameterized" often protects values but not identifiers or operators
- escaping for one interpreter does not protect another interpreter later
- validation before decoding, normalization, or ORM expansion is brittle

## Cross-Site Scripting

High-signal must tests:

- every reflected parameter rendered into HTML, attribute, URL, JavaScript, CSS,
  SVG, markdown, or rich-text contexts
- stored content rendered in admin, moderation, support, email, export, PDF,
  mobile WebView, or embedded widget contexts
- DOM sources: query string, fragment, local storage, postMessage, server JSON,
  and URL path segments
- DOM sinks: `innerHTML`, dangerous template helpers, framework bypass APIs,
  linkifiers, markdown renderers, and syntax highlighters
- sanitizer output later transformed by mentions, link previews, emoji, or
  markdown processing

Gotchas:

- classify the exact output context before choosing a test string
- compare sanitizer behavior with the browser parser and framework hydration
- check CSP for practical script execution paths, not just header presence

## Server-Side Request Forgery

High-signal must tests:

- link previews, webhooks, callbacks, media importers, file importers, document
  converters, RSS readers, screenshot services, and proxy endpoints
- validation before redirects, final DNS resolution, proxy rewrite, or socket
  connection
- private IPs, IPv6, unusual numeric host notation, DNS rebinding, trailing dots,
  userinfo, IDNA, and mixed parser behavior
- cloud metadata, service mesh, internal admin panels, and localhost-only
  services where in scope

Gotchas:

- disable or revalidate redirects; open redirects can convert an allowed URL into
  an internal or attacker-controlled final URL
- compare the URL parser used for validation with the HTTP client parser
- prove reachability with self-owned callback infrastructure before testing
  internal targets

## XML External Entities

High-signal must tests:

- SOAP, SAML, SVG, DOCX, XLSX, PPTX, plist, RSS, Atom, XML import/export, and
  file converters
- DTDs, external general entities, external parameter entities, XInclude, XSLT,
  schema imports, and network fetches
- XML nested inside archives, office documents, or image formats
- validation or transformation services before business validation

Gotchas:

- disabling one XML feature does not disable all entity or network fetch paths
- upload scanners, converters, and downstream services may use different parsers
- use harmless callbacks or parser errors instead of reading sensitive files

## Sensitive Data Exposure

High-signal must tests:

- fields hidden in UI but returned by API, GraphQL, mobile, export, or search
- secrets, reset links, tokens, PII, and payment data in logs, analytics, crash
  reports, browser storage, URLs, referrers, and emails
- CDN/browser caches, object metadata, backups, debug endpoints, source maps, and
  support dashboards
- data visible after revoke, delete, tenant change, role change, or object
  transfer

Gotchas:

- masking at display time is not access control
- GraphQL and mobile APIs often expose fields absent from web UI
- use synthetic or self-owned sensitive data only

## Security Misconfiguration, CORS, And Host Headers

High-signal must tests:

- reflected or regex-matched `Origin`, `Access-Control-Allow-Credentials: true`,
  `null` origins, and trusted-domain suffix mistakes
- password reset, invite, webhook, and absolute-link generation influenced by
  `Host`, `X-Forwarded-Host`, `Forwarded`, or proxy headers
- debug modes, stack traces, environment dumps, OpenAPI docs, metrics, health,
  admin, staging, and preview routes
- public storage buckets, permissive object ACLs, weak cookie flags, missing
  security headers, and ineffective CSP

Gotchas:

- CORS is a browser boundary; direct API access still needs authorization
- host header issues often become account takeover through poisoned links
- check CDN, proxy, framework, and app configuration precedence

## Deserialization And Integrity

High-signal must tests:

- signed cookies, session blobs, remember-me tokens, workflow state, queues,
  cache entries, webhook payloads, mobile sync state, and exported/imported data
- type fields, class names, version fields, algorithm fields, purpose fields,
  tenant/user binding, expiry, nonce, and replay protection
- producer verifies integrity but consumer trusts later replay or cache restore
- encrypted-but-not-authenticated data and signatures that do not cover metadata

Gotchas:

- signed does not mean type-safe or purpose-bound
- verify before deserialize, route, authorize, or enqueue
- prove tampering with harmless fields and owned artifacts

## File Upload And Path Traversal

High-signal must tests:

- avatar, attachment, import, document conversion, archive extraction, template,
  theme, plugin, and media-processing paths
- filename, extension, content type, magic bytes, metadata, polyglot files,
  archive entries, symlinks, and nested paths
- `../`, absolute paths, encoded separators, backslashes, Unicode normalization,
  null-like terminators, and platform-specific path quirks
- server-side processing that writes, extracts, serves, converts, or executes the
  uploaded content

Gotchas:

- validate the final canonical path after extraction and symlink resolution
- denylist extension checks are weak; verify allowed types and storage behavior
- prove impact with harmless files and owned storage paths

## API, GraphQL, Mass Assignment, And Prototype Pollution

High-signal must tests:

- hidden writable fields such as `role`, `is_admin`, `owner_id`, `tenant_id`,
  `plan`, `price`, `status`, `verified`, and feature flags
- GraphQL node IDs, global IDs, batching, aliases, fragments, introspection,
  nested resolvers, mutations, and authorization per edge and node
- automatic object binding in JSON, form, multipart, GraphQL, and XML inputs
- JavaScript object merge paths that accept `__proto__`, `constructor`, or
  prototype-like keys

Gotchas:

- read-only UI fields may still be writable through API object binding
- GraphQL authorization must apply at resolver level, not just route level
- prototype pollution impact often appears later in authorization, template, or
  configuration logic

## Request Smuggling And Cache Poisoning

High-signal must tests:

- reverse proxies, CDNs, load balancers, API gateways, H2-to-H1 downgrade paths,
  and origin/proxy parser mismatches
- ambiguous `Content-Length` and `Transfer-Encoding`, duplicate headers, unusual
  whitespace, chunked parsing, and connection reuse behavior
- cache keys missing host, path, query, headers, cookies, or authorization state
- unkeyed inputs: `Host`, `X-Forwarded-*`, scheme headers, language, encoding,
  device, and route override headers

Gotchas:

- these tests can be disruptive; use lab or explicitly allowed targets first
- parser differentials are the root cause, not individual header strings
- prove with self-contained markers and avoid poisoning shared real-user caches

## Components And Supply Chain

High-signal must tests:

- live loaded version versus declared package version
- vendored copies, duplicate frontend bundles, shaded JARs, generated assets,
  source maps, plugins, and themes
- unpinned actions, mutable tags, public package namespace collisions, fallback
  registries, postinstall scripts, and build scripts
- CI triggers that run untrusted pull-request code with secrets or write tokens
- artifact signing, provenance, checksums, and SBOM freshness

Gotchas:

- a CVE is reportable only when the vulnerable path is reachable or risk is
  otherwise concrete for the program
- version disclosure is evidence, not impact by itself
- avoid publishing dependency-confusion packages without explicit permission

## Logging, Monitoring, And Alerting

High-signal must tests:

- login failures, MFA changes, password resets, email changes, role changes,
  admin impersonation, API key creation, exports, and authorization denials
- failed and blocked actions, not only successful actions
- event fields: actor, target, tenant, source IP, user agent, request ID, result,
  role, severity, and correlation ID
- API, mobile, GraphQL, background job, support, and admin paths feeding the same
  audit and alerting pipelines

Gotchas:

- logs can exist but be inaccessible, uncorrelated, mutable, or never alerted on
- redaction must happen before logs, analytics, and crash reports receive secrets
- use a short labeled event sequence to avoid noisy testing

## Exceptional Conditions And Race Conditions

High-signal must tests:

- timeout, retry, duplicate event, partial commit, rollback, parser error, stale
  cache, and dependency failure paths
- payment callbacks, webhook retries, queue consumers, signup, MFA, password
  reset, role changes, imports, exports, and approval workflows
- concurrent requests against one-time tokens, inventory, coupons, approvals,
  state transitions, and rate-limited actions
- fail-open behavior when authorization, payment, MFA, validation, or policy
  services return errors

Gotchas:

- idempotency must bind actor, action, object, amount, and tenant where relevant
- unknown security decisions should fail closed
- use low-impact owned objects and stop once an unsafe state is demonstrated

## Insecure Design And Business Logic

High-signal must tests:

- multi-step workflows that can be skipped, repeated, reordered, replayed, or
  completed in parallel
- discounts, payments, refunds, subscriptions, trial abuse, invite flows,
  approvals, content moderation, quotas, and rate-limited resources
- assumptions enforced only in UI, documentation, support process, or delayed
  reconciliation
- state transitions across pending, verified, paid, approved, invited, disabled,
  archived, and deleted states

Gotchas:

- business logic bugs often have no "payload"; the proof is a violated invariant
- separate observed impact from speculative impact
- avoid financial or operational side effects unless explicitly allowed
