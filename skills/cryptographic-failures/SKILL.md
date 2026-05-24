---
name: cryptographic-failures
description: >-
  Use when authorized testing involves encryption, hashing, signing, randomness,
  key management, TLS, token protection, secrets handling, password storage, or
  cryptographic protocol misuse.
---

# Cryptographic Failures

OWASP mapping: A02:2021 and A04:2025 Cryptographic Failures. Related to 2017
Sensitive Data Exposure.

## Workflow

1. Read `../../references/scope-safety.md` and the relevant section of
   `../../references/high-signal-must-tests.md`.
2. Identify the asset being protected, threat model, algorithm, mode, key source,
   key lifetime, and verification path.
3. Check whether confidentiality, integrity, authenticity, and freshness are all
   provided where required.
4. Validate with passive inspection, source review, and self-owned tokens or
   ciphertexts.
5. Write findings with `../../references/finding-output.md`.

## Where To Look

- Password storage, reset tokens, remember-me cookies, JWTs, signed URLs,
  encrypted fields, API keys, webhook signatures, TLS config, mobile secrets, and
  file encryption.
- Key rotation, environment variables, KMS/HSM integration, backups, logs, and
  developer tooling.
- Custom crypto wrappers and compatibility paths.

## Common Patterns

- Encryption without authentication.
- Weak randomness or predictable token generation.
- Keys reused across environments, tenants, purposes, or algorithms.
- Passwords hashed without memory-hard algorithms or sufficient cost.
- Signature verification accepts weak algorithms, missing audience, or missing
  purpose binding.

## Protection And Bypass Themes

- Separate encoding, hashing, encryption, and signing; do not let names imply
  security properties.
- Check key origin, rotation, scope, storage, logging, and revocation.
- Test algorithm confusion, missing MAC checks, nonce reuse, replay, expiration,
  and downgrade paths with owned artifacts.
- Review legacy compatibility and fallback behavior.

## Safe Validation

- Do not recover or expose real secrets. Use synthetic data, owned tokens, and
  proof of forgery, replay, or decryption risk when allowed.
