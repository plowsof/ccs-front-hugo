# Previews only: Coolify builds this for each pull request and serves it at
# https://ccs-<PR>.beta.monerodevs.org (its link is commented on the PR, .github/workflows/preview.yml).
# The site with its example data (data/example/), built by the same pinned StageX Hugo as the
# releases and served by StageX's busybox httpd. Releases are made by container/build.sh, never this.
FROM stagex/core-busybox@sha256:a094d1b5ad06943713e75849248d7f89546d15a3e74f42ec5b8f02375fd3706d AS busybox
FROM stagex/core-musl@sha256:94f77e4b1841987a42efce52aac54dbf230c152cb55c62da1967189a2705df89 AS musl
FROM stagex/user-hugo@sha256:dfd71df268546323bb9f3b5ef356a21a513c339a3c867c9e56bbf593bb7f22fb AS hugo

FROM scratch AS build
COPY --from=busybox / /
COPY --from=musl / /
COPY --from=hugo / /
# Coolify's, for the commit line at the bottom of every page (layouts/_partials/preview.html)
ARG SOURCE_COMMIT
ARG COOLIFY_PREVIEW
ARG COOLIFY_BRANCH
COPY . /src
RUN cd /src && hugo build --quiet --noBuildLock --cacheDir /tmp/hugo-cache --destination /site \
    && printf 'E404:/site/404.html\n' > /httpd.conf

FROM scratch
COPY --from=busybox / /
COPY --from=build /site /site
COPY --from=build /httpd.conf /etc/httpd.conf
USER 65534:65534
EXPOSE 8080
CMD ["/bin/busybox", "httpd", "-f", "-p", "8080", "-h", "/site", "-c", "/etc/httpd.conf"]
