#!/usr/bin/env bash
set -euo pipefail

PDF_SRC="reports/generated/paper.pdf"
ARCHIVE_DIR="reports/generated/archive"

# Includes seconds to guarantee uniqueness across rapid rebuilds.
STAMP=$(date +%d%b%Y-%H%M%S)
STAMPED_NAME="paper-${STAMP}.pdf"

if [ ! -f "$PDF_SRC" ]; then
    echo "Error: Source PDF not found at $PDF_SRC. Run 'make paper-all' first." >&2
    exit 1
fi

mkdir -p "$ARCHIVE_DIR"

cp "$PDF_SRC" "reports/generated/${STAMPED_NAME}"
cp "$PDF_SRC" "${ARCHIVE_DIR}/${STAMPED_NAME}"

echo "[archive] Timestamped copy created:"
echo "  -> reports/generated/${STAMPED_NAME}"
echo "  -> ${ARCHIVE_DIR}/${STAMPED_NAME}"
