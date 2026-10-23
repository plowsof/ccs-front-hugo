#!/usr/bin/env bash
# build.sh [OUT]: the site as a reproducible zip, OUT/ccs-front-hugo.zip (default dist/): check
# the pinned StageX images' signatures, then build with no network (Dockerfile). Prints its sha256:
# the same commit gives the same one anywhere. Needs Docker with buildx, git, gpg, jq.
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
docker buildx build -q --network none --pull=false "${contexts[@]}" \
    --build-arg SOURCE_DATE_EPOCH="$(git -C "$repo" log -1 --format=%ct)" \
    --output "type=local,dest=$out" -f "$here/Dockerfile" "$src" > /dev/null
sha256sum "$out/ccs-front-hugo.zip"
