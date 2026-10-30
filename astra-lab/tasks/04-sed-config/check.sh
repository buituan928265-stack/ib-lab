#!/bin/bash
. /opt/astra/tasks/lib.sh
C=/etc/uchet/uchet.conf; O=/opt/astra/tasks/04-sed-config/orig.conf
[ -f $C ] || { fail "нет файла $C — выполните astra reset 04-sed-config"; finish; exit; }
# Приводим к одному виду то, что можно записать по-разному: пробелы в конце, «# debug_» и «#debug_»
norm() { sed -E 's/[[:space:]]+$//; s/^[[:space:]]*#[[:space:]]*(debug_)/#\1/; s/^log_level[[:space:]]*=[[:space:]]*/log_level = /' "$1"; }
EXP=$(sed -E 's/db-old\.local/db01.corp.local/g; s/^log_level = debug$/log_level = warning/; s/^debug_/#debug_/' $O)
check "копия uchet.conf.bak совпадает с исходным файлом" cmp -s $C.bak $O
check_not "db-old.local больше не встречается" grep -q 'db-old\.local' $C
check "db01.corp.local стоит везде, где был старый адрес" test "$(grep -o 'db01\.corp\.local' $C | wc -l)" = 4
check "log_level = warning" grep -Eq '^log_level[[:space:]]*=[[:space:]]*warning[[:space:]]*$' $C
check "пример в комментарии не тронут" grep -qx '# Пример: log_level = info' $C
check "строки, начинающиеся с debug_, закомментированы" bash -c "! grep -q '^debug_' $C && [ \$(grep -Ec '^[[:space:]]*#[[:space:]]*debug_' $C) = 3 ]"
check "show_debug_panel не закомментирована" grep -qx 'show_debug_panel = no' $C
check "остальные строки не изменены" test "$(norm $C)" = "$EXP"
finish
