#!/usr/bin/env bash
set -euo pipefail

# This repository is the gestionale frontend (Flutter web).
# Demo DB seed/reset are owned by agenda_core.

./scripts/demo/verify_demo_env.sh

echo "Prepare demo (frontend):"
echo "1) Ensure demo API endpoint is reachable"
echo "2) Build web bundle with demo dart-defines"
echo "3) Deploy demo artifact to demo web host"
