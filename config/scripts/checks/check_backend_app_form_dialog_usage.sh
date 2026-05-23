#!/usr/bin/env bash
set -euo pipefail

# Detects responsive-form anti-patterns in agenda_backend.
# `showDialog(... AppFormDialog ...)` is allowed only in desktop-only branches.

search_root="${1:-lib}"

if [[ ! -d "$search_root" ]]; then
  echo "Usage: $0 [path-to-agenda_backend-lib]" >&2
  echo "Run from agenda_backend, or pass the lib directory explicitly." >&2
  exit 2
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "rg is required for this check." >&2
  exit 2
fi

violations=0

while IFS=: read -r file line _; do
  [[ -n "$file" && -n "$line" ]] || continue

  block="$(sed -n "${line},$((line + 25))p" "$file")"
  if ! grep -q "AppFormDialog" <<<"$block"; then
    continue
  fi

  context_start=$((line - 80))
  if (( context_start < 1 )); then
    context_start=1
  fi
  context="$(sed -n "${context_start},${line}p" "$file")"
  previous_lines="$(sed -n "$((line - 8)),$((line - 1))p" "$file" 2>/dev/null || true)"

  desktop_guard=false
  if grep -Eq "AppFormFactor\.desktop|isDesktop|useBottomSheet" <<<"$context"; then
    if grep -Eq "else|AppFormFactor\.desktop|isDesktop" <<<"$previous_lines"; then
      desktop_guard=true
    fi
  fi

  if [[ "$desktop_guard" == false ]]; then
    echo "Suspicious AppFormDialog inside showDialog: $file:$line"
    echo "  Use showAppFormDialog/AppForm.show, or route tablet/mobile to AppBottomSheet."
    echo "  showDialog + AppFormDialog is allowed only in explicit desktop-only branches."
    violations=$((violations + 1))
  fi
done < <(rg -n "showDialog\s*\(" "$search_root" -g '*.dart' || true)

if (( violations > 0 )); then
  echo
  echo "Found $violations suspicious AppFormDialog usage(s)." >&2
  exit 1
fi

echo "No suspicious AppFormDialog usage found."
