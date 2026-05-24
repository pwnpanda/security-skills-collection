---
name: blind-xss
description: >-
  Use when authorized testing involves stored user input that is rendered
  later in a privileged or out-of-band context the tester cannot see directly -
  admin dashboards, support tools, moderation queues, audit views, email
  templates, PDF/HTML exports, billing pages, mobile WebView, or embedded
  widgets.
---

# Blind XSS

Blind XSS is stored XSS where the sink lives in a context the tester never
loads. Proof depends on a callback from the rendering browser, so marker
discipline and payload-placement matter more than payload novelty.

## Workflow

1. Read `../../references/scope-safety.md`, the XSS section of
   `../../references/high-signal-must-tests.md`, and `../oast-testing/SKILL.md`.
2. Map every input field that is stored and later read by humans, automated
   reporting, or another service: profile, organization, billing, support
   ticket, feedback, file metadata, integration name, webhook description.
3. Plan a payload-family x field matrix. Each cell is one payload variant
   (HTML, attribute, JS string, SVG, markdown, JSON, header-injectable) paired
   with one field eligibility note.
4. Send one unique Category B marker per (field, payload-family) cell. Append
   each marker to the per-program OAST log before the request is sent.
5. Wait. Some renders fire in seconds (live dashboards); others fire in hours
   or days (weekly exports, billing runs, escalations).
6. When a callback arrives, attribute it via the marker log and capture
   referrer, user-agent, source IP, DOM, cookies *names only*, and rendering
   URL. Stop after one confirmed hit per finding.
7. Write the finding with `../../references/finding-output.md`. Include the
   field, payload family, callback log entry, and the privilege boundary that
   was crossed.

## Where To Look

- Profile fields: display name, username, bio, signature, company, address,
  phone, custom fields, avatar metadata, social links.
- Tenant/org fields: company name, billing address, support email, invoice
  notes, custom domain, SAML metadata, branding strings.
- Workflow fields: ticket subject and body, comment, file name, file
  description, integration name, webhook URL label, alert rule name.
- Audit-visible fields: API key label, OAuth app name, deploy message, error
  message captured from upstream services.
- Indirect sinks: emails, push notifications, PDF/HTML exports, CSV downloads
  opened in spreadsheet apps, mobile clients, admin dashboards, status pages.

## Common Patterns

- Output is sanitized in the public UI but not in the admin/support view.
- Markdown or rich-text rendering occurs after sanitization, reintroducing
  HTML through link, image, mention, or emoji handling.
- Email and PDF rendering use a different template engine and a different CSP
  than the web UI.
- Logging pipelines render structured fields with a template engine
  (Kibana-style, Grafana annotations, alert notification bodies).
- Mobile WebViews disable CSP, expose JS bridges, or rehydrate stored HTML in
  a higher-privilege context.

## Protection And Bypass Themes

- Match payload to the *most likely* sink context, not generic XSS lists. For
  admin dashboards, prefer compact event-handler attribute payloads; for email
  and PDF, prefer img/style/svg payloads; for markdown, prefer link and image
  syntax that smuggles javascript: URLs through linkifiers.
- Account for length and character-class filters: many fields cap at 32, 64,
  or 128 characters. Mark these cells as "skipped - field cap < family
  minimum" rather than leaving them empty.
- Sanitizers that strip script tags often miss SVG, MathML, foreignObject,
  meta refresh, or onerror in obscure tags.
- CSP can block inline script but allow image and link payloads that still
  exfiltrate via referrer or via a same-origin endpoint redirect.

## Safe Validation

- Payload must do nothing more than fetch a unique-marker URL on your owned
  infrastructure. No keylogging, no DOM dumping beyond a single
  `location.href`, no cookie or token capture, no actions performed in the
  victim browser.
- One marker per field per payload family. Never reuse markers across
  resubmissions.
- After the first attributable callback, remove or overwrite the stored
  payload if program rules allow, then stop sending new payloads for that
  finding.

## Anti-Patterns

- Pasting generic public blind-XSS payloads from unrelated programs. Their
  markers are not in your log; any callbacks are someone else's evidence.
- Embedding cookie- or localStorage-exfiltration logic. Crosses the bug-bounty
  proof-of-impact line and likely violates scope.
- Spraying every field with the same payload. You will not be able to tell
  which field fired, and you will trip blind-XSS detection rules with no
  attribution benefit.
- Forgetting to register the marker before sending. A late-firing callback
  with no log entry is unattributable and not reportable.
