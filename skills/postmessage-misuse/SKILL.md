---
name: postmessage-misuse
description: >-
  Use when authorized testing involves `window.postMessage` between frames,
  popups, opener/openee windows, embedded widgets, OAuth pop-up callbacks,
  payment widgets, chat embeds, SSO bridges, third-party SDK iframes, or
  any cross-origin DOM messaging channel.
---

# postMessage Misuse

`window.postMessage` is the standard browser channel for cross-origin DOM
messaging. The bugs are almost always at the receiver: missing origin
check, loose origin check, or trusting message content as authoritative.
Sender-side bugs leak sensitive data to wildcard targets.

## Workflow

1. Read `../../references/scope-safety.md` and the XSS section of
   `../../references/high-signal-must-tests.md`.
2. Map every `postMessage` sender and receiver in the application:
   grep the JS bundle for `postMessage(`, `addEventListener('message'`,
   and `onmessage`.
3. For each receiver, classify:
   - **Origin check present and strict**: low risk.
   - **Origin check absent or loose** (`indexOf`, `endsWith`,
     `startsWith`, regex with `.` unescaped, allowlist with wildcards):
     candidate.
   - **Content trusted as authoritative** (DOM update, token storage,
     navigation, command dispatch): exploitable.
4. For each sender, check whether `targetOrigin` is `*` and what the
   payload contains.
5. Validate from an owned attacker page in another origin. Send a
   message to a victim window (popup, iframe, opener) and observe
   whether the receiver acts on it.
6. Write findings with `../../references/finding-output.md`. State the
   exact handler, the missing/loose check, and the security action
   triggered.

## Where To Look

- OAuth callback popups: parent listens for an auth-code message from
  the popup; loose origin checks let an attacker page post a forged
  code.
- Payment widgets (Stripe Elements, Braintree Drop-in, PayPal Buttons)
  and any third-party iframe SDK.
- Customer chat embeds (Intercom, Drift, Crisp) that postMessage user
  data into the chat widget.
- SSO and federation bridges where a host page communicates with an
  identity iframe.
- "Share to social", embedded video, ad SDKs, A/B test SDKs.
- Internal admin tooling with iframe-embedded subsystems.

## Common Patterns

- Receiver does not check `event.origin` at all; trusts any sender.
- Receiver checks `event.origin.indexOf("trusted.com") !== -1`,
  matching `https://trusted.com.attacker.example`.
- Receiver checks `event.origin.endsWith("trusted.com")` matching
  `https://attacker-trusted.com`.
- Receiver uses a regex with unescaped `.` matching
  `trustedXcom.attacker.example`.
- Receiver accepts message and dispatches a command without
  validating the action against the sender's privilege.
- Sender posts secrets, tokens, or PII with `targetOrigin: '*'`.
- Receiver re-emits the message to a third frame without rechecking
  origin (forwarding loop).

## Protection And Bypass Themes

- Try the receiver from an owned-origin frame and verify the action
  happens. Common attacks:
  - **OAuth code theft**: post a fake `{code: 'x'}` message to the
    parent window before the legitimate popup loads.
  - **Token disclosure**: open the target as a popup, listen for the
    auth message it posts to its (now-attacker-controlled) opener.
  - **Sensitive UI update**: trigger a settings change, navigation,
    or balance update via crafted message.
- For sender-side leaks, check whether the page posts secrets with
  `*` target while the legitimate receiver origin is known and could
  be passed explicitly.
- For nested-frame scenarios, check whether a child iframe forwards
  messages without re-validating origin.
- For SSO/OAuth flows, examine the timing of the popup auth: many
  flows do not pin the popup window reference, so a same-name
  attacker window can intercept the auth.

## Safe Validation

- Owned attacker domain hosting the proof page. Open the target in a
  popup or iframe from your page.
- Use unique markers; send one message, prove one action, stop.
- For OAuth-code theft, use a self-issued client and owned account;
  do not capture real users' codes.

## Anti-Patterns

- Reporting "no origin check" without showing a privileged action the
  attacker can drive via the message.
- Reporting `targetOrigin: '*'` send when the payload is not
  sensitive (e.g. analytics events).
- Forwarding a victim through a real-services OAuth flow as part of
  the PoC.
- Confusing postMessage receiver bugs with CORS; CORS is HTTP, this
  is DOM.
