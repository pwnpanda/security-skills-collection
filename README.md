# Bounty Skills

Cybersecurity skills for authorized bug bounty and vulnerability research.

The collection is structured for day-to-day bounty work: a small set of OWASP-
derived taxonomy skills sits alongside a larger set of specialist skills, one
per attack technique. Skills built around defender-only visibility (SIEM
coverage, alert routing) are intentionally excluded because external testers
cannot validate them.

## Sources

- OWASP Top Ten 2017: https://owasp.org/www-project-top-ten/2017/
- OWASP Top 10 2021: https://owasp.org/Top10/2021/
- OWASP Top 10 2025: https://owasp.org/Top10/2025/0x00_2025-Introduction/

## Layout

- `docs/owasp-top10-union.md` - OWASP edition mapping and dedupe record.
- `docs/critical-content-review.md` - review findings and backlog status.
- `references/scope-safety.md` - shared safety rules for authorized testing.
- `references/finding-output.md` - shared finding and evidence format.
- `references/high-signal-must-tests.md` - concrete test cases, bypass
  themes, and gotchas for the skills.
- `skills/*/SKILL.md` - one skill per technique or OWASP category.
- `evals/evals.json` - one review prompt per skill.
- `evals/high-signal-evals.json` - prompts for bypass and gotcha coverage.

## Skill Layers

**Taxonomy skills** (`skills/`): broad OWASP-derived categories used for
audit routing and as the entry point when the bug class is not yet clear.

- `injection`, `cross-site-scripting`, `broken-access-control`,
  `server-side-request-forgery`, `xml-external-entities`,
  `insecure-deserialization`, `sensitive-data-exposure`,
  `cryptographic-failures`, `security-misconfiguration`, `insecure-design`,
  `mishandling-exceptional-conditions`, `software-supply-chain-failures`.
- `authentication` (consolidates OWASP 2017 Broken Authentication / 2021
  Identification and Authentication Failures / 2025 Authentication Failures).
- `vulnerable-components` (consolidates 2017 Using Components with Known
  Vulnerabilities / 2021 Vulnerable and Outdated Components).
- `integrity-failures` (consolidates 2021 / 2025 integrity categories).

**Specialist skills**: one technique per skill, with discovery / patterns /
bypass / safe validation / anti-patterns. These are the day-to-day entry
points.

OAST-class:

- `oast-testing` - shared OAST workflow and marker discipline.
- `blind-xss` - stored XSS in privileged or out-of-band render sinks.
- `blind-ssrf` - server-side fetchers without visible response.
- `blind-ssti` - template injection where rendered output is hidden.
- `client-side-path-traversal` - CSPT discovery and impact chains.

Injection family:

- `sql-injection`, `nosql-injection`, `command-injection`.

URL / redirect / cross-origin:

- `open-redirect`, `cors-misconfiguration`, `host-header-injection`.

Web state and auth:

- `csrf`, `mass-assignment`, `prototype-pollution`, `race-conditions`,
  `oauth-oidc`, `jwt-jose`.

API / files:

- `graphql-api-security`, `file-upload`, `path-traversal-lfi`.

Infra / protocol:

- `request-smuggling`, `cache-poisoning`.

Email:

- `email-testing` - splitting the email atom (RFC parser tricks), SMTP
  header injection, subaddressing SSTI, multi-address smuggling.

## Excluded By Design

The 2017 / 2021 / 2025 logging-and-monitoring OWASP categories were removed
in the 2026-05-24 dedupe. External bounty testers cannot read the target's
SIEM, alert routing, or audit pipeline; skills built around that visibility
have no actionable test plan. Stack-trace leaks and account-activity-log
disclosure stay under `sensitive-data-exposure` and `security-
misconfiguration`.

## Quality Gates

- Frontmatter descriptions should start with `Use when` and describe trigger
  conditions only.
- Skill bodies should reference shared safety and finding-output guidance.
- Each skill should include where to look, common patterns, protection and
  bypass themes, safe validation, and anti-patterns.
- Each skill should have at least one pressure prompt in `evals/evals.json`.

## Claude Sessions

| Session | Summary | Date |
|---------|---------|------|
| `bounty-skills-owasp-map` | Drafted the OWASP 2017/2021/2025 union skill set. | 2026-05-24 |
| `bounty-skills-critical-review` | Tightened metadata and added eval prompts. | 2026-05-24 |
| `bounty-skills-depth-review` | Added high-signal test coverage notes. | 2026-05-24 |
| `bounty-skills-oast-specialists` | Added oast-testing, blind-xss, blind-ssrf, blind-ssti, and client-side-path-traversal specialist skills with matching evals. | 2026-05-24 |
| `bounty-skills-dedupe-and-backlog` | Dropped 3 logging skills, merged 7 OWASP duplicates into 3 consolidated skills (`authentication`, `vulnerable-components`, `integrity-failures`), and added 17 specialist skills covering open-redirect, csrf, file-upload, path-traversal-lfi, command-injection, sql-injection, nosql-injection, oauth-oidc, jwt-jose, cors-misconfiguration, host-header-injection, mass-assignment, graphql-api-security, prototype-pollution, race-conditions, request-smuggling, cache-poisoning. | 2026-05-24 |
| `bounty-skills-email-testing` | Added email-testing skill covering splitting the email atom (PortSwigger 2024 research), SMTP header injection, subaddressing template injection, multi-address smuggling, and Unicode/IDNA tricks. | 2026-05-24 |
