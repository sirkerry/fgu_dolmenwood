#!/usr/bin/env bash
set -e

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$REPO/dist"
FGDATA="$HOME/.smiteworks/fgdata/extensions"

mkdir -p "$DIST"
rm -f "$DIST"/*.ext "$DIST"/*.mod

if [ -d "$REPO/extensions" ]; then
    for dir in "$REPO/extensions"/*/; do
        [ -d "$dir" ] || continue
        name=$(basename "$dir")
        echo "  $name.ext"
        (cd "$dir" && zip -rq "$DIST/$name.ext" . \
            --exclude "README.md" --exclude "*.zip" --exclude "*.ext" --exclude "*.mod")
    done
fi

echo ""
ls -lh "$DIST"

echo ""
echo "Deploying to $FGDATA ..."
cp "$DIST"/*.ext "$FGDATA/"
echo "Done."
