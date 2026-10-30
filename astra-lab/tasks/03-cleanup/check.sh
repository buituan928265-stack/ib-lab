#!/bin/bash
. /opt/astra/tasks/lib.sh
D=/srv/exchange
[ -d $D ] || { fail "нет каталога $D — выполните astra reset 03-cleanup"; finish; exit; }
check "старые .tmp удалены" bash -c "[ -z \"\$(find $D -name '*.tmp' -mtime +7)\" ] && [ ! -e $D/1c_export.tmp ]"
check "свежие .tmp на месте" test -f $D/upload_1.tmp -a -f $D/scan/scan_0930.tmp
check "файлы с tmp в имени, но не .tmp, на месте" test -f $D/tmp_notes.txt -a -f $D/otchety/2026/q3.tmp.bak
check "остальные файлы на месте" test -f $D/otchety/2026/q3.ods -a -f $D/arhiv/readme.txt -a -f $D/otchety/2026/small.pdf
check "битые ссылки удалены" bash -c "[ -z \"\$(find $D -xtype l)\" ] && [ ! -L $D/plan.ods ]"
check "рабочие ссылки на месте" test -L $D/q3_link.ods -a -L $D/scan/readme
check "большие файлы не удалены" test -f $D/scan/scan_full.pdf -a -f "$D/obmen ivanova/video.mp4" -a -f $D/arhiv/base_2025.tar
EXP=$(printf '%s\n' "$D/scan/scan_full.pdf" "$D/obmen ivanova/video.mp4" "$D/arhiv/base_2025.tar" | sort)
GOT=$(sed 's/[[:space:]]*$//; s#//*#/#g' /root/big_files.txt 2>/dev/null | grep -v '^$' | sort -u)
check "в /root/big_files.txt ровно большие файлы, полные пути" test "$GOT" = "$EXP"
finish
