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

**Pull request previews:** every pull request gets the site built from it, served at
`https://ccs-<PR>.beta.monerodevs.org` and linked in a comment on the pull request
(`.github/workflows/preview.yml`; a fork's once a maintainer has read it). The previews and their
comment were a task plowsof worked on for months, then ofrnxmr picked it up and finished it, with
blood, sweat and tears. Thank you, ofrnxmr.

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

## What ccs-front-bash fills in

The web server's gate (ccs-bash, `contrib/ccs-receive`) holds the same contract: it has this
release's zip too, and lets a page live only if it is one of these pages filled with these parts.
A new marker, part or `{{slot}}` is a new release of ccs-front-bash and of the gate as well.

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
empty), `{{funding_date}}` (a funding-required proposal's one date: when funding started, or the
date its front matter gives when there is none; needs ccs-front-bash with that slot), `{{gitlab_url}}`, `{{funds}}` (a milestone's), `{{date}}` (a milestone's
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
published itself. A preview has a page for each example tag as well, made from it the way
ccs-front-bash makes them (`content/_content.gotmpl`, only when the Dockerfile sets
`HUGO_PARAMS_PREVIEWTAGS`), and its tags link there. A release has only the example page, built as before.

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
- The piggy bank: ccs-front's `img/funding-required.png` (by rehrar, 2018; scaled to 760 px),
  BSD-3, Copyright (c) 2021, monero-project, `static/assets/piggy-LICENSE`.
- The Monero symbol: monero-project/monero-site `img/favicons.svg` (BSD-3).
- The General Fund's QR code (`static/assets/general-fund-qr.png`): monero-project/monero-site
  `public/contributing/donate-monero.png` (BSD-3); it reads as `monero:` and the General Fund address.
- Icons: [Lucide](https://lucide.dev) (lucide-static 1.47.0), ISC, `static/assets/icons-LICENSE`.
- Colours, sizes and font from the new getmonero.org (beta.getmonero.org).
- "What is the CCS" and "How to submit" text and screenshots from ccs-front (BSD-3, monero-project).
- DM Sans: SIL Open Font License, `static/assets/fonts/OFL.txt`.

The Contribute dropdown is a `<details>`, the Proposal / Milestones / Payouts tabs are radio
buttons shown by CSS: like today's ccs-front, and with no JavaScript.

## The Verify page

Visitors check a donation address in a view-only copy of the CCS wallet (`content/verify.md`):
ccs-front-bash fills `parts/verify.html` with the wallet's `{{address}}`, `{{viewkey}}` and
`{{wallet_source}}` (where those were published), or `parts/no-list.html` when the backend has no
signed list, and each donation box's link to it (`{{verify_link}}`, `parts/verify-link.html`).
The signed list of the wallet's subaddresses (ccs-front-bash's docs/setup.md, step 5) is for the
backend and the web server.
