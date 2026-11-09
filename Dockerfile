# Previews only. Releases are built by container/build.sh, never this.
# Coolify builds this for each pull request and serves it at https://ccs-<PR>.beta.monerodevs.org.
# A PR from a fork is built only after a maintainer has read it.
# The site with its example data, built by the same pinned Hugo as releases,
# and served by nginx with the web server's settings.
FROM stagex/core-busybox@sha256:a094d1b5ad06943713e75849248d7f89546d15a3e74f42ec5b8f02375fd3706d AS busybox
FROM stagex/core-musl@sha256:94f77e4b1841987a42efce52aac54dbf230c152cb55c62da1967189a2705df89 AS musl
FROM stagex/user-hugo@sha256:dfd71df268546323bb9f3b5ef356a21a513c339a3c867c9e56bbf593bb7f22fb AS hugo

FROM scratch AS build
COPY --from=busybox / /
COPY --from=musl / /
COPY --from=hugo / /
# Coolify's variables, for the commit line at the bottom of every page.
ARG SOURCE_COMMIT
ARG COOLIFY_BRANCH
COPY . /src
# HUGO_PARAMS_PREVIEWTAGS: a page for each example tag, as on the server.
# HUGO_PARAMS_PREVIEWONION: fills in the footer's onion link with ccs.monerodevs.org's onion.
RUN cd /src && HUGO_PARAMS_PREVIEWTAGS=1 HUGO_PARAMS_PREVIEWONION=euofv4oczbu32vr4my73diw3dwelcnazsnx55wd7ouoimrvstk4wqyid.onion hugo build --quiet --noBuildLock --cacheDir /tmp/hugo-cache --destination /site

# nginx, as on the real web server, so the theme button works.
# StageX has no nginx, so this is the official image, pinned by digest.
FROM nginx:stable-alpine@sha256:47928bf67eb62a1863cb08d9ecb52d3e704304ba614eaee17884204677702951
RUN rm -f /etc/nginx/conf.d/*
COPY preview/nginx.conf /etc/nginx/conf.d/ccs.conf
COPY --from=build /site /site
# An example feed, for the footer's RSS link. nginx puts in the preview's own address.
COPY preview/feed.xml /site/feed.xml
EXPOSE 8080
