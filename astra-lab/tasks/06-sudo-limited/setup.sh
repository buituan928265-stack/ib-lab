#!/bin/bash
. /opt/astra/tasks/lib.sh
ensure_user dezhurny
gpasswd -d dezhurny sudo >/dev/null 2>&1
mkdir -p /var/lib/astra-lab
if [ "$1" = "--reset" ]; then
  grep -l dezhurny /etc/sudoers.d/* 2>/dev/null | xargs -r rm -f
fi
[ -f /var/lib/astra-lab/sudoers.md5 ] || md5sum /etc/sudoers > /var/lib/astra-lab/sudoers.md5
true
