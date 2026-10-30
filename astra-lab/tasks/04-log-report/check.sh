#!/bin/bash
. /opt/astra/tasks/lib.sh
L=/var/log/portal/access.log; R=/root/report
[ -s $L ] || { fail "нет журнала $L — выполните astra reset 04-log-report"; finish; exit; }
check "журнал не изменён" test "$(md5sum < $L | cut -d' ' -f1)" = "$(cat /var/lib/.astra-04-log.md5 2>/dev/null)"
check "errors_5xx.txt: все строки с кодом 5xx, и только они" test "$(cat $R/errors_5xx.txt 2>/dev/null)" = "$(awk '$9 ~ /^5[0-9][0-9]$/' $L)"
check "count_404.txt: верное число" test "$(tr -d '[:space:]' 2>/dev/null < $R/count_404.txt)" = "$(awk '$9 == 404' $L | wc -l)"
EXP=$(awk '{print $1}' $L | sort | uniq -c | sort -rn | head -3 | awk '{print $1, $2}')
# допускаем «число адрес» и «адрес число», любые пробелы
GOT=$(awk 'NF{ if ($1 ~ /^[0-9]+$/ && $2 ~ /\./) print $1, $2; else if ($2 ~ /^[0-9]+$/) print $2, $1; else print "?" }' $R/top3.txt 2>/dev/null)
check "top3.txt: три самых активных адреса с числом запросов, по убыванию" test "$GOT" = "$EXP"
finish
