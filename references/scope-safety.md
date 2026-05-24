# Scope And Safety

Use these rules for every skill in this repository.

## Authorization

- Work only on owned systems, lab targets, or explicitly in-scope bug bounty
  assets.
- Record the program, asset, account, and permission boundary before testing.
- Prefer observation and low-impact probes before active mutation.
- Do not test third-party tenants, users, or data.

## Proof Standard

- Prove practical influence with unique markers, self-owned accounts, and
  reversible state changes.
- Avoid destructive payloads, persistence, stealth, mass scanning, credential
  capture, or data exposure beyond the minimum needed for proof.
- Stop once impact is demonstrated clearly enough for a report.

## Evidence

- Save exact requests, responses, timestamps, accounts, roles, and object IDs.
- Note negative tests and protections that worked.
- Preserve reproduction steps so a triager can verify the issue without guessing.

## Reporting

- State affected assets and prerequisites.
- Separate observed impact from plausible impact.
- Include a remediation path that matches the root cause.
