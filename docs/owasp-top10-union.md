# OWASP Top 10 Union

This file records the OWASP 2017, 2021, and 2025 categories and how they map
into the current `skills/` collection. The first pass kept one skill per
unique OWASP title; the 2026-05-24 dedupe collapsed near-duplicates into
consolidated skills and removed defender-only logging categories.

## Source Lists

### 2017

| Rank | Category | Current skill |
|------|----------|---------------|
| A1 | Injection | `injection` |
| A2 | Broken Authentication | `authentication` *(consolidated)* |
| A3 | Sensitive Data Exposure | `sensitive-data-exposure` |
| A4 | XML External Entities (XXE) | `xml-external-entities` |
| A5 | Broken Access Control | `broken-access-control` |
| A6 | Security Misconfiguration | `security-misconfiguration` |
| A7 | Cross-Site Scripting (XSS) | `cross-site-scripting` |
| A8 | Insecure Deserialization | `insecure-deserialization` |
| A9 | Using Components with Known Vulnerabilities | `vulnerable-components` *(consolidated)* |
| A10 | Insufficient Logging & Monitoring | *removed - defender-only visibility* |

### 2021

| Rank | Category | Current skill |
|------|----------|---------------|
| A01 | Broken Access Control | `broken-access-control` |
| A02 | Cryptographic Failures | `cryptographic-failures` |
| A03 | Injection | `injection` |
| A04 | Insecure Design | `insecure-design` |
| A05 | Security Misconfiguration | `security-misconfiguration` |
| A06 | Vulnerable and Outdated Components | `vulnerable-components` *(consolidated)* |
| A07 | Identification and Authentication Failures | `authentication` *(consolidated)* |
| A08 | Software and Data Integrity Failures | `integrity-failures` *(consolidated)* |
| A09 | Security Logging and Monitoring Failures | *removed - defender-only visibility* |
| A10 | Server-Side Request Forgery (SSRF) | `server-side-request-forgery` |

### 2025

| Rank | Category | Current skill |
|------|----------|---------------|
| A01 | Broken Access Control | `broken-access-control` |
| A02 | Security Misconfiguration | `security-misconfiguration` |
| A03 | Software Supply Chain Failures | `software-supply-chain-failures` |
| A04 | Cryptographic Failures | `cryptographic-failures` |
| A05 | Injection | `injection` |
| A06 | Insecure Design | `insecure-design` |
| A07 | Authentication Failures | `authentication` *(consolidated)* |
| A08 | Software or Data Integrity Failures | `integrity-failures` *(consolidated)* |
| A09 | Security Logging & Alerting Failures | *removed - defender-only visibility* |
| A10 | Mishandling of Exceptional Conditions | `mishandling-exceptional-conditions` |

## Consolidations

| Consolidated skill | Replaced |
|--------------------|----------|
| `authentication` | `broken-authentication`, `identification-authentication-failures`, `authentication-failures` |
| `vulnerable-components` | `using-components-known-vulnerabilities`, `vulnerable-outdated-components` |
| `integrity-failures` | `software-data-integrity-failures`, `software-or-data-integrity-failures` |

`software-supply-chain-failures` stays separate from `vulnerable-components`
because CI/build/registry/provenance content is qualitatively different from
runtime-version reachability.

`insecure-deserialization` stays separate from `integrity-failures` because
the gadget-chain and type-confusion technique content is qualitatively
different from generic producer/consumer integrity gaps.

## Removed (Defender-Only Visibility)

The 2017 / 2021 / 2025 logging-and-monitoring categories were removed because
external bug bounty testers cannot read the target's SIEM, alert routing,
audit pipeline, or correlation rules. Stack-trace leaks and account-activity
log disclosure remain in scope through `sensitive-data-exposure` and
`security-misconfiguration`.

- 2017 A10 Insufficient Logging & Monitoring
- 2021 A09 Security Logging and Monitoring Failures
- 2025 A09 Security Logging & Alerting Failures
