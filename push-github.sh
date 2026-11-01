#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
token_file="$script_dir/secret-github.txt"

if [[ ! -f "$token_file" ]]; then
  printf 'PAT file not found: %s\n' "$token_file" >&2
  exit 1
fi

askpass="$(mktemp)"
chmod 700 "$askpass"
trap 'rm -f "$askpass"' EXIT

cat > "$askpass" <<'ASKPASS_EOF'
#!/bin/sh
case "$1" in
  *Username*) printf '%s\n' 'afrahrifka' ;;
  *) cat "$PAT_FILE" ;;
esac
ASKPASS_EOF
chmod 700 "$askpass"

cd "$script_dir"
env PAT_FILE="$token_file" \
  GIT_ASKPASS="$askpass" \
  GIT_TERMINAL_PROMPT=0 \
  git -c credential.helper= -c core.askPass="$askpass" push origin main
