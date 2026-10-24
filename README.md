# ccs-front-hugo

[![check](https://github.com/plowsof/ccs-front-hugo/actions/workflows/check.yml/badge.svg)](https://github.com/plowsof/ccs-front-hugo/actions/workflows/check.yml) [![release](https://github.com/plowsof/ccs-front-hugo/actions/workflows/release.yml/badge.svg)](https://github.com/plowsof/ccs-front-hugo/actions/workflows/release.yml)

The design of the Monero CCS site as static HTML, built with [Hugo](https://gohugo.io).
No JavaScript, nothing loaded from other sites, and light or dark following the OS setting.

Hugo only runs **offline**, once per design change. Its output, `public/`, is the
"original" that [ccs-front-bash](https://github.com/plowsof/ccs-front-bash) copies and fills
in on the backend every run (see [the design](https://github.com/plowsof/ccs-bash/blob/master/docs/design.md)).
No framework runs on a live machine.

```
hugo build --cleanDestinationDir   # Hugo 0.167.0 → public/
```

Preview with `hugo server`, or any static server on `public/`. The pages show example data
in ccs-bash's JSON format (`data/example/`).

The pages and URLs are today's ccs-front's, so links keep working: `/`, `/ideas/`,
`/funding-required/`, `/work-in-progress/`, `/completed-proposals/`, `/proposals/<name>.html`,
`/donate/`, `/what-is-ccs/`, `/how-to-ccs/`, plus `/explore/` (every stage on one page).

## The reproducible zip

`container/build.sh` builds the site into `dist/ccs-front-hugo.zip` with StageX's Hugo, busybox and
zip (pinned by digest in `container/images`, each signed by two or more StageX maintainers, checked
every build from the copy in `container/sigs/`), run by StageX's BuildKit (`container/builder.Dockerfile`)
rather than the host's, with no network. `container/update-images.sh` repins and refreshes the copy. The same commit gives the same zip, byte for byte, on any machine:
CI builds it on two at once and compares, and a tag `v*` attaches the zip and its sha256 to a
GitHub release only when both match. That zip, sha256 checked, is what goes to the ccs-front-bash
machine as the original (`unzip` it into `/opt/ccs-front-hugo/public`).

## Why Hugo

Both this design and the Astro build of the [getmonero.org beta](https://github.com/monero-project/monero-site/tree/beta)
(its `beta` branch at `a21c9a2`, October 2026) make plain static files, download what they need
first and then build offline, and check in CI that two builds give the same archive. The
difference is what the build has to trust:

| | ccs-front-hugo | the Astro beta |
|---|---|---|
| The build tools | Hugo, busybox and zip: three programs | Node and pnpm, then 812 npm packages in the lockfile, about 700 of them installed on a Linux machine (about 300 for the site, the rest lint and format tools) |
| Who built the programs that run | StageX, from source, reproducibly | each package's own project; some ship ready-made binaries: `esbuild`, `sharp`/libvips, `lightningcss`, `rolldown`, Astro's compiler |
| How a download is checked | pinned by digest, and signed by two or more StageX maintainers who each rebuilt it | a hash per package in the lockfile: the same file as when the lockfile was last updated |
| The same commit gives the same output | checked in CI, and attested by independent builders in [ccs-sigs](https://github.com/plowsof/ccs-sigs) | checked in CI (two runs, hashes compared) |

The beta's pnpm settings are good hardening against a bad npm release: `--frozen-lockfile`, no
version newer than 14 days (`minimumReleaseAge`), no downgrades of a package's trust level
(`trustPolicy: no-downgrade`), no dependencies from git or URLs (`blockExoticSubdeps`), and install
scripts off except `lefthook`'s. They limit when and how a package can change. A hash still only
says a file is the one locked in, not that it was good when it was; the 14 days narrow that, and
each of the 700 packages has its own publishers to trust. Here there are three programs, each
rebuilt from source and signed by more than one person.

Two things hold either way. Hugo isn't small inside: it compiles in 180 Go modules (its `go.mod` at v0.167.0),
fixed by Hugo's `go.sum` and built by StageX, but trusted all the same. And the donation addresses
don't depend on the build: the gate checks each one against the signed list, whatever made the
page. What a bad build tool could still do is anything else, such as add a script or change links.

Astro is a fair choice for getmonero.org, which needs translations and generated images. The CCS
pages are a few templates filled with data, which Hugo does without anything else.

## What ccs-front-bash fills in

**Markers** around everything that changes, in the built pages:

| Marker | Where | Filled with |
|---|---|---|
| `<!-- ccs:list fr -->…<!-- /ccs:list fr -->` (`idea`, `fr`, `wip`, `cp`) | the stage pages, the tag page | one `parts/card-<stage>.html` per proposal, or `parts/empty.html` |
| `<!-- ccs:donate -->…<!-- /ccs:donate -->` | funding-required proposal pages | `parts/donate.html`: raised, progress, and the Contribute dropdown |
| `<!-- ccs:funded -->…<!-- /ccs:funded -->` | other proposal pages | `parts/funded.html` |
| `<!-- ccs:milestones -->…<!-- /ccs:milestones -->` | proposal pages, Milestones tab | `parts/milestone-done.html` / `milestone-todo.html` per milestone |
| `<!-- ccs:payouts -->…<!-- /ccs:payouts -->` | proposal pages, Payouts tab | `parts/payout.html` per payout |
| `<!-- ccs:filters -->…<!-- /ccs:filters -->` | every page's sidebar (proposal pages too) | `parts/filters.html` holding `parts/filter.html` per tag (All first), or nothing if no proposal has tags |
| `<!-- ccs:title -->…<!-- /ccs:title -->` | the tag page | the tag's name |
| `<!-- ccs:count fr -->…<!-- /ccs:count fr -->` (`idea`, `fr`, `wip`, `cp`) | every page's sidebar (proposal pages too) | how many proposals the stage has |
| `<!-- ccs:number fr -->…<!-- /ccs:number fr -->` (`idea`, `fr`, `wip`, `cp`) | the home page's stage cards | the same number (a marker is used once a page) |

**Parts** (`public/parts/`) are fragments with `{{slot}}`s: `{{name}}`, `{{author}}`, `{{date}}`,
`{{url}}`, `{{amount}}`, `{{raised}}`, `{{percentage}}`, `{{contributors}}`, `{{milestones}}`,
`{{done}}`, `{{segments}}` (made of `segment-done.html` / `segment-todo.html`), `{{address}}`,
`{{pending_note}}` (" · 1.5 XMR pending", or empty), `{{funding_note}}` (" · funding since …", or
empty), `{{gitlab_url}}`, `{{funds}}` (a milestone's), `{{date}}` (a milestone's
completion or a payout's). Each is replaced with its value HTML-escaped once
(ccs-bash's JSON is already escaped). `{{qr}}` is the QR code
as a PNG data URI (`data:image/png;base64,…`, ccs-bash's `donate-qr-code`). The exception is
`{{body}}`, the proposal's Markdown rendered with everything escaped first.

**Votes:** `parts/card-idea.html` has `{{upvotes}}` and `{{downvotes}}`, the idea's 👍/👎 on its
merge request (ccs-bash's `upvotes`/`downvotes`, from GitLab or Forgejo).

**Tags** (the front matter's `tags:`, in ccs-bash's JSON as `tags`): `{{tags}}` on a card is a
`parts/label.html` per tag (plain labels: the card is one link), `{{tag_links}}` on a proposal
page a `parts/label-link.html` per tag (`{{tag}}`, `{{href}}`). `filter.html` has `{{tag}}`,
`{{href}}`, `{{count}}` and `{{active}}` (" active" or empty). All three have `{{color}}`:
`tag-0` to `tag-7` (the tag's colour, from its name). The filters (`parts/filters.html`,
around `{{filters}}`) sit in the sidebar.

**The sidebar** (stages with counts, tags) is on every page, once: the left column of the stage
and tag pages on a wide screen, and on a phone the drawer the menu button opens from the left
(a checkbox and CSS, no JavaScript), with the site's links. There is no Explore page: the
header's "Proposals" goes to Funding Required.
`explore/tag/example/index.html` is the tag page: copied to `explore/tag/<tag>/` for each tag
(the same depth, so its links work), with its lists, filters and title filled; it is not
published itself. In the preview every tag links to it (it shows "Abandoned").

**Proposal pages** are `parts/proposal-fr.html`, `proposal-wip.html` and `proposal-cp.html` with
their slots filled, `{{milestones_list}}` and `{{payouts_list}}` being the milestone and
payout parts. Like the proposal pages they become, they sit one folder down, so their
links work unchanged. `parts/` is not pushed to the web server.

The parts are rendered from the same templates as the example pages, so they can't drift apart.

## Rules

- No `<script>`, no inline event handlers, no `style=` attributes: the site works under
  `Content-Security-Policy: default-src 'none'; style-src 'self'; img-src 'self' data:; font-src 'self'`.
- Nothing from other sites: fonts are in `static/assets/`, icons in `assets/assets/icons/` (PNG, no SVG: Tor Browser at "Safest" draws none; `tools/icons-png.sh` makes them from `tools/icons.svg`).
- Raw HTML in Markdown is dropped (`markup.goldmark.renderer.unsafe = false`).

## Credits

- Layout after the concept screenshots in redsh4de's CCS proposal
  ("CCS Frontend Astro Rewrite").
- The piggy bank: from redsh4de/monero-ccs-site (`src/assets/funding-required.png`, branch
  `feat/landing-draft`), BSD-3, Copyright (c) 2026, SyntheticBird, `static/assets/piggy-LICENSE`.
- The Monero symbol: monero-project/monero-site `img/favicons.svg` (BSD-3).
- The General Fund's QR code (`static/assets/general-fund-qr.png`): monero-project/monero-site
  `public/contributing/donate-monero.png` (BSD-3); it reads as `monero:` and the General Fund address.
- Icons: [Lucide](https://lucide.dev) (lucide-static 1.47.0), ISC, `static/assets/icons-LICENSE`.
- Colours, sizes and font from the new getmonero.org (beta.getmonero.org).
- "What is the CCS" and "How to submit" text and screenshots from ccs-front (BSD-3, monero-project).
- DM Sans: SIL Open Font License, `static/assets/fonts/OFL.txt`.

The Contribute dropdown is a `<details>`, the Proposal / Milestones / Payouts tabs are radio
buttons shown by CSS: like today's ccs-front, and with no JavaScript.

## The signed subaddress list

Every donation address on the site is checked against a list of the wallet's subaddresses, signed
with a key made only for that and destroyed right after (ccs-front-bash's docs/setup.md, step 5).
Nothing about it is built in here: ccs-front-bash fills the Verify page (`parts/verify.html`, with
`{{fingerprint}}`, and the wallet's `{{address}}`, `{{viewkey}}`, `{{network}}` and
`{{wallet_source}}` (where the address and view key were published) for asking a copy of the
wallet about an address; or `parts/no-list.html`) and each donation box's link (`{{verify_link}}`,
`parts/verify-link.html`). The key's fingerprint, published here too so it doesn't come only from
the site it vouches for:

| | |
|---|---|
| testnet CCS (ccs.monerodevs.org), 15,000 subaddresses, since 2026-10-24 | `1997 07EE FAE5 4975 D00F  D471 FDA3 BB89 E3EF EFF8` |
| (the testnet's first list, 100,000, until 2026-10-24; its first 15,000 lines are the list above) | `3CB9 30B3 11B4 9080 8775  A4C9 290C 5085 B75F 4D61` |
