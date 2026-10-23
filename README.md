# ccs-front-hugo

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

## What ccs-front-bash fills in

**Markers** around everything that changes, in the built pages:

| Marker | Where | Filled with |
|---|---|---|
| `<!-- ccs:list fr -->…<!-- /ccs:list fr -->` (`idea`, `fr`, `wip`, `cp`) | `explore.html`, the stage pages | one `parts/card-<stage>.html` per proposal, or `parts/empty.html` |
| `<!-- ccs:donate -->…<!-- /ccs:donate -->` | funding-required proposal pages | `parts/donate.html`: raised, progress, and the Contribute dropdown |
| `<!-- ccs:funded -->…<!-- /ccs:funded -->` | other proposal pages | `parts/funded.html` |
| `<!-- ccs:milestones -->…<!-- /ccs:milestones -->` | proposal pages, Milestones tab | `parts/milestone-done.html` / `milestone-todo.html` per milestone |
| `<!-- ccs:payouts -->…<!-- /ccs:payouts -->` | proposal pages, Payouts tab | `parts/payout.html` per payout |
| `<!-- ccs:filters -->…<!-- /ccs:filters -->` | `explore.html`, the tag pages (sidebar) | `parts/filters.html` holding `parts/filter.html` per tag (All first), or nothing if no proposal has tags |
| `<!-- ccs:title -->…<!-- /ccs:title -->` | the tag page | the tag's name |

**Parts** (`public/parts/`) are fragments with `{{slot}}`s: `{{name}}`, `{{author}}`, `{{date}}`,
`{{url}}`, `{{amount}}`, `{{raised}}`, `{{percentage}}`, `{{contributors}}`, `{{milestones}}`,
`{{done}}`, `{{segments}}` (made of `segment-done.html` / `segment-todo.html`), `{{address}}`,
`{{pending_note}}` (" · 1.5 XMR pending", or empty), `{{funding_note}}` (" · funding since …", or
empty), `{{gitlab_url}}`, `{{funds}}` (a milestone's), `{{date}}` (a milestone's
completion or a payout's). Each is replaced with its value HTML-escaped once
(ccs-bash's JSON is already escaped). `{{qr}}` is the QR code
as a PNG data URI (`data:image/png;base64,…`, ccs-bash's `donate-qr-code`). The exception is
`{{body}}`, the proposal's Markdown rendered with everything escaped first.

**Tags** (the front matter's `tags:`, in ccs-bash's JSON as `tags`): `{{tags}}` on a card is a
`parts/label.html` per tag (plain labels: the card is one link), `{{tag_links}}` on a proposal
page a `parts/label-link.html` per tag (`{{tag}}`, `{{href}}`). `filter.html` has `{{tag}}`,
`{{href}}`, `{{count}}` (empty for All) and `{{active}}` (" active" or empty). All three have
`{{color}}`: `tag-0` to `tag-7` (the tag's colour, from its name) or `tag-all`. The filters
(`parts/filters.html`, around `{{filters}}`) sit in the sidebar of Explore and the tag pages.
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
- Nothing from other sites: fonts and icons are in `static/assets/`.
- Raw HTML in Markdown is dropped (`markup.goldmark.renderer.unsafe = false`).

## Credits

- Layout after the concept screenshots in redsh4de's CCS proposal
  ("CCS Frontend Astro Rewrite").
- The piggy bank: from redsh4de/monero-ccs-site (`src/assets/funding-required.png`, branch
  `feat/landing-draft`), BSD-3, Copyright (c) 2026, SyntheticBird, `static/assets/piggy-LICENSE`.
- The Monero symbol: monero-project/monero-site `img/favicons.svg` (BSD-3).
- Icons: [Lucide](https://lucide.dev) (lucide-static 1.47.0), ISC, `static/assets/icons-LICENSE`.
- Colours, sizes and font from the new getmonero.org (beta.getmonero.org).
- "What is the CCS" and "How to submit" text and screenshots from ccs-front (BSD-3, monero-project).
- DM Sans: SIL Open Font License, `static/assets/fonts/OFL.txt`.

The Contribute dropdown is a `<details>`, the Proposal / Milestones / Payouts tabs are radio
buttons shown by CSS: like today's ccs-front, and with no JavaScript.
