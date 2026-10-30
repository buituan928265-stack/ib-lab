#!/bin/bash
. /opt/astra/tasks/lib.sh
S=/usr/local/bin/userinfo
if [ ! -f $S ]; then fail "скрипт $S не найден"; finish; exit; fi
check "скрипт исполняемый" test -x $S
# run: запустить, сохранить stdout, stderr и код
run() { OUT=$("$@" 2>/tmp/.ui_err); RC=$?; ERR=$(cat /tmp/.ui_err); rm -f /tmp/.ui_err; }
u=chk$RANDOM; useradd -M -d /opt/dom_$u -s /bin/sh -u 4321 "$u" >/dev/null 2>&1
run $S root
check "userinfo root: вывод «root 0 /root /bin/bash»" test "$OUT" = "root 0 /root /bin/bash"
check "userinfo root: код 0" test "$RC" = 0
run $S "$u"
check "пользователь с UID 4321 и каталогом /opt/dom_…: верная строка" test "$OUT" = "$u 4321 /opt/dom_$u /bin/sh"
run $S nobody
check "userinfo nobody: верная строка" test "$OUT" = "$(getent passwd nobody | awk -F: '{print $1, $3, $6, $7}')"
run $S net_takogo_$RANDOM
check "нет пользователя: код 1" test "$RC" = 1
check "нет пользователя: обычный вывод пуст" test -z "$OUT"
check "нет пользователя: сообщение в stderr" test -n "$ERR"
run $S ivan
check "userinfo ivan (есть только ivanova): код 1, вывод пуст" test "$RC" = 1 -a -z "$OUT"
run $S
check "без аргументов: код 2" test "$RC" = 2
check "без аргументов: подсказка «Использование» в stderr, вывод пуст" bash -c "[ -z \"\$1\" ] && grep -q 'Использование' <<< \"\$2\"" _ "$OUT" "$ERR"
run $S root "$u"
check "два аргумента: код 2" test "$RC" = 2
check "два аргумента: обычный вывод пуст" test -z "$OUT"
OUT=$(su -s /bin/bash ivanova -c "$S $u" 2>/dev/null)
check "работает под обычным пользователем" test "$OUT" = "$u 4321 /opt/dom_$u /bin/sh"
userdel "$u" >/dev/null 2>&1
finish
