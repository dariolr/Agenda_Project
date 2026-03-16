#!/usr/bin/env bash
set -euo pipefail

./agenda_backend/scripts/demo/verify_demo_env.sh
./agenda_frontend/scripts/demo/verify_demo_env.sh
./agenda_core/scripts/demo/verify_demo_env.sh

echo "OK: all demo environment checks passed"
