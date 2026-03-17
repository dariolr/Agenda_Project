#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/verify_demo_env_backend.sh"
"$SCRIPT_DIR/verify_demo_env_frontend.sh"
"$SCRIPT_DIR/verify_demo_env_core.sh"

echo "OK: all demo environment checks passed"
