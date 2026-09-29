#!/usr/bin/env bash
# Build the source archives that accompany one SynapShare release.
#
#   scripts/make_source_release.sh <synapshare-version> [extra-deskflow-commit ...]
#
# Always archives the Deskflow and libportal revisions pinned in flatpak/
# (what the Linux Flatpak builds, before patches). Pass any other Deskflow
# commit that a Windows or macOS package of this release bundles as an
# official binary (its vendor/deskflow/<platform>/deskflow-manifest.json
# records it) so that source is archived too.
#
# Output: dist/<synapshare-version>/ - upload every file to the GitHub
# release tagged synapshare-v<synapshare-version>.
set -euo pipefail

if [ $# -lt 1 ]; then
  sed -n '2,13p' "$0" >&2
  exit 2
fi

VERSION="$1"
shift
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/dist/$VERSION"
WORK_DIR="$ROOT_DIR/build/src"

yaml_value() {
  # yaml_value <file> <key>: first "key: value" in a flatpak module file.
  sed -n "s/^[[:space:]]*$2:[[:space:]]*\\([^[:space:]#]*\\).*/\\1/p" "$1" | head -n 1
}

archive() {
  # archive <name> <git-url> <commit>
  local name="$1" url="$2" commit="$3"
  local clone="$WORK_DIR/$name.git"
  if [ ! -d "$clone" ]; then
    git clone --bare --filter=blob:none "$url" "$clone"
  fi
  git -C "$clone" fetch --quiet origin "$commit"
  local short="${commit:0:12}"
  local file="$OUT_DIR/$name-$short-src.tar.gz"
  git -C "$clone" archive --format=tar.gz --prefix="$name-$short/" -o "$file" "$commit"
  echo "Created $file"
}

mkdir -p "$OUT_DIR" "$WORK_DIR"

DESKFLOW_URL="$(yaml_value "$ROOT_DIR/flatpak/deskflow-core.yml" url)"
DESKFLOW_COMMIT="$(yaml_value "$ROOT_DIR/flatpak/deskflow-core.yml" commit)"
LIBPORTAL_URL="$(yaml_value "$ROOT_DIR/flatpak/libportal.yml" url)"
LIBPORTAL_COMMIT="$(yaml_value "$ROOT_DIR/flatpak/libportal.yml" commit)"

archive deskflow "$DESKFLOW_URL" "$DESKFLOW_COMMIT"
for extra in "$@"; do
  if [ "$extra" != "$DESKFLOW_COMMIT" ]; then
    archive deskflow "$DESKFLOW_URL" "$extra"
  fi
done
archive libportal "$LIBPORTAL_URL" "$LIBPORTAL_COMMIT"

# The patches and build definitions this release applies, as one archive.
git -C "$ROOT_DIR" archive --format=tar.gz --prefix="synapshare-oss-$VERSION/" \
  -o "$OUT_DIR/synapshare-oss-$VERSION.tar.gz" HEAD
echo "Created $OUT_DIR/synapshare-oss-$VERSION.tar.gz"

(cd "$OUT_DIR" && sha256sum -- *.tar.gz > SHA256SUMS)
echo "Created $OUT_DIR/SHA256SUMS"
