---
name: file-upload
description: >-
  Use when authorized testing involves user-supplied files - avatars,
  attachments, imports, document conversion, archive extraction, media
  processing, plugin/theme installs, or any feature that accepts and later
  stores, serves, processes, or executes user files.
---

# File Upload

Upload bugs usually combine three layers: what the validator believes about
the file, what the storage layer does with it, and what downstream processors
do with it later. The validator/storage/processor disagreement is the bug.

## Workflow

1. Read `../../references/scope-safety.md` and the File Upload And Path
   Traversal section of `../../references/high-signal-must-tests.md`.
2. Map every upload entry point and downstream consumer: storage path,
   served URL, conversion pipeline, archive extraction, antivirus scan,
   indexing, mobile sync, email attachment delivery.
3. For each, identify what the validator checks (extension, MIME, magic
   bytes, image dimensions, archive structure) and what the consumer
   actually executes or renders.
4. Build a payload that satisfies the validator and exploits the consumer.
5. Validate with owned accounts, owned storage paths, and harmless payload
   markers.
6. Write findings with `../../references/finding-output.md`. State which
   layer the bug lives in.

## Where To Look

- Profile avatars, organization logos, attachment uploads on tickets/chat/
  email/comments, media library, file imports.
- Document conversion (PDF, DOCX, XLSX, HTML-to-PDF), image resizing,
  thumbnailing, video transcoding, OCR.
- Archive extraction (ZIP, TAR, RAR, 7z), source-control imports, template/
  theme/plugin installs, backup restore.
- Static-asset hosting paths, signed-URL download paths, CDN cache
  semantics for user files.

## Common Patterns

- Validator checks MIME type from `Content-Type` header (attacker
  controlled), not magic bytes.
- Magic bytes checked but file is later renamed by extension only; storage
  serves it with executable MIME based on extension.
- Image polyglot (e.g. valid JPEG header + PHP/JSP/HTML payload) accepted
  by both validator and renderer.
- Archive extraction follows symlinks, allows absolute paths, allows
  parent-directory paths, or writes outside the extraction root (Zip Slip,
  Tar Slip).
- Filenames containing `../`, encoded separators, null-like bytes, or
  Unicode normalization that resolves differently between validator and
  filesystem.
- Server-side conversion uses a library with known XXE/SSRF/RCE (ImageMagick,
  Ghostscript, LibreOffice, Pandoc) - see `../vulnerable-components/SKILL.md`.
- Antivirus or content scan runs in a worker that fetches the URL back -
  potential SSRF (see `../blind-ssrf/SKILL.md`).

## Protection And Bypass Themes

- Test double extensions (`.php.jpg`, `.svg.html`), uppercase variants,
  trailing characters (`.php.`, `.php\x00.jpg`), and OS-specific path
  separators.
- For images, embed scripts in EXIF, IPTC, XMP, SVG `<script>`, SVG
  `<foreignObject>`, and color profile fields.
- For archives: include symlink entries, absolute paths, `..` segments,
  long paths, oversize files, deep nesting, and zip-bomb-style entries
  (size-bounded for safe testing only).
- For document converters: test for embedded fonts, OLE objects, macros,
  external entity references, font/template fetches that hit the network.
- For storage: check whether files are served from an executable origin
  (same as the app) vs a sandboxed origin (different domain).

## Safe Validation

- Use harmless files with unique markers. For RCE candidates, prefer an
  OAST callback (`../oast-testing/SKILL.md`) over arbitrary code execution.
- For archive extraction, prove a write outside the extraction root using
  a single owned filename in a controlled path, not `/etc/passwd` style.
- Stop after one confirmed exploit per primitive.

## Anti-Patterns

- Uploading actual webshells. An OAST callback or a single harmless write
  is sufficient proof for a report.
- Reporting an SVG XSS that only fires when the file is served from a
  static asset domain with no cookies and no app context - check whether
  the cross-origin boundary makes it impactful.
- Reporting filename injection without showing it lands in a sink (path,
  storage key, log entry, downstream command).
