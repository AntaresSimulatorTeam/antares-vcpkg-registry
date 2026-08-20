# antares-vcpkg-registry

This repository serves two independent purposes for Antares vcpkg builds.

1. **A vcpkg git registry** (`ports/`, `versions/`) supplying Antares-specific ports —
   `sirius-solver`, `or-tools-rte` and friends. Consumers reference it from
   `vcpkg-configuration.json` and pin it by **baseline SHA**, so pushing to `main`
   never changes what an existing branch resolves.
2. **A vcpkg asset mirror** — one release per vcpkg baseline, tagged
   `baseline-<sha>`, holding a content-addressed copy of every source archive that
   baseline's builds download, so that branches with a **frozen vcpkg baseline stay
   buildable after upstream mirrors purge old versions**.

The two do not interact: release assets are not git objects, so they add nothing to
the clone that vcpkg performs when resolving the registry.

The rest of this document covers the asset mirror.

## The asset mirror

The problem it solves: maintenance branches such as `release/9.3.x` pin an old
vcpkg baseline on purpose — bumping it would drag dependency upgrades and breaking
changes into a branch whose whole point is stability. But those pinned ports point at
upstream download URLs that rot. MSYS2 in particular deletes superseded packages
within months, so `vcpkg install` fails at the *download* step: the build is fine,
the bytes are just gone from the internet.

Each asset is named **exactly its SHA512** (128 lowercase hex characters, no
extension), which is the layout vcpkg's `x-azurl` asset-cache provider expects.

Assets are partitioned by **vcpkg baseline**, one release per baseline, tagged
`baseline-<sha>` — the same SHA that appears as `default-registry.baseline` in a
branch's `vcpkg-configuration.json` (or `builtin-baseline` in `vcpkg.json` on 8.8.x).
The baseline decides which port versions, and therefore which source URLs, a branch
resolves, so it is the natural key. Because a branch's baseline is frozen, its release
is a stable, self-contained set that can be dropped when the branch is retired without
affecting anything else.

The `baseline-` prefix is not decoration: a git ref whose name is bare SHA-1 hex is
ambiguous with the object id itself.

Archives shared between baselines are stored once per release. That duplication is the
price of each release being independently prunable, and it is small — there are only a
handful of live baselines.

Shared across Antares repositories — `Antares_Simulator`, `Antares_Xpansion`, and
anything else that builds with vcpkg.

### Using the mirror

The mirror is **public and read-only**, so no credentials are needed anywhere.

In CI, next to the existing `VCPKG_BINARY_SOURCES`:

```yaml
env:
  X_VCPKG_ASSET_SOURCES: "clear;x-azurl,${{ vars.VCPKG_ASSET_BASE_URL || 'https://github.com/AntaresSimulatorTeam/antares-vcpkg-registry/releases/download' }}/baseline-<this-branch's-baseline>/,,read"
```

The baseline is hardcoded per branch — correctly so, since a branch's baseline never
changes. Only the *base* URL comes from an org-level Actions variable, so the mirror
can later move (to Azure Blob, a SAS-protected container) **without re-touching every
frozen release branch** — which is the exact churn this mirror exists to avoid.

Locally:

```bash
export X_VCPKG_ASSET_SOURCES="clear;x-azurl,https://github.com/AntaresSimulatorTeam/antares-vcpkg-registry/releases/download/baseline-$(jq -r '.["default-registry"].baseline' vcpkg-configuration.json)/,,read"
```

Note the trailing `/` on the URL and the `,,read`: the empty field is the SAS token
(unused), and `read` is deliberate — GitHub releases answer GET but not PUT, so
writes go through the seeding workflow below.

**Do not add `x-block-origin` in CI.** Origin fallback is what lets still-alive URLs
keep working and lets seeding discover archives the mirror does not have yet. Use it
only when you want to *prove* a file came from the mirror.

### Adding assets

#### Normally: the seeding workflow

