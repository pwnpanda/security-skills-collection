---
name: email-testing
description: >-
  Use when authorized testing involves email-address handling - signup,
  invitation, password reset, email change, change-of-email confirmation,
  contact/abuse forms, calendar invites, share-by-email, "send me a copy",
  notification preferences, or any flow where the application parses an
  email address, routes mail, builds SMTP headers from user input, or
  trusts the email domain for authorization or tenant assignment.
---

# Email Testing

Email is two attack surfaces in one: the **parser** (does the application
agree with the SMTP server on where mail will actually go?) and the **mail
builder** (does user input land in an SMTP header or template without
sanitisation?). PortSwigger's 2024 "Splitting the email atom" research
demonstrated that even RFC-compliant addresses can route to a domain other
than the one the application validated, breaking domain-based access
control and tenant assignment on GitHub, GitLab, Zendesk, Joomla, and
others. SMTP header injection turns reset/contact endpoints into
attacker-controlled mail relays.

## Workflow

1. Read `../../references/scope-safety.md`. Email tests touch real mail
   systems; use owned mailboxes and owned attacker domains throughout.
2. Enumerate every feature that accepts an email address: signup,
   invitation, change email, change-of-email confirmation, password
   reset, contact form, abuse report, share-by-email, calendar invite,
   notification, "send me a copy", BCC/CC fields, SSO JIT provisioning.
3. For each, classify three things:
   - **Parser**: which library parses the address (Ruby Mail, Python
     `email`, PHP `IdnaConvert`, Node `validator`, custom regex).
   - **Domain-based logic**: does the app use the domain part for
     tenant lookup, allowlist enforcement, SSO routing, or
     auto-verification?
   - **Mail builder**: does user input (name, subject, body, address)
     get concatenated into SMTP headers or template bodies?
4. Plan a payload matrix: splitting-the-atom payloads against parsers,
   CRLF/Unicode-line-separator payloads against builders, subaddressing
   payloads against templates.
5. Validate against owned mailboxes and owned attacker domains. The
   proof is a delivered email whose To/From/Bcc/body/subject was
   manipulated.
6. Write findings with `../../references/finding-output.md`. State which
   parser disagreed with which downstream system, and what authorization
   or routing decision was broken.

## Where To Look

- Signup, change-email, password reset, invitation, account merge, SSO
  account linking, second-factor recovery.
- Forms that send mail on behalf of the user: contact, support, abuse
  report, refer-a-friend, share, "send me a copy", calendar invite,
  bulk export delivery.
- Tenant assignment by email domain: "anyone with @acme.com joins the
  ACME workspace", marketplace seller verification, partner portals.
- Allowlist/denylist enforcement: employee-only signup, gated betas,
  domain-restricted SSO, "approved customer" portals.
- Template-rendered fields: welcome emails using `Hello {{user.email}}`,
  reset emails containing the requested email back, "you signed up as
  X" confirmations.

## Common Patterns

- App validates with one parser, SMTP server routes with a different
  parser; the address `validates as @company.com` but mail goes
  elsewhere.
- Domain-based access control uses the substring after the last `@`
  while the SMTP server uses the substring after the first `@`.
- IDNA/punycode decoded by the validator but not by the renderer (or
  vice versa); the visible domain differs from the actual one.
- User-supplied display name concatenated into a SMTP `Subject:` or
  `From:` header with no CRLF stripping.
- Template engine renders the full email address (including
  subaddressing tag) into a Subject or HTML body without escaping.
- Reset link sent to whatever address was supplied, not to the
  originally registered one.

## Protection And Bypass Themes

### Splitting the email atom

These payloads exploit parser disagreement between the application and
the downstream SMTP server. Goal: make the application *believe* the
domain is `target.com` while mail routes to your own callback domain.

- **Encoded-word (RFC 2047)** - `=?charset?encoding?data?=` inside an
  address. Q-encoding hex, base64 data, and UTF-7 charset chaining all
  collapse to attacker-controlled bytes after decoding. Detection probe:
  `=?x?q?abccollab=40psres=2enet?=@target.com` - if the SMTP RCPT TO
  receives `abccollab@psres.net`, encoded-word is honoured.
- **Quoted local-parts (RFC 5322 3.2.5)** - the local-part may contain
  an embedded `@`, `<`, `>`, or quote when quoted: `"a@b"@target.com`,
  `"<script>"@target.com`. Different parsers disagree on where the
  local-part ends.
- **Comments (RFC 5322 3.2.3)** - parentheses can appear inside an
  address and may nest: `user(comment)@target.com`,
  `(foo)user@(bar)target.com`. Some parsers strip comments, some
  preserve them, some route on the value before/after them.
- **Multiple @ via Unicode overflow** - codepoints > 0xFF passed through
  a `chr(x) % 256` operation collapse to ASCII. `ŀ` (U+0140) becomes
  `@`, `❀` becomes `@`, etc. Useful when the validator strips literal
  `@` but a downstream renderer uses `chr()`.
