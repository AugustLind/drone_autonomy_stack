#!/usr/bin/env bash
#
set -euo pipefail

CLANG_FORMAT="${CLANG_FORMAT:-clang-format}"
FALLBACK_STYLE="Google"
CHECK=0
WORKSPACE=""
JOBS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"
TARGETS=()

usage() { sed -n '3,19p' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--check)     CHECK=1; shift ;;
    -w|--workspace) WORKSPACE="$2"; shift 2 ;;
    -b|--binary)    CLANG_FORMAT="$2"; shift 2 ;;
    -j|--jobs)      JOBS="$2"; shift 2 ;;
    -h|--help)      usage; exit 0 ;;
    --)             shift; TARGETS+=("$@"); break ;;
    -*)             echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *)              TARGETS+=("$1"); shift ;;
  esac
done

if ! command -v "$CLANG_FORMAT" >/dev/null 2>&1; then
  echo "error: '$CLANG_FORMAT' not found. Install it (e.g. sudo apt install clang-format) or pass --binary." >&2
  exit 2
fi

# Find the workspace root: walk up until we find a directory that has src/
# but is not itself a package (packages also often have a src/ folder).
find_workspace() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/src" && ! -f "$dir/package.xml" ]]; then
      echo "$dir"; return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

if [[ -z "$WORKSPACE" ]]; then
  WORKSPACE="$(find_workspace)" || {
    echo "error: couldn't find a ROS 2 workspace (a folder with src/). Use --workspace." >&2
    exit 2
  }
fi
WORKSPACE="$(cd "$WORKSPACE" && pwd)"
SRC="$WORKSPACE/src"
[[ -d "$SRC" ]] || { echo "error: $SRC does not exist" >&2; exit 2; }

# Resolve targets: a package name, a path relative to src/, or an absolute path.
SEARCH=()
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  SEARCH=("$SRC")
else
  for t in "${TARGETS[@]}"; do
    if [[ -e "$t" ]]; then
      p="$(cd "$(dirname "$t")" && pwd)/$(basename "$t")"
    elif [[ -e "$SRC/$t" ]]; then
      p="$SRC/$t"
    else
      # Look it up as a package name
      p="$(grep -rl --include=package.xml "<name>$t</name>" "$SRC" 2>/dev/null | head -n1 | xargs -r dirname)"
      [[ -n "$p" ]] || { echo "error: '$t' is not a path or package under $SRC" >&2; exit 2; }
    fi
    case "$p" in
      "$SRC"|"$SRC"/*) SEARCH+=("$p") ;;
      *) echo "error: '$t' is outside $SRC" >&2; exit 2 ;;
    esac
  done
fi

# Directories of packages marked to be ignored by colcon/ament
mapfile -t IGNORED < <(find "$SRC" \( -name COLCON_IGNORE -o -name AMENT_IGNORE \) -printf '%h\n' 2>/dev/null)

is_ignored() {
  local f="$1" d
  for d in "${IGNORED[@]}"; do
    [[ "$f" == "$d"/* ]] && return 0
  done
  return 1
}

mapfile -t FILES < <(
  find "${SEARCH[@]}" \
    \( -name .git -o -name build -o -name install -o -name log \) -prune -o \
    -type f -regextype posix-extended \
    -iregex '.*\.(c|cc|cpp|cxx|h|hh|hpp|hxx|inc|ipp)$' -print |
  sort -u |
  while read -r f; do is_ignored "$f" || echo "$f"; done
)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No C/C++ files found under ${SEARCH[*]}."
  exit 0
fi

echo "Workspace: $WORKSPACE"
echo "Using $("$CLANG_FORMAT" --version | head -n1)"

STYLE_ARGS=(-style=file "--fallback-style=$FALLBACK_STYLE")

if [[ $CHECK -eq 1 ]]; then
  echo "Checking ${#FILES[@]} file(s)..."
  if printf '%s\0' "${FILES[@]}" | xargs -0 -n 50 -P "$JOBS" \
       "$CLANG_FORMAT" "${STYLE_ARGS[@]}" --dry-run --Werror; then
    echo "All files are correctly formatted."
  else
    echo "Some files need formatting. Run: $0 ${TARGETS[*]:-}" >&2
    exit 1
  fi
else
  echo "Formatting ${#FILES[@]} file(s)..."
  printf '%s\0' "${FILES[@]}" | xargs -0 -n 50 -P "$JOBS" \
    "$CLANG_FORMAT" "${STYLE_ARGS[@]}" -i
  echo "Done."
fi
