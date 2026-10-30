#!/bin/bash
. /opt/astra/tasks/lib.sh
ensure_group otdel
for u in ivanova petrov smirnov; do ensure_user "$u"; done
usermod -aG otdel ivanova; usermod -aG otdel petrov
gpasswd -d smirnov otdel >/dev/null 2>&1
[ "$1" = "--reset" ] && rm -rf /srv/otdel
true
