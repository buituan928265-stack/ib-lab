#!/bin/bash
. /opt/astra/tasks/lib.sh
IMG=/srv/disk.img
if [ ! -f $IMG ]; then fail "нет файла-образа $IMG"; finish; exit; fi
SZ=$(stat -c %s $IMG)
check "размер образа около 200 МБ" test $SZ -ge $((190*1024*1024)) -a $SZ -le $((215*1000*1000))
L=$(losetup -j $IMG -O NAME -n 2>/dev/null | head -1)
if [ -z "$L" ]; then fail "образ не подключён как loop-устройство (losetup -j $IMG)"; finish; exit; fi
check "таблица разделов GPT" test "$(blkid -p -o value -s PTTYPE $L 2>/dev/null)" = gpt
NP=$(lsblk -nr -o TYPE $L | grep -c part)
check "на диске ровно один раздел" test "$NP" = 1
P=$(lsblk -nr -o NAME,TYPE $L | awk '$2=="part"{print "/dev/"$1; exit}')
check "есть файл устройства раздела ${P:-?} (lab-partnodes)" test -b "${P:-/nonexistent}"
PS=$(lsblk -nbr -o SIZE ${P:-/dev/null} 2>/dev/null | head -1)
check "раздел занимает почти весь диск" test "${PS:-0}" -ge $((SZ*9/10))
check "на разделе ext4" test "$(blkid -p -o value -s TYPE ${P:-/dev/null} 2>/dev/null)" = ext4
check "метка файловой системы ARCHIVE" test "$(blkid -p -o value -s LABEL ${P:-/dev/null} 2>/dev/null)" = ARCHIVE
UUID=$(blkid -p -o value -s UUID ${P:-/dev/null} 2>/dev/null)
# строка fstab для /mnt/archive (без комментариев)
FL=$(awk '!/^[[:space:]]*#/ && $2=="/mnt/archive"' /etc/fstab)
check "в /etc/fstab ровно одна строка для /mnt/archive" test "$(printf '%s\n' "$FL" | grep -c .)" = 1
SRC=$(awk '{print $1}' <<< "$FL" | tr -d '"'); TYP=$(awk '{print $3}' <<< "$FL"); OPT=$(awk '{print $4}' <<< "$FL")
check "в fstab устройство указано по UUID этого раздела" test -n "$UUID" -a "$SRC" = "UUID=$UUID"
check "в fstab тип ext4" test "$TYP" = ext4
check "в параметрах fstab есть nofail" bash -c "tr ',' '\n' <<< '$OPT' | grep -qx nofail"
check "findmnt --verify не находит ошибок" findmnt --verify
# монтирование через fstab: отмонтировать и смонтировать по имени каталога
umount /mnt/archive 2>/dev/null
check "команда mount /mnt/archive монтирует раздел из fstab" mount /mnt/archive
check "в /mnt/archive смонтирован раздел ${P:-?}" test "$(findmnt -n -o SOURCE /mnt/archive 2>/dev/null)" = "$P"
finish
