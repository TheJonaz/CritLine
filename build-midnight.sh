#!/usr/bin/env bash
# Builds the Midnight (retail) package from the same sources as CritLine Forever.
# Only the TOC metadata differs; the code already handles a closed combat log.
#   ./build-midnight.sh            -> dist/CritLine-Midnight-<version>.zip
#   ./build-midnight.sh --install  -> also copies the addons to the retail AddOns folder
set -euo pipefail

VERSION="v4.7.1-midnight1"
INTERFACE="120105"
RETAIL_ADDONS="$HOME/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns"

cd "$(dirname "$0")"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

cp -r Critline Critline_AuraMonitor "$stage"/
for toc in "$stage"/Critline/Critline.toc "$stage"/Critline_AuraMonitor/Critline_AuraMonitor.toc; do
	sed -i \
		-e "s/^## Interface: .*/## Interface: $INTERFACE/" \
		-e "s/^## Title: CritLine Forever/## Title: CritLine Midnight/" \
		-e "s/^## Version: .*/## Version: $VERSION/" \
		-e "s/^## X-Port: WoW: Forever port/## X-Port: Midnight port/" \
		"$toc"
done

mkdir -p dist
zip_path="dist/CritLine-Midnight-$VERSION.zip"
rm -f "$zip_path"
(cd "$stage" && zip -qr - Critline Critline_AuraMonitor) > "$zip_path"
echo "Built $zip_path"

if [[ "${1:-}" == "--install" ]]; then
	rm -rf "$RETAIL_ADDONS/Critline" "$RETAIL_ADDONS/Critline_AuraMonitor"
	cp -r "$stage"/Critline "$stage"/Critline_AuraMonitor "$RETAIL_ADDONS"/
	echo "Installed to $RETAIL_ADDONS"
fi
