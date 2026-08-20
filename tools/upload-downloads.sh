#!/usr/bin/env bash
# Hash every archive in a vcpkg downloads directory and upload the ones the
# mirror does not have yet, named by their SHA512.
#
# Usage: tools/upload-downloads.sh <downloads-dir> [--dry-run]
set -euo pipefail

DOWNLOADS=${1:?usage: $0 <vcpkg-downloads-dir> [--dry-run]}
DRY_RUN=${2:-}
REPO=${ASSETS_REPO:-AntaresSimulatorTeam/antares-vcpkg-registry}
TAG=${ASSETS_TAG:-assets}

[ -d "$DOWNLOADS" ] || { echo "no such directory: $DOWNLOADS" >&2; exit 1; }

work=$(mktemp -d)
staging=$work/assets          # only files to be uploaded live here
mkdir -p "$staging"
trap 'rm -rf "$work"' EXIT

# What the mirror already holds. A release can hold many thousands of assets,
# so list once and match locally rather than probing per file.
echo "Listing existing assets in $REPO ($TAG)..."
existing=$work/existing.txt
if ! gh release view "$TAG" -R "$REPO" --json assets --jq '.assets[].name' > "$existing" 2>"$work/gh.err"; then
    # A missing release means an empty mirror, which is fine on first run.
    # Anything else (not authenticated, network) must not be mistaken for
    # "empty", or every auth glitch silently re-uploads the whole set.
    # Note gh also says "release not found" when the repo itself is missing;
    # the upload below fails loudly in that case.
    if grep -qi "release not found" "$work/gh.err"; then
        : > "$existing"
    else
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
