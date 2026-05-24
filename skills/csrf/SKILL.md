---
name: csrf
description: >-
  Use when authorized testing involves authenticated state-changing actions
  reachable from a cross-site or cross-origin context - profile/email/password/
  MFA/payout/role/integration changes, invites, deletes, exports, login CSRF,
  account-link CSRF, JSON endpoints, GET-as-mutation, or method-override
  endpoints.
---

# CSRF

Cross-Site Request Forgery is testing whether an attacker page in another
origin can cause an authenticated victim browser to perform a sensitive
action. Modern apps rely on SameSite cookies, CSRF tokens, and origin checks;
the bug is almost always in how those defenses are *bound* and how often they
are *enforced*.

## Workflow

1. Read `../../references/scope-safety.md` and the Cross-Site Request
   Forgery section of `../../references/high-signal-must-tests.md`.
2. Enumerate every authenticated state-changing action and classify by
   method, content type, and required headers.
3. For each, identify the defense set: SameSite cookie attributes, CSRF
   token presence, token binding (session-only vs action/user/tenant/method/
   freshness), `Origin`/`Referer` checks, custom-header requirement.
4. Build the simplest cross-origin form/fetch that would trigger the action;
   determine which defense (if any) actually blocks it.
5. Validate with two owned accounts and a harmless mutation.
6. Write findings with `../../references/finding-output.md`. State both the
   action and the *specific* defense gap.

## Where To Look

- Profile, password, email, phone, MFA settings; payout/withdrawal/billing
  configuration; payment method changes.
- Role assignments, invites, member removals, tenant transfer, OAuth app
  authorization, API key creation.
- Integration configuration: webhook URLs, SAML metadata, SCIM endpoints,
  third-party links.
- Login itself (login CSRF): can an attacker bind the victim's browser to
  an attacker-controlled identity?
- Account linking endpoints (link-CSRF): can the attacker join their
  identity to the victim's account?
- GET endpoints that perform side effects (rare but high-impact when
  present).
- Method-override endpoints (`_method=DELETE`, `X-HTTP-Method-Override`).

## Common Patterns

- CSRF token bound only to session; valid across actions, users, methods,
  or freshness windows.
- JSON endpoint that also accepts `application/x-www-form-urlencoded`,
  `multipart/form-data`, or `text/plain`, bypassing custom-header preflight.
- `SameSite=Lax` cookies assumed safe, but the action is reachable via a
  top-level navigation or a same-site subdomain.
- `Origin`/`Referer` validation by substring, suffix, or null-tolerance.
- Custom-header requirement satisfied by browsers in alternate content
  types or after a preflight that the server silently accepts.

## Protection And Bypass Themes

- CORS is **not** a CSRF defense; it controls browser *read* access to
  responses, not whether a write request is sent.
- `SameSite=Lax` does not protect: same-site subdomains, top-level
  navigations to GET-as-mutation endpoints, or cross-site iframes if
  `SameSite=None` is set elsewhere.
- Custom headers usually force a CORS preflight, but alternate content
  types (`text/plain`, `multipart/form-data` without `Content-Type` JSON)
  bypass preflight on some servers.
- Token binding granularity matters: per-session is the weakest, per-action/
  user/method/timestamp is stronger.
- For login CSRF, look for missing CSRF on `/login` itself; for link CSRF,
  look at OAuth callback and account-link endpoints.

## Safe Validation

- Two owned accounts: victim browser logged in as one, attacker page in a
  different origin. Make a harmless change (e.g. flip a personal
  preference) and capture the request from victim's session.
- Do not target real users. Do not perform irreversible or financially
  meaningful changes even on owned accounts.
- Provide a minimal HTML PoC; do not weaponize.

## Anti-Patterns

- Reporting CSRF on a login form without explaining the impact (login CSRF
  is a finding when it leads to attacker-controlled session binding).
- Reporting CSRF on a JSON endpoint whose only client is a same-origin
  fetch with custom headers, without first proving alternate content-type
  acceptance.
- Reporting CSRF where the action is read-only or non-security-relevant.
