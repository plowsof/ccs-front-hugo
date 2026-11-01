# Previews only: Coolify builds this for each pull request from a branch of this repository (one
# from a fork only once a maintainer has read it and deploys it by hand) and serves it at
# https://ccs-<PR>.beta.monerodevs.org (its link is commented on the PR, .github/workflows/preview.yml).
# The site with its example data (data/example/), built by the same pinned StageX Hugo as the
# releases and served by nginx with the web server's settings (preview/nginx.conf). Releases are made by container/build.sh, never this.
FROM stagex/core-busybox@sha256:a094d1b5ad06943713e75849248d7f89546d15a3e74f42ec5b8f02375fd3706d AS busybox
FROM stagex/core-musl@sha256:94f77e4b1841987a42efce52aac54dbf230c152cb55c62da1967189a2705df89 AS musl
FROM stagex/user-hugo@sha256:dfd71df268546323bb9f3b5ef356a21a513c339a3c867c9e56bbf593bb7f22fb AS hugo

FROM scratch AS build
COPY --from=busybox / /
COPY --from=musl / /
COPY --from=hugo / /
# Coolify's, for the commit line at the bottom of every page (layouts/_partials/preview.html)
ARG SOURCE_COMMIT
ARG COOLIFY_BRANCH
COPY . /src
# HUGO_PARAMS_PREVIEWTAGS: a page for each example tag (content/_content.gotmpl), as the server has;
# HUGO_PARAMS_PREVIEWONION: the footer's onion link filled in (layouts/baseof.html), as ccs-front-bash
# fills it with CCS_ONION: ccs.monerodevs.org's onion
RUN cd /src && HUGO_PARAMS_PREVIEWTAGS=1 HUGO_PARAMS_PREVIEWONION=euofv4oczbu32vr4my73diw3dwelcnazsnx55wd7ouoimrvstk4wqyid.onion hugo build --quiet --noBuildLock --cacheDir /tmp/hugo-cache --destination /site

# nginx, as on the real web server, so the theme button works too (StageX has no nginx; this
# official image, pinned by digest, serves previews only)
FROM nginx:stable-alpine@sha256:47928bf67eb62a1863cb08d9ecb52d3e704304ba614eaee17884204677702951
RUN rm -f /etc/nginx/conf.d/*
COPY preview/nginx.conf /etc/nginx/conf.d/ccs.conf
COPY --from=build /site /site
# an example of the feed ccs-front-bash writes (feed.xml), for the footer's RSS link (nginx puts
# the preview's own address in its links)
COPY preview/feed.xml /site/feed.xml
EXPOSE 8080
