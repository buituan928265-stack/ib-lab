#!/bin/bash
. /opt/astra/tasks/lib.sh
# узлы /dev/loopN могут отсутствовать в контейнере
for i in $(seq 0 31); do [ -e /dev/loop$i ] || mknod -m 660 /dev/loop$i b 7 $i 2>/dev/null; done
# lab-partnodes: создать узлы разделов loop-устройства (в контейнере нет udev)
cat > /usr/local/sbin/lab-partnodes <<'S'
#!/bin/bash
# Создаёт файлы устройств /dev/loopNpM для разделов, которые видит ядро.
[ -n "$1" ] || { echo "Использование: lab-partnodes /dev/loopN"; exit 2; }
d=${1#/dev/}
[ -d /sys/block/$d ] || { echo "Нет устройства $1"; exit 1; }
partx -u "/dev/$d" 2>/dev/null
n=0
for p in /sys/block/$d/${d}p*; do
  [ -e "$p/dev" ] || continue
  b=$(basename "$p")
  [ -b /dev/$b ] && [ "$(stat -c '%t:%T' /dev/$b)" = "$(printf '%x:%x' $(tr : ' ' < $p/dev))" ] && continue
  rm -f /dev/$b; mknod -m 660 /dev/$b b $(tr : ' ' < $p/dev); chgrp disk /dev/$b
  echo "создан /dev/$b"; n=$((n+1))
done
[ $n -eq 0 ] && echo "новых разделов нет (смотрите lsblk $1)"
true
S
chmod 755 /usr/local/sbin/lab-partnodes
if [ "$1" = "--reset" ]; then
  umount /mnt/archive 2>/dev/null
  sed -i '\#[[:space:]]/mnt/archive[[:space:]]#d' /etc/fstab
  for l in $(losetup -j /srv/disk.img -O NAME -n 2>/dev/null); do
    umount ${l}p* 2>/dev/null; losetup -d $l
  done
  rm -f /srv/disk.img
  # убрать узлы разделов, которых больше нет в ядре
  for n in /dev/loop*p*; do [ -b "$n" ] && [ ! -e /sys/class/block/${n#/dev/} ] && rm -f "$n"; done
  rmdir /mnt/archive 2>/dev/null
  systemctl daemon-reload 2>/dev/null
fi
true
