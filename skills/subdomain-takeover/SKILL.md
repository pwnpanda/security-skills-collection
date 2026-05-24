---
name: subdomain-takeover
description: >-
  Use when authorized testing involves DNS records that may point to dangling
  cloud resources - CNAMEs or A records for unclaimed S3 buckets, GitHub
  Pages, Heroku apps, Azure resources, Shopify stores, Fastly services,
  Vercel/Netlify projects, abandoned SaaS tenants, expired domain
  registrations, or any third-party hosting where the provider lets a new
  user claim the name.
---

# Subdomain Takeover

A subdomain takeover happens when a DNS record (CNAME, ALIAS, or A) points
at a third-party service that no longer owns the resource. The attacker
re-claims the resource at the provider, and the subdomain serves attacker
content under the target's name - good for phishing, cookie scoping
attacks, SSO redirect chains, and CSP bypass.

## Workflow

1. Read `../../references/scope-safety.md`. Treat in-scope wildcard
   subdomain rules carefully; provider acceptance of a claim is an
   active mutation.
2. Enumerate the target's subdomains from passive sources (cert
   transparency, public datasets) and from active brute-force where
   program rules allow.
3. Resolve every subdomain. For each unresolved or NXDOMAIN-with-CNAME
   result, fingerprint the provider from the CNAME target or the HTTP
   response of the underlying host.
4. Match the fingerprint to a known-vulnerable pattern (see
   "can-i-take-over-xyz" community list as a starting reference).
5. Confirm the resource is actually unclaimed at the provider before
   claiming. Some providers verify domain ownership; some do not.
6. Claim with a unique marker page. Do not host phishing, exfil scripts,
   or attacker-controlled cookies that would weaponise the bug.
7. Write findings with `../../references/finding-output.md`. Include
   DNS records, provider name, the fingerprint, and the marker page.
   Disclose immediately so the target can reclaim.

## Where To Look

- Static-hosting CNAMEs: GitHub Pages (`*.github.io`), GitLab Pages,
  Bitbucket Pages, Netlify, Vercel, Cloudflare Pages, Surge, Read the
  Docs.
- Object storage: S3 (`*.s3.amazonaws.com`,
  `*.s3-website-*.amazonaws.com`), GCS, Azure Blob (`*.blob.core.
  windows.net`), Backblaze B2.
- PaaS apps: Heroku (`*.herokuapp.com`), Azure Web Apps (`*.azurewebsites.
  net`, `*.cloudapp.net`, `*.trafficmanager.net`), AWS Elastic Beanstalk
  (`*.elasticbeanstalk.com`), AWS CloudFront (`*.cloudfront.net`).
- SaaS: Shopify (`shops.myshopify.com`), Zendesk (`*.zendesk.com`),
  HelpScout, UserVoice, FreshDesk, Statuspage, Tumblr, Tilda,
  Webflow, Wishpond, Unbounce, Pingdom public reports, Tictail.
- CDN edges: Fastly, Akamai, Cloudflare (when a custom hostname is
  un-attached but the DNS record stays).
- Mail: SPF includes referencing dangling domains; MX records to
  decommissioned providers.
- Internal / legacy: `*.staging`, `*.demo`, `*.preview`, `*.old`,
  `*.app-{numeric}`.

## Common Patterns

- Marketing campaign created a Heroku app, pointed DNS at it, then the
  campaign ended and the dyno was deleted - DNS record stays.
- Acquired company's status page on Statuspage was migrated to the new
  parent's account, but the old `status.acquired.com` CNAME remains.
- Engineering reused a CNAME for repeated experiments; one round
  released the resource at the provider but no one updated DNS.
- Documentation site CNAME points to a `readthedocs.io` slug that was
  renamed.
- An S3 bucket was renamed and the old name fell back to the global
  namespace.

## Protection And Bypass Themes

- Provider acceptance varies: some (Heroku, S3 in certain regions)
  require domain verification before serving custom hostnames; others
  do not.
- A `dig` returning NXDOMAIN with a CNAME chain is the canonical
  fingerprint, but some providers return a 404 with a provider-branded
  page instead - that page string is the fingerprint.
- Wildcard records (`*.target.com -> static.target.com`) hide takeovers
  by serving the wildcard's content for arbitrary names; the takeover
  exists if the wildcard *target* is dangling.
- For HTTPS, some providers issue certs only after ownership proof;
  takeover may serve HTTP but not HTTPS, limiting impact (cookies
  scoped to HTTPS, etc.).
- Impact escalates when: cookies are scoped to a parent domain (cookie
  scoping attacks), the parent runs OAuth that accepts subdomain
  redirects, CSP lists the parent domain as a script source, or SSO
  trusts subdomain SAML callbacks.

## Safe Validation

- Claim the resource and serve a static marker page with a unique
  string the program can later verify (`takeover-poc-<uuid>`).
- Do not host phishing forms, JavaScript that reads target cookies,
  exfiltration scripts, or look-alike login pages.
- For impact chains (cookie scoping, CSP bypass), document the chain
  in the report but do not exploit it against real users.
- Stop after one resource per program is claimed for proof.

## Anti-Patterns

- Listing every subdomain that fingerprints as vulnerable without
  confirming the claim works at the provider; some report templates
  filter these as noise.
- Claiming a resource and immediately weaponising it (login form,
  exfil script). Programs reject these as out-of-scope abuse.
- Reporting NXDOMAIN as takeover; NXDOMAIN with a *vulnerable provider
  fingerprint* is the bug.
- Reporting CNAME to a healthy resource you just happen to also own;
  that is a recon finding, not a takeover.
