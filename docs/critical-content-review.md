# Critical Content Review

Date: 2026-05-24 (updated after dedupe + specialist backlog)

Scope: full repository content; whether skills include enough concrete bug
bounty technique, bypass, and gotcha coverage; whether OWASP-derived
duplicates have been consolidated; whether defender-only content remains.

## Findings

### High: OWASP Categories Were Too Abstract

The first-pass skills mapped OWASP category titles correctly, but several
categories were too broad for practical bug bounty use. A future agent using
only a taxonomy skill could miss high-signal test cases such as open redirect
parameters, mass assignment fields, GraphQL node authorization, CORS origin
reflection, request smuggling parser differentials, and file-upload path
issues.

Action taken:

- Added `references/high-signal-must-tests.md`.
- Linked every `skills/*/SKILL.md` workflow to the high-signal reference.
- Promoted every flagged high-signal class to a dedicated specialist skill
  (see Specialist Backlog below).

### High: Specialist Backlog Implemented

All 17 specialist skills from the original backlog have been written,
plus 5 OAST/CSPT specialists. Each follows the same template:
description-only frontmatter, workflow, where to look, common patterns,
protection and bypass themes, safe validation, anti-patterns.

OAST-class specialists:

- `oast-testing` - shared OAST workflow and marker discipline.
- `blind-xss`, `blind-ssrf`, `blind-ssti` - blind classes with marker
  attribution.
- `client-side-path-traversal` - CSPT.

Backlog specialists:

- `open-redirect`, `csrf`, `file-upload`, `path-traversal-lfi`,
  `command-injection`, `sql-injection`, `nosql-injection`,
  `oauth-oidc`, `jwt-jose`, `cors-misconfiguration`,
  `host-header-injection`, `mass-assignment`, `graphql-api-security`,
  `prototype-pollution`, `race-conditions`, `request-smuggling`,
  `cache-poisoning`.

### High: OWASP Duplicates Consolidated

The first pass kept one skill per unique OWASP title. Across three editions
this produced three near-identical authentication skills, three logging
skills, two near-identical components skills, and two near-identical
integrity skills.

Action taken:

- Merged the auth trio into `authentication`.
- Merged the components pair into `vulnerable-components` (kept
  `software-supply-chain-failures` separate).
- Merged the integrity pair into `integrity-failures` (kept
  `insecure-deserialization` separate).
- Removed all 3 logging skills entirely (see next finding).
- Updated `docs/owasp-top10-union.md` with the consolidation table.

### High: Defender-Only Logging Skills Removed

The 2017 / 2021 / 2025 logging-and-monitoring OWASP categories were removed.

Rationale: external bug bounty testers cannot read the target's SIEM, alert
routing, audit pipeline, correlation rules, or responder dashboards. A skill
that asks "is this event logged and alerted?" produces no actionable
black-box test plan. Stack-trace leaks and account-activity-log disclosure
stay in scope through `sensitive-data-exposure` and
`security-misconfiguration`.

Removed:

- `insufficient-logging-monitoring` (2017 A10)
- `security-logging-monitoring-failures` (2021 A09)
- `security-logging-alerting-failures` (2025 A09)

### Medium: Evaluation Prompts Now Cover Every Skill

The eval suite was rewritten in step with the dedupe and specialist
expansion. Every current skill has at least one prompt in
`evals/evals.json`. The `evals/high-signal-evals.json` set provides
additional bypass/gotcha-specific prompts and stays untouched.

### Low: Open Redirect Coverage

Open redirects were already a section of `high-signal-must-tests.md` from
the prior session; the 2026-05-24 pass added a dedicated `open-redirect`
specialist skill linked from the OAuth, SSRF, and CSRF specialists.

## External References Used For Review

- OWASP Unvalidated Redirects and Forwards Cheat Sheet
- OWASP SSRF Prevention Cheat Sheet
- OWASP File Upload Cheat Sheet
- OWASP XSS Prevention Cheat Sheet
- OWASP Mass Assignment Cheat Sheet
- OWASP GraphQL Cheat Sheet
- OWASP JWT for Java Cheat Sheet
- OWASP OAuth2 Cheat Sheet
- OWASP WSTG Testing for HTTP Request Smuggling
- PortSwigger research on HTTP/2 desync and web cache deception
- James Kettle, Smashing The State Machine (race-condition technique)
