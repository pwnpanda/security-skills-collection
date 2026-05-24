---
name: jwt-jose
description: >-
  Use when authorized testing involves JWT or JOSE tokens - signed cookies,
  bearer tokens, ID tokens, session tokens, signed URLs, signed webhook
  payloads, signed cache entries, or any artifact verified through JWS/JWE
  with a key-id, jwks-uri, or algorithm choice.
---

# JWT And JOSE

JWT and JOSE bugs concentrate around algorithm selection, key selection, and
claim binding. The token format is fine; the *verifier configuration* is
where the bug usually lives.

## Workflow

1. Read `../../references/scope-safety.md` and the Authentication, OAuth,
   and JWT section of `../../references/high-signal-must-tests.md`.
2. For each JWT issuer/verifier pair, capture: declared algorithms,
   `kid` policy, `jku`/`jwk`/`x5u` policy, key rotation behavior,
   accepted issuers, accepted audiences, accepted purposes.
3. Identify the verifier library and version. Many historical bypasses
   are version-specific.
4. Test algorithm confusion, key-selection abuse, claim coverage, and
   replay/freshness.
5. Validate with owned tokens issued by an owned IdP or a self-signed
   tampered token; do not forge tokens for real users.
6. Write findings with `../../references/finding-output.md`. State the
   verifier behavior that accepted the bypass.

## Where To Look

- API auth bearer tokens, ID tokens from OAuth/OIDC
  (`../oauth-oidc/SKILL.md`), session cookies in JWT/JWE form.
- Signed query parameters, signed webhook headers (Stripe-style),
  signed cache restore tokens, signed CSRF tokens.
- SDK tokens (mobile, CLI, terraform), service-to-service tokens.
- OIDC discovery documents, JWKS endpoints, key rotation policies.

## Common Patterns

- `alg: none` accepted by a permissive verifier.
- HS256-vs-RS256 algorithm confusion: token signed with the RS256
  public key as HMAC secret, verifier infers algorithm from header.
- `kid` header that selects the key by path; attacker injects path
  traversal or controls the key file (file/URL injection via `kid`).
- `jku` or `x5u` header that fetches keys from an attacker URL when
  the verifier does not pin a domain.
- `jwk` embedded in the header and trusted by the verifier without
  checking that the public key is one the issuer actually published.
- Missing `aud` or `iss` checks; token issued for one tenant accepted
  by another.
- Missing purpose binding: refresh token accepted as access token, or
  vice versa.
- Missing replay protection: token without `jti` and `nonce` accepted
  multiple times within validity.

## Protection And Bypass Themes

- Try lowercase/casing variants of `alg` and `kid` to bypass
  case-sensitive checks.
- For HS/RS confusion, fetch the issuer's public key, re-sign the token
  with HS256 using the public key as secret, and check whether the
  verifier accepts.
- For `kid` path traversal, point `kid` at a predictable file (e.g.
  `/dev/null` results in empty key) and check if zero-length keys yield
  trivial signatures.
- For `jku`/`x5u`, host an attacker JWKS with a key whose `kid` matches
  the legitimate one and see if it is fetched and trusted.
- For nested JWS, test whether the outer signature covers the inner
  payload and headers.
- For JWE, test whether `enc`/`alg` downgrade is possible and whether
  the recipient validates the recipient header.

## Safe Validation

- Use tokens for owned accounts/tenants. Tamper with a flag that
  changes one of *your* permissions, not someone else's.
- Do not exfiltrate or replay real users' tokens.
- For JWKS-fetch tests, host the malicious JWKS on a domain you own and
  use a unique marker so callbacks are attributable.

## Anti-Patterns

- Reporting `alg: none` accepted without showing that a sensitive
  endpoint was reached with the forged token.
- Reporting that the header is decodable as if it were impact. JWT
  headers are not secret.
- Forging tokens for real users to show "we can authenticate as anyone"
  - one self-issued tampered token is enough.
