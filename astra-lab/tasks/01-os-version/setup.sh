#!/bin/bash
. /opt/astra/tasks/lib.sh
[ "$1" = "--reset" ] && rm -f /root/version.txt
cat > /root/inventory-2024.txt <<'TXT'
Опись на 2024 год (устарела)
os=Debian GNU/Linux 11 (bullseye)
kernel=5.10.0-21-amd64
TXT
true
