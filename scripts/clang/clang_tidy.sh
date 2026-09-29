#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

SRC="$(pwd)/src"

for db in build/*/compile_commands.json; do
  [[ -f "$db" ]] || { echo "No compile_commands.json in build/. Build with -DCMAKE_EXPORT_COMPILE_COMMANDS=ON" >&2; exit 1; }

  # Source files from this package's compile database that live in src/
  mapfile -t files < <(python3 -c '
import json, os, sys
for e in json.load(open(sys.argv[1])):
    f = os.path.realpath(os.path.join(e["directory"], e["file"]))
    if f.startswith(sys.argv[2] + "/"):
        print(f)
' "$db" "$SRC" | sort -u)

  [[ ${#files[@]} -gt 0 ]] || continue
  clang-tidy -p "$(dirname "$db")" --quiet --header-filter="^$SRC/" "${files[@]}"
done
