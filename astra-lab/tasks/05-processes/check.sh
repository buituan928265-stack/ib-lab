#!/bin/bash
. /opt/astra/tasks/lib.sh
M=/var/lib/.astra-05
[ -f $M ] || { fail "задание не подготовлено — выполните astra reset 05-processes"; finish; exit; }
R=$(pgrep -x year-report | head -1)
check "годовой отчёт (year-report) продолжает работу" test -n "$R"
check "у year-report значение nice не меньше 10" test "$(ps -o ni= -p "${R:-0}" 2>/dev/null | tr -d ' ')" -ge 10
check_not "uchet-sync остановлена" pgrep -x uchet-sync
check "файл блокировки убран (остановка сигналом TERM)" test ! -e /var/lib/uchet/sync.lock
A=$(pgrep -x uchet-agent | head -1)
check "uchet-agent работает с прежним номером процесса" test -n "$A" -a "$A" = "$(cat $M)"
check "uchet-agent перечитал настройки" grep -q 'перечитаны' /var/log/uchet/agent.log
finish
