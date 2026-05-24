---
name: prototype-pollution
description: >-
  Use when authorized testing involves JavaScript object merging, deep clone,
  query-string parsing, body parsing, options builders, settings/config
  merging, or any code path that copies keys from user input into an object
  without filtering prototype-like keys.
---

# Prototype Pollution

Prototype pollution is a JavaScript-specific class where polluting
`Object.prototype` (or another shared prototype) changes the behavior of
unrelated code downstream. The pollution itself is not the impact; a gadget
elsewhere converts it into authentication bypass, RCE, XSS, or denial of
service.

## Workflow

1. Read `../../references/scope-safety.md` and the API, GraphQL, Mass
   Assignment, And Prototype Pollution section of
   `../../references/high-signal-must-tests.md`.
2. Identify object-merge or deep-set sinks. On the server: settings,
   config, query parsers; on the client: state merges, options
   builders, framework hydration.
3. Inject `__proto__`, `constructor.prototype`, and `prototype`-shaped
   keys; verify pollution by observing a benign property appear on an
   unrelated object.
4. Find a gadget that turns pollution into security impact: missing-
   default-via-prototype reads, template compilation, command execution,
   bypass of authorization defaults.
5. Validate with owned accounts and the smallest possible pollution
   value.
6. Write findings with `../../references/finding-output.md`. Show both
   the pollution primitive and the gadget chain.

## Where To Look

- Body parsers that accept nested JSON or form-encoded bracket syntax
  (`a[__proto__][polluted]=1`).
- Query-string parsers (`qs`, `query-string`) configured to allow
  deep nesting.
- Deep-merge utilities (`lodash.merge`, `merge`, `defaults-deep`,
  `extend`, `deepmerge`) when called on user input.
- Configuration loaders (YAML, JSON, INI) that merge user-supplied
  values into a defaults object.
- Client-side state stores, framework options, plugin loaders.
- Templating engines whose helper resolution falls back to prototype
  lookup.

## Common Patterns

- An options builder reads `options.allowAdmin` and pollution sets
  `Object.prototype.allowAdmin = true`.
- A sanitizer reads `config.allowedTags` and pollution adds a tag
  that lets `<script>` through.
- A path-resolver or template loader reads `options.tag` and pollution
  causes loading of an attacker-controlled template.
- Server-side rendering uses `Object.assign({}, defaults, userInput)`
  - safer than merge - but the defaults object itself was polluted by
  an earlier request.

## Protection And Bypass Themes

- Try multiple syntax forms: nested JSON `{"__proto__":{"x":1}}`,
  bracket form `a[__proto__][x]=1`, dotted `__proto__.x=1`,
  `constructor[prototype][x]=1`.
- Test whether `Object.freeze(Object.prototype)` is applied
  (modern hardening).
- Look for gadget chains in installed packages (server-side) or in
  the loaded framework (client-side) - many CVE writeups document
  per-library gadgets.
- For client-side pollution, look for DOM clobbering interactions and
  XSS via template hydration.

## Safe Validation

- Show pollution with a property name that has zero security impact
  (e.g. `__proto__.proofOfPollution = "marker"`) and observe it on a
  fresh empty object.
- Demonstrate one gadget chain end-to-end on owned data only.
- For long-lived processes, prefer per-request pollution proofs over
  persistent pollution that could affect other users in the test
  environment.

## Anti-Patterns

- Reporting that `__proto__` is reflected in an echo endpoint without
  showing pollution of an empty object.
- Reporting pollution without a gadget that turns it into security
  impact - the pollution alone is rarely accepted as a bounty finding.
- Persisting pollution in a shared environment that affects other
  testers or real users.
