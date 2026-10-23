# The site as a reproducible zip: StageX's Hugo, busybox and zip (container/images, signatures
# checked by build.sh), no network. The same commit gives the same zip, byte for byte, anywhere:
# every file gets the commit's time and fixed permissions, the zip lists them in one order and
# keeps nothing of the machine (no uid/gid or extra timestamps, -X; no folder entries, -D).
FROM scratch AS build
COPY --from=busybox / /
COPY --from=musl / /
COPY --from=hugo / /
COPY --from=zip / /
ARG SOURCE_DATE_EPOCH
RUN --mount=type=bind,source=.,target=/src \
    mkdir -p /tmp/hugo-cache /out \
    && cd /src && hugo build --quiet --noBuildLock --cacheDir /tmp/hugo-cache --destination /out/site \
    && cd /out/site \
    && find . -type d -exec chmod 755 {} + && find . -type f -exec chmod 644 {} + \
    && find . -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} + \
    && find . -type f | sed 's|^\./||' | LC_ALL=C sort | TZ=UTC zip -q -X -D /out/ccs-front-hugo.zip -@

FROM scratch
COPY --from=build /out/ccs-front-hugo.zip /
