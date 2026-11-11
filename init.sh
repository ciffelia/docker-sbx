#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: init.sh [--local] [PROJECT_DIR]

Create sbxenv.yaml and .sbx-local in PROJECT_DIR (default: current directory).
Existing files are preserved.

  --local  Exclude sbxenv.yaml and .sbx-local via Git's info/exclude.
  -h, --help  Show this help.
EOF
}

local_only=false
project_arg=
while (($#)); do
  case "$1" in
    --local) local_only=true ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
    *)
      if [[ -n "$project_arg" ]]; then usage >&2; exit 1; fi
      project_arg=$1
      ;;
  esac
  shift
done
if (($#)); then
  if (($# != 1)) || [[ -n "$project_arg" ]]; then usage >&2; exit 1; fi
  project_arg=$1
fi

project_dir=$(cd -- "${project_arg:-.}" && pwd -P)
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
kit_dir=$script_dir/my-kit
[[ -d "$kit_dir" ]] || { printf 'Kit directory not found: %s\n' "$kit_dir" >&2; exit 1; }

if "$local_only"; then
  if [[ $(git -C "$project_dir" rev-parse --is-inside-work-tree 2>/dev/null) != true ]]; then
    printf -- '--local requires a Git working tree.\n' >&2
    exit 1
  fi
  exclude_file=$(git -C "$project_dir" rev-parse --path-format=absolute --git-path info/exclude)
  repo_root=$(git -C "$project_dir" rev-parse --show-toplevel)
  if [[ "$project_dir" != "$(cd -- "$repo_root" && pwd -P)" ]]; then
    printf -- '--local requires PROJECT_DIR to be the Git working tree root.\n' >&2
    exit 1
  fi
fi

# Single-quoted YAML strings escape apostrophes by doubling them.
yaml_quote() {
  local value=${1//\'/\'\'}
  printf "'%s'" "$value"
}

if [[ ! -e "$project_dir/sbxenv.yaml" && ! -L "$project_dir/sbxenv.yaml" ]]; then
  {
    cat <<'EOF'
schemaVersion: "1"
agent: shell
workspace: .

kits:
  - docker.io/sbx/github-ssh:latest
EOF
    printf '  - %s\n' "$(yaml_quote "$kit_dir")"
    cat <<'EOF'

additionalWorkspaces:
  - path: ./.sbx-local/.codex
    target: /home/agent/.codex
EOF
  } > "$project_dir/sbxenv.yaml"
  printf 'Created %s/sbxenv.yaml\n' "$project_dir"
else
  printf 'Keeping existing %s/sbxenv.yaml\n' "$project_dir"
fi

mkdir -p -- "$project_dir/.sbx-local"
if [[ ! -e "$project_dir/.sbx-local/.gitignore" && ! -L "$project_dir/.sbx-local/.gitignore" ]]; then
  printf '%s\n' '*' '!/.gitignore' > "$project_dir/.sbx-local/.gitignore"
fi

if "$local_only"; then
  mkdir -p -- "$(dirname -- "$exclude_file")"
  touch -- "$exclude_file"
  for pattern in /sbxenv.yaml /.sbx-local; do
    if ! grep -Fxq -- "$pattern" "$exclude_file"; then
      printf '\n%s\n' "$pattern" >> "$exclude_file"
    fi
  done
  printf 'Added local exclusions to %s\n' "$exclude_file"
fi
