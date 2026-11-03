#!/usr/bin/env bash
# Local test build only; releases are built by BigWigs Packager on GitHub (see .pkgmeta).
#   ./build.sh          -> dist/Critline-<version>.zip (Era, Forever and Midnight TOC files)
#   ./build.sh install  -> also copies both addons to the game folders below
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
DIST="$ROOT/dist"
WOW="$HOME/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft"
GAME_FOLDERS=(_classic_era_ _forever_ _retail_)
ADDONS=(Critline Critline_AuraMonitor)

# VERSION=v4.7.2 ./build.sh builds a release zip before the tag exists (e.g. for a manual first upload)
VERSION="${VERSION:-$(git -C "$ROOT" describe --tags --always 2>/dev/null || echo dev)}"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

for addon in "${ADDONS[@]}"; do
	cp -r "$ROOT/$addon" "$stage/"
	sed -i "s/@project-version@/$VERSION/" "$stage/$addon"/*.toc
done
# the changelog lives at the repo root (the packager reads it from the package folder)
cp "$ROOT/CHANGELOG.md" "$stage/Critline/"

mkdir -p "$DIST"
zip_path="$DIST/Critline-$VERSION.zip"
rm -f "$zip_path"
(cd "$stage" && zip -qr - "${ADDONS[@]}") > "$zip_path"
echo "Built $zip_path"

if [[ ${1:-} == install ]]; then
	for folder in "${GAME_FOLDERS[@]}"; do
		dest="$WOW/$folder/Interface/AddOns"
		if [[ -d $dest ]]; then
			for addon in "${ADDONS[@]}"; do
				rm -rf "${dest:?}/$addon"
				cp -r "$stage/$addon" "$dest/"
			done
			echo "  installed to $folder"
		else
			echo "  skipped $folder: $dest not found"
		fi
	done
fi
