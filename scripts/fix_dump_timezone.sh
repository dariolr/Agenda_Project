#!/bin/bash
# Corregge il timezone nei dump da SiteGround prima dell'import
# Uso: ./fix_dump_timezone.sh /path/to/dump.sql

if [ -z "$1" ]; then
    echo "Uso: $0 <file.sql>"
    exit 1
fi

sed -i '' 's/SET time_zone = "+00:00";/SET time_zone = "-07:00";/' "$1"
echo "Timezone corretto in $1"
