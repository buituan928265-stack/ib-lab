#!/bin/bash
. /opt/astra/tasks/lib.sh
D=/srv/reports
[ -d $D ] || { fail "нет каталога $D — выполните astra reset 07-acl-audit"; finish; exit; }
check "auditor не в группе buh" bash -c "! id -nG auditor | grep -qw buh"
check "каталог: владелец и права не изменены (buh_chief:buh 750)" test "$(stat -c '%U:%G %a' $D)" = "buh_chief:buh 750"
check "отчёты: права не изменены (640)" bash -c "[ -z \"\$(find $D -maxdepth 1 -type f ! -perm 640)\" ]"
check "auditor читает существующий отчёт" as auditor "cat $D/report_2026-10.txt"
check_not "auditor не может изменить отчёт" as auditor "echo x >> $D/report_2026-10.txt"
check_not "auditor не может создать файл" as auditor "touch $D/.chk_a"
check_not "auditor не может удалить отчёт" as auditor "rm -f $D/report_2026-08.txt && test ! -e $D/report_2026-08.txt"
as buh_chief "echo new > $D/.chk_new; chmod 640 $D/.chk_new" >/dev/null 2>&1
check "auditor читает новый отчёт (ACL по умолчанию)" as auditor "cat $D/.chk_new"
rm -f $D/.chk_new $D/.chk_a
finish
