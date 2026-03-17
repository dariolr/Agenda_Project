#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# This repository is the gestionale frontend (Flutter web).
# Demo DB seed/reset are owned by agenda_core.

"$SCRIPT_DIR/verify_demo_env_backend.sh"

echo "Prepare demo (frontend):"
echo "1) Ensure demo API endpoint is reachable"
echo "2) Build web bundle with demo dart-defines"
echo "3) Deploy demo artifact to demo web host"
