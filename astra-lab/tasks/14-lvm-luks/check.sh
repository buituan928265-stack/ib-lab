#!/bin/bash
. /opt/astra/tasks/lib.sh
D=/srv/lvm
L1=$(losetup -j $D/disk1.img -O NAME -n 2>/dev/null | head -1)
L2=$(losetup -j $D/disk2.img -O NAME -n 2>/dev/null | head -1)
if [ -z "$L1" ] || [ -z "$L2" ] || ! vgs vgdata >/dev/null 2>&1; then
  fail "диски лаборатории не найдены — выполните astra reset 14-lvm-luks"; finish; exit
fi
MiB=$((1024*1024))
lvsize() { lvs --noheadings --units b --nosuffix -o lv_size "vgdata/$1" 2>/dev/null | tr -d ' '; }
check "второй диск $L2 — физический том в группе vgdata" test "$(pvs --noheadings -o vg_name $L2 2>/dev/null | tr -d ' ')" = vgdata
S=$(lvsize lvdb)
check "том lvdb не меньше 400 МиБ" test "${S:-0}" -ge $((400*MiB))
check "том lvdb не больше 450 МиБ (место нужно и для lvsecret)" test "${S:-0}" -le $((450*MiB))
check "в /srv/db смонтирован том lvdb" test "$(findmnt -n -o SOURCE /srv/db 2>/dev/null)" = /dev/mapper/vgdata-lvdb
BC=$(tune2fs -l /dev/vgdata/lvdb 2>/dev/null | awk -F: '/^Block count/{gsub(/ /,"",$2);print $2}')
BS=$(tune2fs -l /dev/vgdata/lvdb 2>/dev/null | awk -F: '/^Block size/{gsub(/ /,"",$2);print $2}')
check "файловая система растянута на весь том (resize2fs)" test $(( ${BC:-0} * ${BS:-0} )) -ge $(( ${S:-1} * 98 / 100 ))
check "данные в /srv/db на месте" test "$(md5sum /srv/db/base.dat 2>/dev/null | cut -d' ' -f1)" = "$(cat $D/.base.md5 2>/dev/null)"
S2=$(lvsize lvsecret)
check "том lvsecret размером около 64 МиБ" test "${S2:-0}" -ge $((60*MiB)) -a "${S2:-0}" -le $((80*MiB))
check "lvsecret зашифрован LUKS" cryptsetup isLuks /dev/vgdata/lvsecret
check "LUKS-том открыт под именем secret" test -b /dev/mapper/secret
check "secret открыт именно поверх lvsecret" bash -c "cryptsetup status secret 2>/dev/null | grep -Eq 'device:[[:space:]]+/dev/(mapper/vgdata-lvsecret|vgdata/lvsecret)$'"
check "внутри secret файловая система ext4" test "$(blkid -p -o value -s TYPE /dev/mapper/secret 2>/dev/null)" = ext4
LU=$(cryptsetup luksUUID /dev/vgdata/lvsecret 2>/dev/null)
CL=$(awk '!/^[[:space:]]*#/ && $1=="secret"' /etc/crypttab 2>/dev/null)
check "в /etc/crypttab ровно одна строка для secret" test "$(printf '%s\n' "$CL" | grep -c .)" = 1
SRC=$(awk '{print $2}' <<< "$CL" | tr -d '"'); KEY=$(awk '{print $3}' <<< "$CL"); OPT=$(awk '{print $4}' <<< "$CL")
check "в crypttab указан том lvsecret (путь или UUID LUKS)" bash -c "case '$SRC' in /dev/vgdata/lvsecret|/dev/mapper/vgdata-lvsecret|UUID=$LU) exit 0;; *) exit 1;; esac"
check "в crypttab пароль запрашивается при загрузке (ключ none или -)" bash -c "case '$KEY' in none|-) exit 0;; *) exit 1;; esac"
check "в crypttab указан тип luks" bash -c "tr ',' '\n' <<< '$OPT' | grep -qx luks"
finish
