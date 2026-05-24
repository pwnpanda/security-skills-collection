---
name: xml-external-entities
description: >-
  Use when authorized testing involves XML, SOAP, SAML, SVG, DOCX/XLSX/PPTX,
  RSS, plist, or other XML-based input parsed by server-side code or backend
  services.
---

# XML External Entities

OWASP mapping: A4:2017 XML External Entities (XXE). Related to Injection and
SSRF in later OWASP editions.

## Workflow

1. Read `../../references/scope-safety.md` and the relevant section of
   `../../references/high-signal-must-tests.md`.
2. Identify every XML parser and wrapper format accepted by the application.
3. Determine parser features: DTDs, external entities, parameter entities,
   XInclude, schema imports, stylesheet processing, and network/file access.
4. Validate with harmless self-owned callbacks or non-sensitive local markers
   only when allowed.
5. Write findings with `../../references/finding-output.md`.

## Where To Look

- SOAP APIs, SAML flows, XML import/export, SVG upload, office document upload,
  report generation, RSS/Atom ingestion, and mobile config endpoints.
- File processors that unpack archives and parse embedded XML.
- Legacy libraries, Java/.NET XML defaults, and code that disables one XML
  feature but leaves others enabled.

## Common Patterns

- DTD disabled in one parser path but enabled in a secondary converter.
- XML validation, transformation, or schema fetching that happens before business
  validation.
- Server accepts JSON at the edge but converts or forwards XML internally.
- Upload checks validate extension or MIME type but not embedded XML behavior.

## Protection And Bypass Themes

- Check all XML entry points, not just obvious `.xml` endpoints.
- Review whether DTDs, external general entities, external parameter entities,
  XInclude, and XSLT/network fetches are disabled independently.
- Look for parser differentials across upload scanners, converters, validators,
  and downstream services.
- Check archive wrappers where XML is nested inside accepted office or vector
  formats.

## Safe Validation

- Do not read sensitive files. Use a self-owned HTTP endpoint, harmless marker,
  or parser error that proves external resolution without disclosing data.
