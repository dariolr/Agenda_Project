#!/bin/bash
# Notification Queue Worker
# Cron: * * * * * /path/to/agenda_core/bin/run-worker.sh

cd "$(dirname "$0")/.."
php bin/notification-worker.php "$@"
