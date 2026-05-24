---
name: webhook-signature-bypass
description: >-
  Use when authorized testing involves webhook receivers that verify HMAC
  or signature headers - Stripe-style, GitHub-style, Slack-style, Shopify,
  Twilio, Mailgun, SendGrid, payment processors, CI providers, or any
  integration where a third party POSTs signed payloads that drive
  privileged state changes on the receiver.
---

# Webhook Signature Bypass

Webhook signature schemes look simple - HMAC over the body with a shared
secret - but the implementation surface is where the bugs live: raw-body
vs parsed-body, header parsing, timing-safe comparison, version pinning,
replay protection, and "test mode" bypasses.

## Workflow

1. Read `../../references/scope-safety.md` and the Integrity Failures
   and Deserialization sections of
   `../../references/high-signal-must-tests.md`.
2. Identify every webhook receiver and the third-party scheme it
   verifies. Capture the signature header name, format, and
   documentation.
3. For each receiver, examine:
   - Body source (raw request bytes vs parsed JSON re-serialised).
   - Signature comparison (timing-safe vs string equality).
   - Version handling (which signature versions accepted).
   - Replay protection (timestamp window, nonce store).
   - Secret rotation (multi-secret acceptance window).
   - Test/development mode (signature skipped or weakened).
4. Probe each with a forged payload: replay an old event, downgrade
   version, send unsigned, send signed with the wrong secret, send
   parsed-then-re-serialised body, send a payload with extra fields.
5. Validate with owned accounts and harmless state changes.
6. Write findings with `../../references/finding-output.md`. State the
   exact verifier behaviour, the bypass, and the privileged action it
   enables.

## Where To Look

- Payment providers: Stripe, Adyen, Braintree, PayPal, Razorpay,
  Square, Mollie.
- Source control and CI: GitHub, GitLab, Bitbucket, CircleCI, Travis,
  Buildkite.
- Comms: Slack, Discord, Twilio, Vonage, Telegram, MS Teams.
- Email: SendGrid, Mailgun, Postmark, AWS SES.
- E-commerce: Shopify, BigCommerce, WooCommerce.
- Identity: Auth0, Okta, Clerk, WorkOS webhooks.
- Custom partner integrations with `X-*-Signature` headers.

## Common Patterns

- Receiver computes HMAC over the parsed-and-re-serialised body
  instead of the raw bytes; the attacker varies whitespace, key
  ordering, or duplicate keys to change the hash without changing the
  parsed event.
- Signature comparison uses `==` or `string ===` instead of
  constant-time; timing attack possible across network.
- Version field accepted as `v0` (legacy, weaker) when current is
  `v1`; or any version accepted.
- No timestamp window check; signed events replay indefinitely.
- Timestamp accepted with no clock skew bound; old events still
  process.
- Multi-secret acceptance window left open long after rotation; old
  compromised secret still valid.
- Test-mode signature path or "skip verification in dev" flag
  reachable in production via header or domain.
- Receiver verifies the signature but parses the body before
  verification, allowing parser side-effects (JSON injection, XML
  XXE, prototype pollution) on unsigned input.

## Protection And Bypass Themes

- For raw-vs-parsed body: capture an example signed request, parse
  the JSON and re-serialise with whitespace differences, re-send
  with the original signature. If accepted, the receiver is comparing
  over re-serialised bytes - and you can now mutate fields the parser
  ignores.
- For timing-safe comparison: send N requests with a guessed
  signature byte and measure latency; this is rarely practical over
  the public internet but matters in same-cluster scenarios.
- For replay: store one legitimate signed event, send it again,
  observe whether the receiver creates duplicate state.
- For version downgrade: examine the verifier's accepted-version
  list; if `v0` is older/weaker, craft a `v0`-signed event.
- For multi-secret acceptance: probe whether an old secret (leaked,
  rotated, in past commits) still verifies.
- For pre-verification parsing: trigger a parser side-effect (XXE,
  prototype pollution) in an unsigned request and check whether the
  side-effect happens before verification rejects.
- For "test mode" bypass: see whether a header like
  `X-Stripe-Mode: test` or `X-Webhook-Test: 1` is honoured by
  production endpoints.

## Safe Validation

- For replay, use one of your own past signed events (e.g. a Stripe
  test webhook tied to your owned account) and replay it once.
- For raw-vs-parsed, prove with a single semantically-equivalent body
  variant that yields a different event outcome on the receiver.
- For test-mode bypass, observe but do not weaponise (e.g. do not
  trigger refunds, role grants, or state changes against shared
  resources).
- Owned accounts and integrations throughout. Do not interact with
  third-party providers' real signed webhooks meant for other users.

## Anti-Patterns

- Reporting "signature check uses string compare" without proving
  timing-attack feasibility in the target's network position.
- Replaying webhooks against production state-changing endpoints
  without verifying the action is reversible.
- Confusing signed-webhook bypass with general API auth bypass; the
  webhook receiver is the trust boundary.