Run [`Seed asset mirror`](../../actions/workflows/seed.yml) with the consumer repo,
the ref, the runner OS and the triplet. It builds that ref with the asset cache
disabled so everything is fetched from origin, then mirrors whatever landed in
`vcpkg/downloads`.

Run it per (branch × OS) combination that CI builds, and re-run it after any baseline
bump on `develop`. **Prioritise Windows** — that is where `vcpkg_acquire_msys` pulls
the volatile MSYS2 packages, which are by far the most likely to disappear.

`download-only` mode is much faster but best-effort: some ports only resolve their
downloads during the build. If a Windows seed comes back without MSYS2 packages, re-run
in `full-install` mode.

Seeding can only capture what **still downloads today**. Archives already purged
upstream need the procedure below.

#### When the file is already gone upstream

This is the case that unblocks a broken maintenance branch. It works because vcpkg
verifies the SHA512 of every asset on every use, so **provenance does not matter** —
a file whose hash matches is by definition the right file.

1. Read the expected hash straight out of the failing CI log. vcpkg prints it next to
   the dead URL:

   ```
   error: failed to download from mirror set
   Expected hash: 9f2c...  (128 hex chars)
   ```

2. Find the file anywhere: a developer machine with a warm `vcpkg/downloads/`, an old
   Docker image, a still-warm CI cache, a third-party archive mirror.

3. Verify and upload:

   ```bash
   sha512sum thefile.tar.zst          # must match the expected hash exactly
   sha=$(sha512sum thefile.tar.zst | cut -d' ' -f1)
   cp thefile.tar.zst "$sha"
   gh release upload "baseline-<baseline-sha>" "$sha" \
       -R AntaresSimulatorTeam/antares-vcpkg-registry
   ```

   If the hash does not match, the file is the wrong one — do not upload it. vcpkg
   would reject it anyway.

#### Bulk upload from a local downloads directory

```bash
tools/upload-downloads.sh /path/to/vcpkg/downloads <baseline-sha>
tools/upload-downloads.sh /path/to/vcpkg/downloads <baseline-sha> --dry-run
```

It hashes every top-level file, skips what that baseline's release already has, and
uploads the rest, creating the release if it does not exist. A bare 40-hex baseline is
accepted and prefixed automatically. `ASSETS_REPO` overrides the target repo.

### Verifying the mirror actually serves a file

`x-block-origin` disables origin fallback, so a successful install proves the archive
came from here and not from a still-live upstream:

```bash
rm -f vcpkg/downloads/<the-file>
export X_VCPKG_ASSET_SOURCES="clear;x-azurl,https://github.com/AntaresSimulatorTeam/antares-vcpkg-registry/releases/download/baseline-<sha>/,,read;x-block-origin"
./vcpkg/vcpkg install --x-manifest-root=. --triplet x64-linux-release
```

### Why GitHub releases, and why this repository

Release assets are served over a 302 redirect to a signed blob URL, which vcpkg's
downloader follows. They are free, unlimited in count, public without auth, and need
no infrastructure to maintain. The only thing they cannot do is accept PUT, which is
why the mirror is read-only and writes go through `gh release upload`.

If the mirror ever outgrows this — or needs to be private — point the org variable
`VCPKG_ASSET_BASE_URL` at an Azure Blob container with a SAS token and `readwrite`,
and consumers pick it up with no branch changes.

The mirror lives here rather than in a repository of its own because this is already
the org's vcpkg infrastructure repo, it is already public, and release assets cost the
registry nothing — they are not git objects, so the clone vcpkg performs stays at a
few hundred kilobytes.

The one trade-off: GitHub has no releases-only permission, so anything that can seed
the mirror (`Contents: write`) can also rewrite `ports/` and `versions/`. This is
acceptable because consumers pin the registry by **baseline SHA** — a bad push to
`main` does not change what any existing branch resolves. Keep `seed.yml` the only
workflow here holding `contents: write`, and review changes to it accordingly.
