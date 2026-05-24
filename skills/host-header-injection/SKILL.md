---
name: host-header-injection
description: >-
  Use when authorized testing involves the Host header, X-Forwarded-Host,
  X-Forwarded-Proto, X-Original-URL, Forwarded, or any reverse-proxy or
  framework primitive that influences absolute URL generation, virtual host
  routing, cache keying, or authorization checks.
---

# Host Header Injection

The Host header (and its `X-Forwarded-*` cousins) often influence absolute
URL generation used in password-reset links, invite emails, OAuth callbacks,
webhook signatures, and cache keys. When the application trusts the header
but the reverse proxy forwards arbitrary values, attackers can poison those
URLs.

## Workflow

1. Read `../../references/scope-safety.md` and the Security
   Misconfiguration, CORS, And Host Headers section of
   `../../references/high-signal-must-tests.md`.
2. Map every feature that builds an absolute URL: password reset,
   invitation, email verification, OAuth callback registration, webhook
   delivery, image/CDN proxy, shareable links, exports.
3. Probe each with overridden Host / X-Forwarded-Host / X-Forwarded-Proto
   / Forwarded / X-Original-URL / X-Original-Host headers.
4. Identify which header the framework or library actually trusts; many
   apps trust `X-Forwarded-Host` from any client because the proxy "is
   in front of them".
5. Validate with self-owned accounts, owned email inbox, and a unique
   marker in the rendered URL.
6. Write findings with `../../references/finding-output.md`.

## Where To Look

- Password reset flow: trigger reset for an owned account and check
  whether the link host reflects an injected header.
- Invitation flow: same as above for invites.
- Email verification, magic links, "view in browser" links, unsubscribe
  links.
- OAuth/OIDC redirect_uri default registration, dynamic-client-
  registration flows, webhook URL displays.
- API gateways and load balancers that route by Host; can a host
  override reach a different virtual host or admin app?
- Cache keys: does the cache key the response by Host? If yes, host
  manipulation can poison the cache (see `../cache-poisoning/SKILL.md`).

## Common Patterns

- Framework helpers like `request.get_host()`, `url_for(_external=True)`,
  `request.url`, or `URL.parse(req.url)` use the Host header without
  validation when behind a proxy.
- `X-Forwarded-Host` accepted in addition to Host because "we are behind
  a load balancer", but the load balancer does not strip client-supplied
  copies.
- `X-Forwarded-Proto` accepted to switch the scheme of generated links
  from `http` to `https` or vice versa.
- Routing by Host combined with virtual-host fallback: setting Host to
  an internal hostname routes to admin or staging.

## Protection And Bypass Themes

- Try sending two Host headers; some stacks use the first, some the
  last.
- Try `Host: attacker.example` directly; try Host with port that
  matches the proxy; try IPv6-bracketed Host.
- Try `X-Forwarded-Host`, `X-Forwarded-Server`, `X-Original-Host`,
  `X-Host`, `Forwarded: host=attacker.example`.
- Try comma-separated values in `X-Forwarded-Host` - frameworks vary
  in which entry they use.
- For absolute-URL generation, check whether the path is also taken from
  a forwarded header (`X-Original-URL`, `X-Rewrite-URL`); this can
  bypass route auth.

## Safe Validation

- Use an owned account, an owned email inbox, and an owned attacker
  domain. The proof is the rendered link in the email pointing to the
  attacker domain.
- Do not trigger reset/invite for real users.

## Anti-Patterns

- Reporting "Host header reflected in the response body" as a finding
  with no impact. The bug needs to influence a security-relevant URL or
  authorization decision.
- Reporting cache poisoning via Host without verifying the cache key
  actually includes the attacker-controlled value - see
  `../cache-poisoning/SKILL.md`.
- Confusing virtual-host routing exposure with Host header injection;
  if the proxy routes by Host, an unauthorized Host may simply 404 with
  no security impact.
