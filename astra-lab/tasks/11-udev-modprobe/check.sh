#!/bin/bash
. /opt/astra/tasks/lib.sh
R=/etc/udev/rules.d/70-backup.rules
B=$(losetup -j /srv/backup.img -O NAME -n 2>/dev/null | head -1)
O=$(losetup -j /srv/other.img -O NAME -n 2>/dev/null | head -1)
if [ -z "$B" ] || [ -z "$O" ]; then fail "loop-устройства не подключены — выполните astra reset 11-udev-modprobe"; finish; exit; fi
check "файл правила $R существует" test -f $R
check_not "в правиле нет номера устройства (KERNEL==\"loopN\")" grep -Eq 'KERNEL=="?loop[0-9]' $R
T=$(udevadm test /sys/class/block/${B#/dev/} 2>&1)
check_not "udevadm test не находит ошибок в $R" bash -c "grep -F '$R' <<< \"\$1\" | grep -Eqi 'invalid|error|unknown|ignoring'" _ "$T"
check "правило создаёт ссылку /dev/backupdisk на $B" bash -c "grep -q '^DEVLINKS=.*/dev/backupdisk\b' <<< \"\$1\"" _ "$T"
GID=$(getent group arhiv | cut -d: -f3)
check "правило назначает группу arhiv и права 0660" bash -c "grep -Eq 'Setting permissions $B, uid=[0-9]+, gid=$GID, mode=0?660' <<< \"\$1\"" _ "$T"
T2=$(udevadm test /sys/class/block/${O#/dev/} 2>&1)
check_not "правило не срабатывает на другом устройстве ($O)" bash -c "grep -q '^DEVLINKS=.*/dev/backupdisk\b' <<< \"\$1\"" _ "$T2"
rm -f /dev/backupdisk 2>/dev/null; udevadm test /sys/class/block/${B#/dev/} >/dev/null 2>&1
C=$(modprobe -c 2>/dev/null)
check "модуль usb-storage в чёрном списке (blacklist)" bash -c "grep -qx 'blacklist usb_storage' <<< \"\$1\"" _ "$C"
check "ручная загрузка usb-storage заменена на /bin/false (install)" bash -c "grep -Eqx 'install usb_storage (/usr)?/bin/false' <<< \"\$1\"" _ "$C"
finish
