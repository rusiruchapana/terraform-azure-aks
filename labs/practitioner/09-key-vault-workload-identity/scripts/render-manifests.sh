#!/usr/bin/env bash
set -euo pipefail

: "${AZURE_CLIENT_ID:?Set AZURE_CLIENT_ID}"
: "${AZURE_TENANT_ID:?Set AZURE_TENANT_ID}"
: "${KEYVAULT_NAME:?Set KEYVAULT_NAME}"

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$LAB_DIR/rendered"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

for file in "$LAB_DIR"/manifests/*.yaml; do
  out="$OUT_DIR/$(basename "$file")"
  sed \
    -e "s|AZURE_CLIENT_ID_PLACEHOLDER|$AZURE_CLIENT_ID|g" \
    -e "s|AZURE_TENANT_ID_PLACEHOLDER|$AZURE_TENANT_ID|g" \
    -e "s|KEYVAULT_NAME_PLACEHOLDER|$KEYVAULT_NAME|g" \
    "$file" > "$out"
done

echo "Rendered manifests written to:"
echo "$OUT_DIR"
