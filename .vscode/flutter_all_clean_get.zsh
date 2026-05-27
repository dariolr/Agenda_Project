#!/usr/bin/env zsh
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
parent_dir="$(cd -- "$script_dir/.." && pwd)"
workspace_file=""

for ws in "$parent_dir"/*.code-workspace; do
  if [[ -f "$ws" ]]; then
    workspace_file="$ws"
    break
  fi
done

if [[ -z "$workspace_file" ]]; then
  echo "No .code-workspace file found in $parent_dir" >&2
  exit 1
fi

dirs_output="$(python3 - <<'PY' "$workspace_file" "$parent_dir" "$script_dir"
import json
import os
import re
import sys

workspace_file = sys.argv[1]
parent_dir = sys.argv[2]
script_dir = sys.argv[3]


def load_workspace_json(path):
    with open(path, "r", encoding="utf-8") as f:
        raw = f.read()

    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        # VS Code workspace files often include trailing commas.
        sanitized = re.sub(r",\s*([}\]])", r"\1", raw)
        return json.loads(sanitized)


try:
    data = load_workspace_json(workspace_file)
except json.JSONDecodeError as e:
    print(f"Invalid workspace JSON: {workspace_file}: {e}", file=sys.stderr)
    sys.exit(1)

folders = data.get("folders", [])
for item in folders:
    path = item.get("path")
    if not path:
        continue
    abs_path = os.path.abspath(os.path.join(parent_dir, path))
    if abs_path == script_dir:
        continue
    pubspec = os.path.join(abs_path, "pubspec.yaml")
    if os.path.isfile(pubspec):
        print(abs_path)
PY
)"

if [[ -z "${dirs_output//[[:space:]]/}" ]]; then
  echo "No Flutter projects with pubspec.yaml found in workspace: $workspace_file" >&2
  exit 1
fi

for dir in "${(@f)dirs_output}"; do
  echo "==> $dir"
  (cd "$dir" && flutter clean && flutter pub get)
done
