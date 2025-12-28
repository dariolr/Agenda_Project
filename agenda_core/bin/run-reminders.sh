#!/bin/bash
# Queue Upcoming Reminders
# Cron: 0 * * * * /path/to/agenda_core/bin/run-reminders.sh

cd "$(dirname "$0")/.."
php bin/queue-reminders.php "$@"
