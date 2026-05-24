---
name: blind-ssti
description: >-
  Use when authorized testing involves server-side template rendering where
  the rendered output is not directly visible - email templates, PDF/HTML
  exports, notification bodies, alert messages, invoice generation, scheduled
  reports, agent prompts, expression-language fields, or any sink that
  interprets user input as a template later.
---

# Blind SSTI

Server-side template injection is "blind" when the rendered output never
returns to the tester. Evidence comes from an OAST callback, a deterministic
timing oracle, or a structured side effect (a math result that arrives in
email). Engine fingerprinting matters because every engine has a different
syntax, sandbox, and side-effect surface.

## Workflow

1. Read `../../references/scope-safety.md`, the Injection section of
   `../../references/high-signal-must-tests.md`, and `../oast-testing/SKILL.md`.
2. Enumerate every field stored and later rendered by a template engine:
   email subject/body, invoice notes, PDF/HTML report fields, alert message
   templates, notification titles, agent-prompt fields, custom-field labels,
   expression-language inputs in workflow builders.
3. Send a small set of engine-fingerprinting probes that produce a *visible
   or side-effect difference* per engine family (Jinja, Twig, ERB, Liquid,
   Velocity, Freemarker, Handlebars, Smarty, Pebble, Mustache, Razor,
   Thymeleaf, Go templates, JEXL/SpEL/MVEL/OGNL). Use simple arithmetic
   payloads only.
4. Once an engine is identified, send a *blind* probe that triggers a unique
   Category B OAST marker (DNS lookup, HTTP fetch, or SMTP) only if template
   evaluation succeeded.
5. Wait for the deferred render path (queue worker, scheduled job, email
   pipeline). Some sinks fire seconds later, some hours later.
6. Attribute the callback through the marker log. Stop after one confirmed
   evaluation per finding.
7. Write the finding with `../../references/finding-output.md`. Include the
   field, engine fingerprint, payload, callback log entry, and the privilege
   the template runs with.

## Where To Look

- Email and notification subjects/bodies: welcome, invite, reset, billing,
  digest, alert, SOC, escalation messages.
- Invoice line items, PDF/HTML export fields, scheduled report sections,
  status-page incident templates.
- Workflow and automation builders: rule names, action descriptions, custom
  expressions, computed columns, calculation fields, dynamic placeholders.
- Agent or LLM prompt fields where the application interpolates user data
  through a template engine before sending.
- Logging and alert annotation pipelines that interpret structured fields as
  templates.

## Common Patterns

- Validation strips `<script>` and HTML but not `{{ }}`, `${ }`, `#{ }`,
  `<% %>`, `[[ ]]`, or `{% %}`.
- Rendering happens in a worker with broader permissions than the API tier.
- Multiple engines coexist: web UI uses one engine, email uses another, PDF
  export uses a third. Each may have a different sandbox.
- "Safe" expression languages allow object navigation or method calls that
  reach network, filesystem, or subprocess APIs.

## Protection And Bypass Themes

- Choose probes that produce a clear yes/no per engine. `{{7*7}}` returning
  `49` is a fingerprint; `${7*7}` returning `49` is a different fingerprint;
  neither rendering is also evidence (combined with other clues).
- For blind evaluation, use the engine's network primitive if available
  (`{{request|attr('application')...}}`-style for Jinja, OGNL/MVEL/SpEL
  network calls only when scope permits) and prefer a DNS-only OAST oracle.
- Time-based oracles (sleep, large arithmetic, large string repeat) help when
  no egress is available; use small, bounded deltas and stop after one
  confirmation.
- Sandbox escapes exist but are engine- and version-specific; confirm engine
  version before attempting any payload beyond fingerprinting.

## Safe Validation

- Stop at "evaluation confirmed" via a single OAST callback or a clean timing
  oracle. Do not escalate to file read, shell, or environment dump unless
  program rules explicitly accept that proof.
- One marker per (field, engine family, payload variant). Append to the log
  before sending.
- Do not abuse template eval to send messages to real users, write to
  databases, or hit third-party systems.

## Anti-Patterns

- Spraying every engine's syntax in one payload. You may get a callback but
  not know which engine fired, and you may trip a WAF rule that hides the
  true engine.
- Using payloads that read files, list directories, or dump environment
  variables before evaluation is confirmed. These are over-proof and often
  out of scope.
- Treating a callback without a marker-log entry as proof. Other testers and
  scanners share OAST listeners.
