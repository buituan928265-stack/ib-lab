#!/bin/bash
. /opt/astra/tasks/lib.sh
ensure_user ivanova
[ "$1" = "--reset" ] && rm -f /usr/local/bin/userinfo
true
