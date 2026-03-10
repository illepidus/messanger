#!/usr/bin/env bash

set -e

for file in $(git ls-files "*.excalidraw"); do
  out="${file%.excalidraw}.jpeg"

  npx @excalidraw/excalidraw export \
    --input "$file" \
    --output "$out" \
    --type jpeg

  echo "Rendered $file -> $out"
done