- **IDNA / punycode generators** - malformed `xn--` labels in some
  libraries (notably IdnaConvert) decode to characters the validator
  thinks were impossible: `xn--0117.example.com` becomes `@@`,
  `xn--0049.com` becomes `,`, `xn--694` becomes `;`,
  `xn--svg/-9x6.example.com` smuggles a partial `<svg/` tag.
- **SMTP routing legacy** - source routing (`@a,@b:user@target.com`),
  UUCP bang paths (`oastify.com!user@target.com` on Sendmail 8.15.2),
  percent-hack (`collab%psres.net@target.com` on Postfix 3.6.4 converts
  the percent to `@` and routes to `collab@psres.net`).
- **ORCPT smuggling** - when the app passes `ORCPT=` to SMTP from user
  input, an extra address can hijack the delivery.

### SMTP header injection

User input concatenated into an SMTP header allows arbitrary header
addition or body smuggling.

- Try raw CRLF: `\r\n`, then URL-encoded `%0d%0a`, double-encoded
  `%250d%250a`, mixed `%0d%0A` and `\nBcc:`.
- Try Unicode line separators that some parsers normalise to newline:
  U+2028 (line separator), U+2029 (paragraph separator), U+0085 (NEL).
- Try vertical tab `\v` and form feed `\f` - some Go/Python regex
  character classes accept these but exclude only CR/LF.
- Try injecting `Bcc:` to add an attacker recipient, `Subject:` to
  replace the subject, `Content-Type: multipart/mixed; boundary=...`
  followed by a full alternative body to smuggle attachments.
- Fields most commonly vulnerable: display name, subject, reply-to
  address, recipient lists, body templates, abuse-report comment.

### Subaddressing tampering (RFC 5233)

Most providers route `victim+anything@target.com` to `victim@target.com`,
but the application sees and often renders the full address.

- For template rendering, register or reset with
  `victim+{{7*7}}@target.com`. If the welcome/reset email displays
  `49` instead of `{{7*7}}`, the template engine evaluated user input
  via the address - server-side template injection.
- For domain-allowlist abuse, register as
  `attacker+anything@allowed.com` if the application accepts the
  domain but mail will still bounce or land in your inbox if you also
  control DNS for `allowed.com` (e.g. an expired sandbox).
- For tenant-confusion attacks, signing up as
  `victim+attacker@target.com` may auto-join the same tenant as
  `victim@target.com` while delivering the verification mail to a
  catch-all you control.
- For account linking, observe whether the app deduplicates
  subaddressed forms before binding identities; some apps treat
  `a@x.com` and `a+1@x.com` as the same identity, others do not.

### Multiple addresses

- Try `,` and `;` in single-address fields: `victim@target.com,
  attacker@evil.com`. Some libraries silently parse this as two
  recipients.
- Try multi-line addresses with CRLF between them.
- For comma-injection through IDNA, see the punycode generator above
  (`xn--0049.com` decodes to a literal `,`).

### Unicode normalisation and homoglyph

- Try `user@exămple.com` where `ă` (U+0103) is a homoglyph for `a`.
  If the server normalises with NFKC *after* the uniqueness check, a
  password reset bound to the homoglyph email can rebind the original
  account.
- Mixed-script addresses (Latin + Cyrillic) often pass per-character
  validation but collide with existing usernames after normalisation.
- Domains: `evil.com` vs `xn--evil-xxx.com` punycode forms; case
  variants; trailing-dot variants (`target.com.`).

### Domain-based authorization

- Never trust the substring after the last `@`. After all the parser
  tricks above, the SMTP server may route somewhere entirely different.
- Test SSO providers that issue emails for unverified identities; an
  attacker with an unverified `victim@target.com` claim at one IdP can
  often link to an existing target account.

## Safe Validation

- Use mailboxes you fully control on a domain you own. Maintain
  catch-all so subaddressed and misrouted mail still arrives.
- Use unique OAST-style markers per test request (see
  `../oast-testing/SKILL.md`); append marker to the per-program log
  before sending.
- For domain-allowlist bypasses, prove with two owned identities -
  attacker (your mailbox) and "victim" (a second owned mailbox on the
  target's domain via legitimate signup).
- For SMTP header injection, prove with a single `Bcc:` to your owned
  mailbox; do not relay arbitrary mail.
- For SSTI via subaddressing, stop at `{{7*7}}` evaluating to `49`. Do
  not chain to file read or shell.
- Do not send mail to real users on the target system or to the
  target's customer mailboxes.

## Anti-Patterns

- Submitting splitting-the-atom payloads against real users' addresses;
  any successful misroute leaks something to the attacker.
- Spamming abuse forms or contact forms with CRLF payloads at high
  volume; this is in scope for almost no program.
- Using the legitimate target SMTP infrastructure to send phishing as
  proof; one `Bcc:` to an owned mailbox is sufficient.
- Reporting `=?x?q?...?=` accepted in a field without proving the
  decoded form routed somewhere else than the validator believed.
- Confusing display-only sanitisation with routing. A green checkmark
  next to a forged address is cosmetic; the proof is the SMTP RCPT TO
  log or the inbox the message actually landed in.
- Treating an HTML-escaped `{{7*7}}` in a welcome email as proof of
  SSTI; the test is whether `49` (or another evaluation result)
  arrives.
