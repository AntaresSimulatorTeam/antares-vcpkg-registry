#!/usr/bin/env bash
# Hash every archive in a vcpkg downloads directory and upload the ones the
# mirror does not have yet, named by their SHA512.
#
# Assets are partitioned by vcpkg baseline: one release per baseline, tagged
# "baseline-<sha>". A branch's baseline is frozen, so its release is a stable,
# self-contained set that can be pruned when the branch is retired without
# affecting any other branch.
#
# Usage: tools/upload-downloads.sh <downloads-dir> <baseline-sha|tag> [--dry-run]
#
# Env:
#   ASSETS_REPO         override the mirror repository
#   MIRROR_RESULT_FILE  if set, write tag/new/skipped as shell assignments there
set -euo pipefail

DOWNLOADS=${1:?usage: $0 <vcpkg-downloads-dir> <baseline-sha|tag> [--dry-run]}
RAW_TAG=${2:?usage: $0 <vcpkg-downloads-dir> <baseline-sha|tag> [--dry-run]}
DRY_RUN=${3:-}
REPO=${ASSETS_REPO:-AntaresSimulatorTeam/antares-vcpkg-registry}

# Accept a bare 40-hex baseline or an already-prefixed tag. The "baseline-"
# prefix is not decoration: a ref whose name is bare SHA-1 hex is ambiguous
# with the object id itself, and git resolves such names unpredictably.
if [[ $RAW_TAG =~ ^[0-9a-f]{40}$ ]]; then
    TAG="baseline-$RAW_TAG"
else
    TAG=$RAW_TAG
fi

[ -d "$DOWNLOADS" ] || { echo "no such directory: $DOWNLOADS" >&2; exit 1; }

work=$(mktemp -d)
staging=$work/assets          # only files to be uploaded live here
mkdir -p "$staging"
trap 'rm -rf "$work"' EXIT

# What the mirror already holds for this baseline. A release can hold thousands
# of assets, so list once and match locally rather than probing per file.
echo "Mirror: $REPO ($TAG)"
existing=$work/existing.txt
if ! gh release view "$TAG" -R "$REPO" --json assets --jq '.assets[].name' > "$existing" 2>"$work/gh.err"; then
    if grep -qi "release not found" "$work/gh.err"; then
        if [ "$DRY_RUN" = "--dry-run" ]; then
            echo "  release $TAG does not exist yet (would be created)"
        else
            echo "  creating release $TAG"
            gh release create "$TAG" -R "$REPO" \
                --title "vcpkg baseline ${TAG#baseline-}" \
                --notes "SHA512-keyed source archives for vcpkg baseline \`${TAG#baseline-}\`.

Consume with:

    X_VCPKG_ASSET_SOURCES=\"clear;x-azurl,https://github.com/$REPO/releases/download/$TAG/,,read\"

Do not delete assets from this release while any branch still pins this baseline."
        fi
        : > "$existing"
    else
        # Not authenticated, network, etc. Mistaking this for "empty" would
        # silently re-upload the whole set on every glitch.
        echo "cannot read $REPO release $TAG:" >&2
        cat "$work/gh.err" >&2
        exit 1
    fi
fi
echo "  $(wc -l < "$existing") already mirrored"

new=0
skipped=0
# Only top-level files: tools/ holds extracted toolchains, not downloaded assets.
while IFS= read -r -d '' f; do
    case "$f" in
        *.part|*.partial|*.clean|*.lock) continue ;;
    esac
    sha=$(sha512sum "$f" | cut -d' ' -f1)
    if grep -qxF "$sha" "$existing"; then
        skipped=$((skipped + 1))
        continue
    fi
    echo "  + $(basename "$f") -> $sha"
    cp "$f" "$staging/$sha"
    new=$((new + 1))
done < <(find "$DOWNLOADS" -maxdepth 1 -type f -print0)

echo "$new new asset(s), $skipped already mirrored"

# Machine-readable counts for a caller that wants to report them (refresh.yml
# renders these into the run summary). Written before the early exit below so
# a no-op run still reports.
if [ -n "${MIRROR_RESULT_FILE:-}" ]; then
    { echo "tag=$TAG"; echo "new=$new"; echo "skipped=$skipped"; } > "$MIRROR_RESULT_FILE"
fi

[ "$new" -eq 0 ] && exit 0

if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "dry run: not uploading"
    exit 0
fi

# --clobber so a re-run after a partial upload is safe. Batched because gh
# accepts many files per invocation but not an unbounded argv.
find "$staging" -maxdepth 1 -type f -print0 \
    | xargs -0 -n 50 gh release upload "$TAG" -R "$REPO" --clobber
echo "uploaded $new asset(s) to $REPO ($TAG)"
