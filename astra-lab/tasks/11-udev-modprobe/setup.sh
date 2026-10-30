#!/bin/bash
. /opt/astra/tasks/lib.sh
ensure_group arhiv
# узлы /dev/loopN могут отсутствовать в контейнере
for i in $(seq 0 31); do [ -e /dev/loop$i ] || mknod -m 660 /dev/loop$i b 7 $i 2>/dev/null; done
for f in /srv/backup.img /srv/other.img; do
  if [ "$1" = "--reset" ]; then
    for l in $(losetup -j $f -O NAME -n 2>/dev/null); do losetup -d $l; done
    rm -f $f
  fi
  [ -f $f ] || truncate -s 16M $f
  [ -n "$(losetup -j $f -O NAME -n 2>/dev/null)" ] || losetup -f $f
done
if [ "$1" = "--reset" ]; then
  rm -f /etc/udev/rules.d/70-backup.rules /dev/backupdisk
  grep -rlE '^\s*(blacklist|install)\s+usb[-_]storage' /etc/modprobe.d 2>/dev/null | xargs -r rm -f
fi
true
