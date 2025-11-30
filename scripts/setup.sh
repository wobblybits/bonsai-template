#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_TOKEN="bonsai_template"
PATCH_FILE="$ROOT_DIR/patches/ocamlformat-0.28.1-base_018.patch"
OCAMLFORMAT_VERSION="0.28.1"

usage() {
  cat <<'USAGE'
Usage: scripts/setup.sh [--no-switch] <new_project_name>

Replaces occurrences of the default template name ("bonsai_template") with the
provided project name across all source files. By default, this script also
creates an opam switch with the same name and installs project dependencies.

Example:
  scripts/setup.sh awesome_app

Options:
  --no-switch   Skip opam switch import/creation. You can handle it manually
                later by following INSTALL.md.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

CREATE_SWITCH=1

ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-switch)
      CREATE_SWITCH=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ $# -gt 0 ]]; then
  ARGS+=("$@")
fi

if [[ ${#ARGS[@]} -ne 1 ]]; then
  usage
  exit 1
fi

PROJECT_NAME="${ARGS[0]}"

if [[ ! "$PROJECT_NAME" =~ ^[a-z0-9_]+$ ]]; then
  echo "Error: project name must be lowercase with digits or underscores (^[a-z0-9_]+$)." >&2
  exit 1
fi

if [[ "$PROJECT_NAME" == "$TEMPLATE_TOKEN" ]]; then
  echo "Error: project name must be different from the template token \"$TEMPLATE_TOKEN\"." >&2
  exit 1
fi

if ! command -v perl >/dev/null 2>&1; then
  echo "Error: perl is required for in-place editing. Please install perl and retry." >&2
  exit 1
fi

mapfile -t FILES < <(
  cd "$ROOT_DIR"
  grep -R --files-with-matches --exclude-dir=_build --exclude-dir=.git \
    --exclude-dir=.opam --exclude="*.export" --exclude="*.log" \
    --exclude="scripts/setup.sh" "$TEMPLATE_TOKEN" .
)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No files still contain the template token \"$TEMPLATE_TOKEN\". Nothing to do."
  exit 0
fi

for file in "${FILES[@]}"; do
  perl -0pi -e "s/${TEMPLATE_TOKEN}/${PROJECT_NAME}/g" "$ROOT_DIR/$file"
done

# Rename opam file to match the new project name
ORIGINAL_OPAM="$ROOT_DIR/bonsai_template.opam"
TARGET_OPAM="$ROOT_DIR/${PROJECT_NAME}.opam"
OPAM_FILE=""
if [[ -f "$ORIGINAL_OPAM" ]]; then
  if [[ -f "$TARGET_OPAM" && "$TARGET_OPAM" != "$ORIGINAL_OPAM" ]]; then
    echo "Warning: ${TARGET_OPAM} already exists. Leaving both opam files in place." >&2
    OPAM_FILE="${PROJECT_NAME}.opam"
  else
    mv "$ORIGINAL_OPAM" "$TARGET_OPAM"
    OPAM_FILE="${PROJECT_NAME}.opam"
  fi
elif [[ -f "$TARGET_OPAM" ]]; then
  OPAM_FILE="${PROJECT_NAME}.opam"
else
  echo "Warning: no opam file found. Dependency installation will be skipped." >&2
fi

patch_and_pin() {
  local package=$1
  local switch=$2
  local tmp_dir

  if [[ ! -f "$PATCH_FILE" ]]; then
    echo "Warning: patch file $PATCH_FILE not found; skipping pin for $package." >&2
    return 1
  fi

  tmp_root=$(mktemp -d)
  tmp_dir="$tmp_root/${package}"
  if ! opam source "${package}.${OCAMLFORMAT_VERSION}" --dir="$tmp_dir" >/dev/null 2>&1; then
    echo "Warning: failed to fetch sources for ${package}.${OCAMLFORMAT_VERSION}." >&2
    rm -rf "$tmp_root"
    return 1
  fi
  if ! patch -d "$tmp_dir" -p1 < "$PATCH_FILE" >/dev/null; then
    echo "Warning: failed to apply ocamlformat patch to $package." >&2
    rm -rf "$tmp_root"
    return 1
  fi
  if ! (cd "$tmp_dir" && opam pin add --switch "$switch" --yes "$package" . >/dev/null 2>&1); then
    echo "Warning: opam pin failed for $package." >&2
    rm -rf "$tmp_root"
    return 1
  fi
  rm -rf "$tmp_root"
  return 0
}

SWITCH_CREATED=0
SWITCH_MSG=""

if [[ "$CREATE_SWITCH" -eq 1 ]]; then
  if ! command -v opam >/dev/null 2>&1; then
    SWITCH_MSG="Warning: opam not found in PATH; skipped switch setup."
  else
    if opam switch list --short | grep -Fxq "$PROJECT_NAME"; then
      SWITCH_MSG="An opam switch named \"$PROJECT_NAME\" already exists; skipped creation."
    else
      if opam switch create "$PROJECT_NAME" 5.2.0 --yes; then
        eval "$(opam env --switch "$PROJECT_NAME" --set-switch)"
        if ! opam repo list --short | grep -Fxq "janestreet"; then
          opam repo add janestreet https://github.com/janestreet/opam-repository.git --yes
        fi
        if patch_and_pin ocamlformat-lib "$PROJECT_NAME" \
          && patch_and_pin ocamlformat "$PROJECT_NAME" \
          && [[ -n "$OPAM_FILE" ]] \
          && opam install --switch "$PROJECT_NAME" --yes "$OPAM_FILE" --deps-only; then
          SWITCH_CREATED=1
          SWITCH_MSG="Created opam switch \"$PROJECT_NAME\" and installed template dependencies."
        else
          SWITCH_MSG="Warning: switch \"$PROJECT_NAME\" was created but dependency installation failed. Consult INSTALL.md."
        fi
      else
        SWITCH_MSG="Warning: failed to create opam switch \"$PROJECT_NAME\". Consult INSTALL.md."
      fi
    fi
  fi
else
  SWITCH_MSG="Skipped opam switch creation (requested via --no-switch)."
fi

if [[ "$CREATE_SWITCH" -eq 1 && "$SWITCH_CREATED" -eq 1 ]]; then
  NEXT_STEP="Load the opam environment:
     eval \"\$(opam env --switch ${PROJECT_NAME})\""
else
  NEXT_STEP="Follow INSTALL.md to configure or activate your opam switch."
fi

cat <<EOF
Updated template name to "${PROJECT_NAME}".
${SWITCH_MSG}

Next steps:
  1. Rename the project directory if desired.
  2. ${NEXT_STEP}
  3. Run dune build to ensure everything compiles.
EOF

