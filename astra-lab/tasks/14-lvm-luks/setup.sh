#!/bin/bash
. /opt/astra/tasks/lib.sh
D=/srv/lvm
# узлы /dev/loopN могут отсутствовать в контейнере
for i in $(seq 0 31); do [ -e /dev/loop$i ] || mknod -m 660 /dev/loop$i b 7 $i 2>/dev/null; done
# LVM без udev: пусть сам создаёт файлы устройств
if ! grep -q 'udev_rules = 0' /etc/lvm/lvmlocal.conf 2>/dev/null; then
  printf '\n# Лаборатория: в контейнере нет udev\nactivation {\n\tudev_sync = 0\n\tudev_rules = 0\n}\n' >> /etc/lvm/lvmlocal.conf
fi
loopof() { losetup -j "$1" -O NAME -n 2>/dev/null | head -1; }
teardown() {
  umount /srv/db 2>/dev/null
  for m in $(findmnt -rn -o TARGET -S /dev/mapper/secret 2>/dev/null); do umount "$m"; done
  cryptsetup close secret 2>/dev/null
  sed -i '/^[[:space:]]*secret[[:space:]]/d' /etc/crypttab 2>/dev/null
  vgchange -an vgdata >/dev/null 2>&1
  vgremove -ff -y vgdata >/dev/null 2>&1
  for f in $D/disk1.img $D/disk2.img; do
    for l in $(losetup -j $f -O NAME -n 2>/dev/null); do pvremove -ff -y $l >/dev/null 2>&1; losetup -d $l; done
  done
  dmsetup remove vgdata-lvdb vgdata-lvsecret 2>/dev/null
  rm -rf $D /dev/vgdata
}
[ "$1" = "--reset" ] && teardown
# уже подготовлено и устройства на месте — ничего не делаем
if [ -n "$(loopof $D/disk1.img)" ] && [ -n "$(loopof $D/disk2.img)" ] && vgs vgdata >/dev/null 2>&1; then exit 0; fi
teardown
mkdir -p $D /srv/db
truncate -s 256M $D/disk1.img $D/disk2.img
L1=$(losetup -f --show $D/disk1.img); L2=$(losetup -f --show $D/disk2.img)
pvcreate -y $L1 >/dev/null && vgcreate vgdata $L1 >/dev/null && lvcreate -y -L 200M -n lvdb vgdata >/dev/null
mkfs.ext4 -q -L DB /dev/vgdata/lvdb
mount /dev/vgdata/lvdb /srv/db
head -c 50M /dev/urandom > /srv/db/base.dat
echo "Учебная база. Не удалять." > /srv/db/README.txt
md5sum /srv/db/base.dat | cut -d' ' -f1 > $D/.base.md5
cat > $D/disks.txt <<T
Диск 1: $L1  (уже в группе томов vgdata, на нём lvdb)
Диск 2: $L2  (новый, пустой)
T
true
