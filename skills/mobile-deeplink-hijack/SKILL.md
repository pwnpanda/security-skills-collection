---
name: mobile-deeplink-hijack
description: >-
  Use when authorized testing involves mobile app deep links - iOS
  Universal Links and custom URL schemes, Android App Links and intent
  filters and custom schemes, deep-link OAuth callbacks, magic-link
  authentication flows, in-app browser handoffs, or cross-app navigation
  on iOS or Android.
---

# Mobile Deep Link Hijack

Mobile deep links bind a URL to an installed app. The bugs concentrate at
the boundary where the OS decides which app handles a URL, and where the
app decides what to do with the URL's data. iOS Universal Links require
a verified domain association file; Android App Links require Digital
Asset Links; both fall back to custom URL schemes when the verification
fails. Custom schemes are first-come-first-served per device, which
enables intent / scheme hijack by a malicious app.

## Workflow

1. Read `../../references/scope-safety.md`.
2. For each mobile app in scope, pull the manifest: iOS Associated
   Domains entitlements, `apple-app-site-association` (AASA) JSON,
   Android `AndroidManifest.xml` intent-filter blocks, Digital Asset
   Links `assetlinks.json`.
3. Enumerate every URL pattern the app claims to handle: scheme,
   host, path prefix or regex, and the corresponding in-app handler.
4. For each, test:
   - **Custom scheme collision**: can another app register the same
     scheme and intercept?
   - **Path-prefix coverage**: does AASA / assetlinks declare narrow
     paths, or `*` everything?
   - **Verification status**: is the domain association file served
     correctly, with correct MIME type and over HTTPS?
   - **Data handling**: does the in-app handler trust the deep link's
     parameters (auth tokens, redirect targets, account selectors)?
5. For OAuth-over-deep-link flows, test whether an attacker app can
   register the redirect scheme and intercept the auth code.
6. Validate with an owned attacker app on an owned test device.
7. Write findings with `../../references/finding-output.md`. State the
   scheme/host/path, the verification gap, and the data leaked or
   action triggered.

## Where To Look

- iOS Universal Links: `applinks:example.com` entitlements,
  `https://example.com/.well-known/apple-app-site-association`.
- iOS custom URL schemes: `MyApp://...` declared in Info.plist
  `CFBundleURLTypes`.
- Android App Links: intent-filter with `android:autoVerify="true"`
  + `https://example.com/.well-known/assetlinks.json`.
- Android custom intents: implicit intents with action `VIEW` and
  custom schemes/data fields.
- OAuth/OIDC native flows using loopback or custom scheme
  redirect URIs.
- Magic-link authentication where the email link triggers a deep
  link.
- In-app browsers (SFSafariViewController, Chrome Custom Tabs) that
  hand off URLs to the OS.

## Common Patterns

- AASA file declares overly broad path (`"paths": ["*"]`); an
  attacker page on the same domain can trigger any in-app handler.
- AASA served with wrong MIME (`application/json` required; some
  servers return `text/html`); iOS silently falls back to scheme,
  enabling hijack.
- Custom scheme handler trusts the deep link's `token` parameter and
  logs the user in - intercept the link, log in as victim.
- OAuth native client uses a custom scheme; another app registers
  the same scheme and receives the auth code.
- Universal Link or App Link target has not enforced HTTPS for the
  domain association file; a network attacker can replace it.
- Deep-link handler executes a destructive action (account delete,
  payout change) without re-prompt or step-up auth.

## Protection And Bypass Themes

- For iOS, the verification file path is fixed:
  `https://<domain>/.well-known/apple-app-site-association` or
  `https://<domain>/apple-app-site-association`. It must be HTTPS,
  no redirects, valid JSON, and signed for older iOS or proxied
  through Apple's CDN. Failures fall back to scheme.
- For Android, `assetlinks.json` must be served at
  `https://<domain>/.well-known/assetlinks.json` and verified at
  install. Failures fall back to disambiguation dialog or scheme.
- For custom-scheme races, another app with the same scheme can
  intercept; Android shows a chooser, iOS picks unpredictably (last
  installed often wins, but undefined).
- For OAuth-over-deep-link, prefer PKCE-required flows; without
  PKCE, the auth code is the secret and any app receiving the link
  can complete the exchange.
- For Universal Link / App Link, an attacker page on the same domain
  can trigger handlers if path coverage is `*` - look at this when
  testing self-XSS or upload features that serve attacker HTML on
  the target domain.

## Safe Validation

- Owned attacker app on an owned test device (simulator or
  physical). Owned victim account.
- For OAuth interception, use a self-issued client when the program
  permits; do not capture codes for real users.
- For deep-link parameter trust, trigger one privileged action on
  your own account.
- Stop after one reproducible hijack per scheme/host.

## Anti-Patterns

- Reporting "AASA missing" without showing a downstream impact
  (fallback hijack, OAuth interception, action-without-step-up).
- Targeting real users with deep-link-bearing emails or messages.
- Confusing in-app browser cookie sharing with deep-link hijack.
- Building a malicious app that mimics the target's UI to phish
  users; one technical PoC of scheme interception is enough.
