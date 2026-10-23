#!/usr/bin/env bash
# build.sh [OUT]: the site as a reproducible zip, OUT/ccs-front-hugo.zip (default dist/): check
# the pinned StageX images' signatures, make StageX's BuildKit a builder (builder.Dockerfile), and
# build in it with no network (Dockerfile). Prints its sha256: the same commit gives the same one
# anywhere. Needs Docker with buildx, git, gpg, jq.
set -euo pipefail
here=$(dirname "$(readlink -f "$0")")
repo=$(git -C "$here" rev-parse --show-toplevel)
out=$(readlink -f "${1:-$repo/dist}")

"$here/verify-images.sh" > /dev/null
contexts=()
while read -r name ref; do
    docker pull -q "$ref" > /dev/null
    contexts+=(--build-context "$name=docker-image://$ref")
done < <(grep -v '^#' "$here/images")
# the commit's time, and only what git has (a clean copy: no stray local files in the zip)
src=$(mktemp -d)
trap 'rm -rf "$src"' EXIT
git -C "$repo" archive HEAD | tar -x -C "$src"

# Only copies, so the host's BuildKit makes it; named by its ID, so new pins get a new builder.
docker buildx build -q --builder default --network none --pull=false "${contexts[@]}" \
    --build-arg SOURCE_DATE_EPOCH=0 --output type=docker,name=ccs-front-hugo-builder,rewrite-timestamp=true \
    -f "$here/builder.Dockerfile" "$here" > /dev/null
builder_id=$(docker image inspect ccs-front-hugo-builder --format '{{.Id}}')
builder=ccs-front-hugo-builder-${builder_id:7:12}
docker tag ccs-front-hugo-builder "$builder"
docker buildx inspect "$builder" > /dev/null 2>&1 \
    || docker buildx create --name "$builder" --driver docker-container --driver-opt image="$builder" > /dev/null

# Hugo and zip run in StageX's BuildKit, not the host's
docker buildx build -q --builder "$builder" --network none "${contexts[@]}" \
    --build-arg SOURCE_DATE_EPOCH="$(git -C "$repo" log -1 --format=%ct)" \
    --output "type=local,dest=$out" -f "$here/Dockerfile" "$src" > /dev/null
sha256sum "$out/ccs-front-hugo.zip"
