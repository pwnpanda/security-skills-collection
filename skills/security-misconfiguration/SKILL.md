---
name: security-misconfiguration
description: >-
  Use when authorized testing involves cloud, framework, storage, headers, CORS,
  debug, admin, default credentials, container, CI/CD, or environment
  misconfiguration.
---

# Security Misconfiguration

OWASP mapping: A6:2017, A05:2021, and A02:2025 Security Misconfiguration.

## Workflow

1. Read `../../references/scope-safety.md` and the relevant section of
   `../../references/high-signal-must-tests.md`.
2. Inventory externally observable configuration and relevant source or
   infrastructure configuration.
3. Compare intended exposure against actual exposure.
4. Validate impact with passive checks first and minimal authenticated probes.
5. Write findings with `../../references/finding-output.md`.

## Where To Look

- HTTP headers, CORS, cookies, CSP, TLS, debug modes, stack traces, directory
  listing, admin panels, storage buckets, CDN rules, and reverse proxies.
- Kubernetes, Docker, serverless, cloud IAM, object storage, queues, databases,
  and managed services.
- Framework defaults, staging routes, health checks, metrics, docs, OpenAPI, and
  test endpoints.

## Common Patterns

- Debug, verbose errors, or development defaults exposed in production.
- Overbroad CORS, permissive storage policies, public buckets, or weak cookie
  flags.
- Admin and observability endpoints protected by obscurity or network assumptions.
- Security headers present but ineffective because of unsafe directives.

## Protection And Bypass Themes

- Check alternate hostnames, ports, paths, regions, methods, and content types.
- Compare browser-enforced protections with direct API access.
- Review precedence across CDN, proxy, application, framework, and service
  defaults.
- Test whether staging, preview, and tenant-specific domains inherit weaker
  configuration.

## Safe Validation

- Prefer non-invasive reads and headers.
- Do not modify infrastructure or access data outside scope. Demonstrate exposure
  with metadata, synthetic objects, or controlled accounts.
