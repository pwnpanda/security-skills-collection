---
name: oauth-oidc
description: >-
  Use when authorized testing involves OAuth 2.0 / OIDC authorization flows,
  client registration, redirect_uri validation, scope handling, state/PKCE,
  ID/refresh token issuance, account linking, social login, federation,
  consent screens, or third-party app authorization.
---

# OAuth And OIDC

OAuth/OIDC bugs are usually one of: weak `redirect_uri` matching that leaks
codes, missing/weak `state` and PKCE that enables CSRF on the callback, ID
token validation gaps (issuer/audience/nonce), or scope/account-link
confusion that grants more than the user intended.

## Workflow

1. Read `../../references/scope-safety.md` and the Authentication, OAuth,
   And JWT section of `../../references/high-signal-must-tests.md`.
2. For each OAuth/OIDC integration, capture the full flow: client_id,
   registered redirect URIs, supported flows (auth code, implicit,
   device, client credentials, refresh), PKCE requirement, scopes,
   consent screen behavior.
3. Test `redirect_uri` matching: exact match, prefix match, registered-
   subdirectory match, port handling, scheme handling.
4. Test `state` and PKCE binding to the calling session.
5. For OIDC, validate ID token: `iss`, `aud`, `sub`, `exp`, `nbf`,
   `nonce`, signature key selection, `email_verified` trust.
6. Test account-link flows: can a federated identity bind to an
   existing account without verification?
7. Validate with self-registered clients, owned accounts, owned IdPs
   when possible.
8. Write findings with `../../references/finding-output.md`.

## Where To Look

- Authorization endpoint, token endpoint, userinfo, JWKS, OIDC discovery
  document, dynamic-client-registration endpoint.
- Account-link buttons (Connect Google/Apple/Microsoft/GitHub/...),
  enterprise SSO setup, SAML/OIDC tenant configuration.
- "Approved third-party apps" lists and consent management.
- Refresh token rotation policy; introspection and revocation endpoints.
- Mobile and CLI flows with custom URI schemes or loopback redirects.

## Common Patterns

- `redirect_uri` validation by prefix or substring, allowing
  `https://app.example.com.attacker.example`.
- `redirect_uri` validation by registered URL but with permissive query
  string, fragment, or port handling.
- `state` parameter optional or not bound to the calling session -
  enables callback CSRF / account hijacking.
- Missing or optional PKCE in public clients - exposes the code on
  redirect chains.
- ID token issuer not pinned to the IdP for this connection (federation
  confusion).
- `email_verified=false` accepted as proof of identity; account
  takeover by registering a federated identity for a victim's email.
- Implicit flow still enabled for legacy clients; token in URL fragment
  leaks through referrers and history.
- Authorization code is accepted multiple times or after expiry.

## Protection And Bypass Themes

- Combine open-redirect findings (`../open-redirect/SKILL.md`) with
  `redirect_uri` allowlist gaps to leak codes to attacker.
- Test PKCE downgrade: client supports PKCE but server allows requests
  without it.
- For social-login account linking, attempt to register an attacker IdP
  identity for a victim email and check whether the link binds without
  re-verification.
- For SAML, look at four specific classes:
  - **XSW (XML Signature Wrapping)**: the assertion is signed, but the
    parser reads a different unsigned assertion. Wrap the signed
    assertion in an `<Extensions>` or comment block, then inject an
    attacker-controlled assertion as the body. Eight published XSW
    variants per Mainka/Somorovsky.
  - **Comment truncation**: NameID like `victim@target.com<!--
    -->@evil.example` may be canonicalised one way for signature and
    another for application read - the app sees `victim@target.com`
    while the signed value is `victim@target.com<!---->@evil.example`.
  - **Audience/recipient/issuer validation**: signed assertion meant
    for one SP accepted by another; issuer not pinned per connection.
  - **SignedInfo coverage**: signature covers Assertion but not
    Response, or covers `Conditions` but not `Subject`.
- For device flow, check whether the user-code namespace is large
  enough and whether the polling endpoint rate-limits.

## Safe Validation

- Use a self-registered client when the program permits dynamic
  registration. Use two owned accounts for account-link tests.
- For redirect_uri leakage, use a domain you own and a unique marker;
  do not capture codes from real users.
- For ID token tests, use tokens you generated against your own IdP or
  a tenant you control.

## Anti-Patterns

- Reporting "redirect_uri allows http://localhost" as a finding for a
  desktop or mobile flow where loopback is required.
- Reporting open-registration on the dynamic-client-registration endpoint
  without showing token issuance impact.
- Reporting weak state handling on a flow that uses PKCE correctly -
  PKCE substitutes for state in many cases.
