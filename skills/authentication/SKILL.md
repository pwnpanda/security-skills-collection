---
name: authentication
description: >-
  Use when authorized testing involves login, sessions, MFA, passkeys/WebAuthn,
  SSO/OAuth/OIDC/SAML, account linking, identity proofing, password reset,
  account recovery, remember-me tokens, refresh tokens, API keys, device
  trust, step-up auth, or impersonation/support login.
---

# Authentication

OWASP mapping: consolidates A2:2017 Broken Authentication, A07:2021
Identification and Authentication Failures, and A07:2025 Authentication
Failures. For protocol-specific deep dives use `../oauth-oidc/SKILL.md` and
`../jwt-jose/SKILL.md`.

## Workflow

1. Read `../../references/scope-safety.md` and the Authentication, OAuth, and
   JWT section of `../../references/high-signal-must-tests.md`.
2. Build a state map: anonymous, pre-MFA, authenticated, remembered,
   step-up'd, password-reset, invited, linked, deactivated, locked, deleted.
3. Separate three concerns and test each independently:
   - **Identity proofing**: which identifier(s) establish "this is user X"?
   - **Authentication strength**: which factors and assurance level prove it?
   - **Session lifecycle**: how is the proven session issued, rotated,
     scoped, and revoked across web, API, mobile, and integrations?
4. Map every recovery and downgrade path (magic link, recovery code, support
   override, SSO fallback, basic-auth API token). These often weaken the
   declared assurance level.
5. Validate only with owned accounts and program-approved rate limits.
6. Write findings with `../../references/finding-output.md`.

## Where To Look

- Login, registration, invite acceptance, password reset, email/phone change,
  MFA enrollment and reset, passkey/WebAuthn enrollment, magic links,
  passwordless flows.
- SSO/OAuth/OIDC/SAML callbacks, account linking, JIT provisioning, domain-
  based joins, tenant selection, identity unlinking.
- Session cookies, remember-me tokens, refresh tokens, API keys, personal
  access tokens, service account credentials, mobile tokens, impersonation
  endpoints, support login.
- High-risk actions: payout/withdrawal changes, email/2FA changes, role
  changes, exports, OAuth app authorization, account deletion, billing.

## Common Patterns

- Session not rotated after login, MFA, password reset, role change, or
  email change.
- Password reset or magic link token not single-use, not bound to the
  requesting user, or not expired.
- MFA enforced in web UI but not on API, mobile, recovery, or legacy paths.
- Refresh tokens remain valid after password change, MFA reset, or account
  deactivation.
- Email treated as identity across issuers or tenants; recycled or
  attacker-controlled email links to an existing account.
- SSO callback validates signature but not issuer, audience, tenant, nonce,
  or intended account.
- Step-up auth required by UI but the underlying API accepts the original
  session.
- Device trust is transferable, predictable, or not bound to risk context.

## Protection And Bypass Themes

- Test every state transition for token reuse and session rotation.
- Compare authentication and assurance checks across web, API, mobile,
  GraphQL, admin, and background paths - parity gaps are the bug.
- Canonicalize identifiers: emails, domains, phone numbers, usernames,
  external subjects, tenant identifiers. Casing, plus-addressing, IDNA,
  trailing dots, and recycled addresses are common bypass surfaces.
- For OIDC/SAML check issuer, audience, recipient, nonce, state, subject,
  `email_verified`, and tenant context; for OAuth check exact `redirect_uri`,
  PKCE, and scope binding.
- For passkeys check origin binding, rpId, user verification flag, and
  fallback to weaker factors.
- Map every fallback: support login, legacy SSO, basic auth, API key,
  service account, recovery code. The weakest is the real assurance level.
- **Cookie tossing / multi-subdomain cookie attacks**: a less-trusted
  subdomain (`sandbox.example.com`, `dev.example.com`, a marketing
  microsite) can set a cookie scoped to `.example.com`. The parent app
  receives it and, if it prefers the attacker-set cookie or merges
  values, an attacker can override session, CSRF token, or feature
  flags. Test: from any in-scope subdomain you can write to, set a
  cookie with the same name as the parent's session cookie scoped to
  the parent domain; observe whether the parent's auth or CSRF logic
  reads the attacker value.

## Safe Validation

- Use owned accounts, owned domains, and non-production credentials.
- Do not brute-force, credential-stuff, or attack real users. Keep rate tests
  minimal and within program rules.
- For account-link or identity-confusion tests, use two owned identities and
  show the boundary that was crossed; do not target real third-party
  accounts.

## Anti-Patterns

- Treating UI step-up as proof of API step-up.
- Reporting "session valid after logout" without checking whether the same
  token still authorizes a sensitive action.
- Reporting recovery codes as a bug when they are working as designed; the
  bug is when recovery bypasses the declared assurance level.
