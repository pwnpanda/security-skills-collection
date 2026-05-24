---
name: path-traversal-lfi
description: >-
  Use when authorized testing involves server-side reads or writes whose path
  is built from user input - file download, image proxy, template loader,
  asset server, log download, attachment retrieval, tenant-scoped storage
  paths, or any endpoint that takes a filename, path segment, or storage key.
---

# Path Traversal And Local File Inclusion

Server-side path traversal (LFI / "local file inclusion" / arbitrary file
read) lets an attacker read - and sometimes include or write - files the
application did not intend. For *client-side* path concatenation in fetch/XHR
URLs use `../client-side-path-traversal/SKILL.md`.

## Workflow

1. Read `../../references/scope-safety.md` and the File Upload And Path
   Traversal section of `../../references/high-signal-must-tests.md`.
2. Enumerate every server-side endpoint that builds a filesystem path,
   object-storage key, template name, include directive, or URL from user
   input.
3. For each, identify the base directory or namespace, the validation
   (allowlist, denylist, prefix check, canonicalization), and the operation
   (read, include, write, delete, list).
4. Test traversal vectors against the validation order; the bug is usually
   "validation before canonicalization" or "canonicalization differs between
   validator and OS".
5. Validate with owned tenant-scoped files first, then a single innocuous
   target (e.g. a versioned but non-secret file) for proof.
6. Write findings with `../../references/finding-output.md`.

## Where To Look

- File download endpoints, "view attachment", "export", "print",
  "preview", and signed-URL generators.
- Image proxies, avatar fetchers, screenshot services, document
  conversion paths, log download.
- Template loaders, partial includes, plugin/theme path resolution.
- Tenant-scoped storage: `/tenants/{id}/files/{name}`, `/u/{user}/...`,
  signed-URL paths.
- Endpoints that take a filename in `name=`, `file=`, `path=`, `template=`,
  `view=`, `include=`, `page=`, `src=`, `key=`.

## Common Patterns

- `os.path.join` (Python) or `path.join` (Node) with attacker-controlled
  segment when the segment is absolute - it discards the base.
- Allowlist on extension (`.txt`) but no allowlist on directory; attacker
  reads any `.txt` file.
- Denylist on `../` but not `..%2F`, `..%5C`, `..%252F`, `....//`,
  `..\../`, or Unicode `../`.
- Canonicalization happens after validation; attacker uses an encoding
  that the validator does not decode but the OS does.
- Object-storage key built from user input without prefix enforcement;
  attacker accesses another tenant's keys.
- Symlinks in user storage that point into application directories;
  reading the symlink reads the target.

## Protection And Bypass Themes

- Try: `../`, `..\\`, `....//`, `..%2F`, `..%5C`, `..%252F`,
  `..%c0%af`, `..%ef%bc%8f`, mixed case, multiple separators.
- Try absolute paths: `/etc/passwd`, `/proc/self/environ`,
  `C:\windows\win.ini`, UNC paths `\\evil.example\share`.
- Try null-like and length tricks: `file.txt%00.jpg`, very long names,
  Unicode normalization (`./` -> `.%E2%88%95`).
- For URL-style paths (object storage), try alternate separators, double
  slashes, and percent-encoded slashes.
- For template/include sinks, try wrappers (`php://filter`, `phar://`,
  `file://`, `expect://`) on PHP; equivalent wrappers exist on other
  runtimes.
- Check parser parity: validator may use one path library, the consumer
  another.

## Safe Validation

- Read **one** harmless file first to prove the primitive: package
  manifest, version file, build manifest. Avoid `/etc/passwd` as proof if
  scope is sensitive.
- For write primitives, write to an owned tenant-scoped location or to a
  uniquely named file in a public-writable directory; do not overwrite
  application files.
- Stop at primitive confirmation. Do not enumerate the filesystem.

## Anti-Patterns

- Reading `/etc/shadow`, SSH keys, database credentials, or other operator
  secrets when a harmless file would have proven the bug.
- Confusing server-side LFI with client-side path traversal (CSPT) - the
  fix and impact chain are different.
- Reporting an `os.path.join` with sanitized input as vulnerable without
  proving the sanitization can be bypassed.
