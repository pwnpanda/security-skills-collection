---
name: cross-site-scripting
description: >-
  Use when authorized testing involves reflected, stored, DOM, markdown,
  rich-text, template, widget, postMessage, PDF/HTML export, or client-side
  rendering XSS.
---

# Cross-Site Scripting

OWASP mapping: A7:2017 Cross-Site Scripting (XSS). Related to Injection in
2021 and 2025.

## Workflow

1. Read `../../references/scope-safety.md` and the relevant section of
   `../../references/high-signal-must-tests.md`.
2. Classify the sink context before trying payloads: HTML text, HTML attribute,
   URL, JavaScript string, JavaScript template literal, CSS, SVG, markdown, or
   framework-rendered component.
3. Identify the sanitizer, encoder, framework escape behavior, CSP, and trust
   boundary for stored content.
4. Validate with a harmless marker or controlled script action in your own
   account, then stop.
5. Write findings with `../../references/finding-output.md`.

## Where To Look

- Profiles, display names, comments, chat, tickets, CMS fields, rich text, and
  markdown preview.
- Import/export, email templates, reports, PDF generation, embedded widgets, and
  public sharing pages.
- Client routes that read query, hash, local storage, postMessage, or server JSON
  into dangerous DOM APIs.
- Admin moderation views that render user content with higher privileges.

## Common Patterns

- Escaping for one context followed by insertion into another context.
- Sanitized HTML later modified by linkifiers, markdown renderers, mention
  parsers, or syntax highlighters.
- DOM updates through `innerHTML`, unsafe template helpers, or framework bypass
  APIs.
- Stored content safe for normal users but unsafe in email, admin, export, or
  mobile WebView contexts.

## Protection And Bypass Themes

- Match bypass attempts to the exact output context instead of using generic
  payload lists.
- Look for double decoding, entity normalization, URL rewriting, SVG/MathML
  handling, and sanitizer/parser differences.
- Check CSP coverage: nonces, hashes, unsafe-inline, allowed script hosts, JSONP,
  upload origins, and legacy browser fallbacks.
- Test how filters handle broken tags, nested markup, unusual attributes, casing,
  comments, protocol normalization, and framework hydration.

## Safe Validation

- Use a unique marker, alert-free proof, or controlled callback only to owned
  infrastructure when program rules allow it.
- Avoid stealing cookies, tokens, private data, or executing actions against
  other users.
