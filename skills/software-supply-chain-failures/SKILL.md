---
name: software-supply-chain-failures
description: >-
  Use when authorized testing involves dependency confusion, package trust,
  build systems, artifact signing, CI/CD integrity, registries, provenance,
  update channels, or third-party code ingestion.
---

# Software Supply Chain Failures

OWASP mapping: A03:2025 Software Supply Chain Failures. Evolved from dependency
hygiene categories in earlier OWASP editions.

## Workflow

1. Read `../../references/scope-safety.md` and the relevant section of
   `../../references/high-signal-must-tests.md`.
2. Map the software supply chain: source, dependency registry, build runner,
   artifact store, signing, deployment, update, and runtime loading.
3. Identify trust decisions and where untrusted code or artifacts can enter.
4. Validate with inert packages, private namespace checks, or configuration
   review only when allowed.
5. Write findings with `../../references/finding-output.md`.

## Where To Look

- CI/CD workflows, package manifests, private registry config, build scripts,
  Dockerfiles, deployment manifests, release automation, and update mechanisms.
- GitHub Actions, reusable workflows, third-party actions, package scripts,
  postinstall hooks, plugins, browser extensions, and mobile update channels.
- Artifact repositories, object storage, SBOMs, provenance, signing, and
  environment secrets.

## Common Patterns

- Public package namespace can shadow a private package.
- CI trusts pull-request code with secrets or write tokens.
- Actions, images, or dependencies are pinned by mutable tags.
- Build artifacts are consumed without signature, provenance, or checksum
  verification.

## Protection And Bypass Themes

- Check registry precedence, scoped packages, typo-confusable names, and fallback
  registries.
- Review token permissions, workflow triggers, fork behavior, and secret
  availability in CI.
- Check whether pinned versions are immutable: commit SHA, digest, lockfile, and
  verified provenance.
- Inspect plugin and extension ecosystems that run code inside trusted build or
  admin contexts.

## Safe Validation

- Do not publish confusing public packages or tamper with production builds
  without explicit written permission.
- Prefer read-only configuration proof, inert private packages, and controlled
  non-production pipelines.
