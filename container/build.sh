#!/usr/bin/env bash
# build.sh [OUT]: build the site as a reproducible zip, OUT/ccs-front-hugo.zip (default dist/).
# Checks the pinned StageX images' signatures, sets up StageX's BuildKit,
# and builds with no network. Prints the zip's sha256, the same for a commit anywhere.
# Needs Docker with buildx, git, gpg and jq.
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
# The commit's time, and only what git has, so no stray local files get in.
src=$(mktemp -d)
trap 'rm -rf "$src"' EXIT
git -C "$repo" archive HEAD | tar -x -C "$src"

# Only copies, so the host's BuildKit can make it.
# Named by its ID, so the three repositories share one builder and one cache.
docker buildx build -q --builder default --network none --pull=false "${contexts[@]}" \
    --build-arg SOURCE_DATE_EPOCH=0 --output type=docker,name=stagex-buildkit,rewrite-timestamp=true \
    -f "$here/builder.Dockerfile" "$here" > /dev/null
builder_id=$(docker image inspect stagex-buildkit --format '{{.Id}}')
builder=stagex-buildkit-${builder_id:7:12}
docker tag stagex-buildkit "$builder"
docker buildx inspect "$builder" > /dev/null 2>&1 \
    || docker buildx create --name "$builder" --driver docker-container --driver-opt image="$builder" > /dev/null

# Hugo and zip run in StageX's BuildKit, not the host's.
docker buildx build -q --builder "$builder" --network none "${contexts[@]}" \
    --build-arg SOURCE_DATE_EPOCH="$(git -C "$repo" log -1 --format=%ct)" \
    --output "type=local,dest=$out" -f "$here/Dockerfile" "$src" > /dev/null
sha256sum "$out/ccs-front-hugo.zip"
