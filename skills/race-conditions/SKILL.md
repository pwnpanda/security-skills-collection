---
name: race-conditions
description: >-
  Use when authorized testing involves operations whose correctness depends
  on order or atomicity - one-time tokens, coupon/voucher redemption,
  inventory or balance updates, state transitions, MFA enrollment, password
  reset, account deletion, payouts, withdrawals, role changes, or any
  endpoint where concurrent requests may break an invariant.
---

# Race Conditions

Race conditions in web applications usually take one of three shapes:
classic TOCTOU (check then use), limit bypass through concurrent submission,
or state-transition collision. Modern HTTP/2 multiplexing makes these
practical with a single connection sending dozens of last-byte-synchronized
requests.

## Workflow

1. Read `../../references/scope-safety.md` and the Exceptional Conditions
   And Race Conditions section of `../../references/high-signal-must-tests.md`.
2. Identify candidate endpoints by invariant: should run once, must not
   exceed a limit, must be atomic, must serialize state changes.
3. Build a minimal concurrent harness (HTTP/2 single-packet, or close
   parallel requests) - prefer Turbo Intruder, ffuf with parallel
   workers, or a small custom script.
4. Send N concurrent identical or near-identical requests; observe
   whether the invariant breaks.
5. Validate with owned accounts and reversible state. Stop after the
   first reproducible break.
6. Write findings with `../../references/finding-output.md`. Include the
   concurrency level, the observed invariant break, and a note on
   reproducibility variance.

## Where To Look

- One-time-use tokens: password reset, email verification, MFA setup,
  magic link, invite acceptance.
- Coupons, vouchers, gift cards, loyalty redemption, referral bonuses.
- Inventory: stock decrement, seat reservation, ticket purchase, slot
  booking.
- Balance/credit changes: refunds, withdrawals, transfers, in-app
  currency purchases.
- State transitions: order placement, subscription upgrade/downgrade,
  membership renewal, KYC approval.
- MFA enrollment/disable, password change, email change, account
  deletion (often combine with "is this user still authenticated?"
  checks).
- Role assignment, member invitation, tenant transfer.
- API rate limiting itself, when the limit is enforced after the action.

## Common Patterns

- Token validity checked, then operation performed without atomic
  consume; two concurrent requests both pass the check.
- Balance read, decremented in memory, written back - classic lost
  update without row lock or compare-and-swap.
- "First request wins, rest fail" assumed but not enforced because the
  failure path emits a side effect (refund triggered twice).
- Idempotency keys checked at request handler but not at the database
  level, so concurrent requests with the same key both proceed.
- State-machine transition not guarded by a versioned `WHERE state=
  expected` clause.

## Protection And Bypass Themes

- Single-packet HTTP/2 attack: send N requests in one TCP packet to
  minimize jitter and maximize concurrency at the application layer.
- Coordinated start: pad requests so the last bytes flush
  simultaneously.
- For workflow races, hold open one connection at a slow step, fire
  another concurrent request that depends on the not-yet-completed
  state change.
- Test idempotency-key handling under high concurrency.
- Check whether DB transactions use the right isolation level for the
  invariant (READ COMMITTED is rarely enough for balance updates).

## Safe Validation

- Owned accounts and reversible operations. Use small balances, small
  inventory, owned coupons.
- Stop after the first reproducible double-spend or invariant break.
  Do not loop or amplify.
- Avoid races against payment processors or external systems where
  state cannot be reverted.

## Anti-Patterns

- Running races against production at high concurrency for extended
  periods.
- Reporting a one-off success without reproducing it; race timing is
  noisy.
- Demonstrating a race by claiming hundreds of credits on owned
  accounts - one double-claim is sufficient evidence.
