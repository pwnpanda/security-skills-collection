---
name: websocket-security
description: >-
  Use when authorized testing involves WebSocket endpoints - real-time
  notifications, chat, collaborative editing, presence, live dashboards,
  trading streams, GraphQL subscriptions, MQTT-over-WS, STOMP-over-WS, or
  any feature using `ws://` / `wss://` for bidirectional communication.
---

# WebSocket Security

WebSocket bugs concentrate at three points: the upgrade handshake (where
origin and auth get checked or not), per-message authorisation (often
missing because "the connection was authenticated"), and message
confusion (different message types share one channel with different trust
levels).

## Workflow

1. Read `../../references/scope-safety.md` and the relevant injection /
   access-control sections of `../../references/high-signal-must-tests.md`.
2. Identify every WebSocket endpoint: `wss://` URLs in the bundle,
   `/socket.io/`, `/graphql/ws`, `/cable` (Rails ActionCable), STOMP
   over WS, MQTT over WS.
3. Capture a full session: upgrade headers, server response,
   authenticated and unauthenticated message sequences.
4. Test each of three failure modes:
   - **Upgrade**: does the server check `Origin`, authenticate the
     handshake, scope cookies/tokens to the WS path?
   - **Per-message auth**: can an authenticated channel subscribe to
     another user's room/tenant, receive other users' broadcasts, or
     publish on their behalf?
   - **Message confusion**: do message types share a parser; does
     server-side state trust client-supplied type fields?
5. For Cross-Site WebSocket Hijacking (CSWSH), validate with an owned
   page in a different origin connecting via cookies.
6. Write findings with `../../references/finding-output.md`. State the
   upgrade behaviour, the per-message check that was missing, and the
   boundary that was crossed.

## Where To Look

- Chat, in-app messaging, support widget, customer-chat embed.
- Collaborative editing, live cursors, presence indicators.
- Notification streams, status pages, live dashboards.
- Trading and pricing streams.
- GraphQL subscriptions (`graphql-ws`, `subscriptions-transport-ws`).
- Game/realtime engines: Socket.IO, Pusher, Ably, Centrifugo.
- IoT and broker patterns: MQTT-over-WS, STOMP-over-WS.

## Common Patterns

- Upgrade accepts any `Origin`; browser sends cookies, so an attacker
  page connects in a victim's session (CSWSH).
- Upgrade authenticates via a bearer token in the URL or query string;
  the token leaks via referrer, browser history, server logs, or
  proxy logs.
- Per-message handlers do `if (user.id == event.target_id)` checks
  client-side but trust `target_id` server-side.
- Subscribe to a room/channel by string name; no server-side check
  that the user belongs to that room.
- Publish a message with a client-supplied `from` field; server
  rebroadcasts as-is.
- Message type discriminator (`type: "system_announcement"`) accepted
  from any client.
- Reconnection logic that re-auths only on first connect, then assumes
  identity for the lifetime of the connection.

## Protection And Bypass Themes

- For CSWSH, build an owned-origin page that opens the WebSocket via
  the browser, relying on cookie-based auth. Bypass succeeds when no
  Origin check or a permissive check (`endsWith(target.com)`) is in
  place.
- For per-message authorisation, enumerate room/channel names by
  pattern (numeric IDs, sequential tenant slugs); subscribe to each
  with one owned account and watch for unexpected events.
- For message confusion, swap the `type` discriminator on a low-
  privilege message to a higher-privilege type and replay; check
  whether the server differentiates.
- For Socket.IO specifically, the upgrade may fall back to long-poll
  HTTP which is sometimes auth-checked differently than the WS path.
- For GraphQL subscriptions, check whether subscription resolvers
  apply the same authorisation as query/mutation resolvers - they
  often do not.
- For token-in-URL upgrades, check whether the token also works as a
  regular API token; if so, leakage paths multiply.

## Safe Validation

- Use two owned accounts and (for CSWSH) one owned attacker domain
  page. Prove cross-origin connect or cross-room subscribe with the
  victim browser.
- Use small messages with unique markers; never publish to channels
  with real users.
- For impersonation, prove with a single message to your own second
  account; do not impersonate to real users.
- Stop after one reproducible failure per channel/type.

## Anti-Patterns

- Reporting "WebSocket exposed" with no auth or authorisation impact;
  WS being open is not a bug.
- Flooding channels with messages as "DoS proof".
- Reporting cross-origin connect as CSWSH without showing the server
  performs an authenticated action based on the cross-origin client's
  messages.
- Reading other users' messages and quoting them in the report; one
  attributable event with metadata is sufficient.
