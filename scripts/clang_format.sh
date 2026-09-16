#!/usr/bin/env bash
set -euo pipefail

find src -type f -regextype posix-extended -iregex '.*\.(c|cc|cpp|cxx|h|hh|hpp|hxx)$' -print0 |
  xargs -0 -r clang-format -i -style=file --fallback-style=Google
