---
name: vulnerable-components
description: >-
  Use when authorized testing involves dependency inventory, known CVEs in
  libraries, frameworks, runtimes, containers, CMS plugins, or transitive
  packages - and whether the vulnerable code path is reachable in the target.
---

# Vulnerable Components

OWASP mapping: consolidates A9:2017 Using Components with Known
Vulnerabilities and A06:2021 Vulnerable and Outdated Components. For build,
CI/CD, registry, and signing concerns use `../software-supply-chain-failures/
SKILL.md`.

## Workflow

1. Read `../../references/scope-safety.md` and the Components And Supply
   Chain section of `../../references/high-signal-must-tests.md`.
2. Build a component inventory from every visible source: lockfiles, package
   manifests, SBOMs, container images, server banners, JavaScript bundles,
   source maps, CMS plugins, debug endpoints, `/version`, `/health`.
3. Match observed versions to advisories. Note both **declared** and
   **runtime-loaded** versions; they often differ.
4. For each candidate CVE, determine reachability: is the vulnerable feature
   enabled, the vulnerable parser/route exposed, and the prerequisite
   configuration present?
5. Validate with non-destructive proof: version evidence plus a reachability
   probe with a harmless marker, or a local lab reproduction.
6. Write findings with `../../references/finding-output.md`.

## Where To Look

- Package manifests, lockfiles, SBOMs, Dockerfiles, container manifests,
  Helm charts, deployment YAMLs.
- HTTP response headers (`Server`, `X-Powered-By`, framework cookies),
  error pages, default pages, admin login pages, debug routes.
- JavaScript bundles, source maps, vendored libraries, shaded JARs, CMS
  plugin lists, theme files, browser extension manifests.
- Runtime disclosure: Node/Python/Java/PHP versions in stack traces, ETag
  hashes, Last-Modified timestamps, vendor banners.

## Common Patterns

- Scanner reports a CVE but the vulnerable route is not reachable; report
  needs reachability evidence to land.
- Frontend library is vulnerable only when a specific plugin or sink is
  used; check actual call sites.
- Patched package exists in one service but an older copy remains vendored
  or bundled elsewhere.
- Container base image includes vulnerable utilities that are not used by
  the running app; low priority.
- Microservices share a monorepo but version dependencies inconsistently.

## Protection And Bypass Themes

- Verify the **loaded** version, not only the **declared** version. Sometimes
  the lockfile says one thing and the running runtime loads another.
- Check duplicate copies: CDN assets, vendored code, shaded JARs, generated
  bundles, Docker layers.
- Map advisory prerequisites (feature flags, enabled parsers, specific
  endpoints) to the target's actual configuration.
- A WAF may block one known exploit path while leaving an equivalent path
  untouched; check parser/route parity.

## Safe Validation

- Avoid running public exploit chains unless explicitly allowed.
- Prefer passive version evidence plus a reachable, harmless behavior probe.
- For verifying impact in lab, use a local instance matching the target's
  version and configuration; do not exfiltrate from production.

## Anti-Patterns

- Reporting a version disclosure as if it were impact. Version disclosure
  is evidence; the bug is the reachable behavior.
- Reporting a CVE that requires admin or local access when the program
  scope is unauthenticated external testing.
- Treating one vulnerable transitive dependency in `node_modules` as a
  finding without checking whether the actual application code reaches it.
