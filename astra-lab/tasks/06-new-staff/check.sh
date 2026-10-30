#!/bin/bash
. /opt/astra/tasks/lib.sh
sf() { getent shadow "$1" | cut -d: -f"$2"; }
today=$(( $(date +%s) / 86400 ))
check "группа kadry существует" getent group kadry
check "в /etc/skel есть PRAVILA.txt" test -f /etc/skel/PRAVILA.txt
for u in sidorova kuznetsov; do
  if ! id "$u" >/dev/null 2>&1; then fail "пользователь $u не создан"; continue; fi
  home=$(getent passwd "$u" | cut -d: -f6)
  check "$u: домашний каталог /home/$u, владелец $u" test "$home" = "/home/$u" -a "$(stat -c %U "/home/$u" 2>/dev/null)" = "$u"
  check "$u: в домашнем каталоге есть PRAVILA.txt" test -f "/home/$u/PRAVILA.txt"
  check "$u: оболочка /bin/bash" test "$(getent passwd "$u" | cut -d: -f7)" = /bin/bash
  check "$u: состоит в группе kadry" bash -c "id -nG $u | grep -qw kadry"
  p=$(sf "$u" 2)
  check "$u: пароль задан" bash -c "[ -n '$p' ] && [[ '${p:0:1}' != '!' && '${p:0:1}' != '*' ]]"
  check "$u: смена пароля при первом входе" test "$(sf "$u" 3)" = 0
  check "$u: пароль действует 90 дней" test "$(sf "$u" 5)" = 90
  check "$u: предупреждение за 14 дней" test "$(sf "$u" 6)" = 14
done
check "kuznetsov: учётная запись действует до 2026-12-31" test "$(sf kuznetsov 8)" = "$(( $(date -ud 2026-12-31 +%s) / 86400 ))"
id sidorova >/dev/null 2>&1 && check "sidorova: срок учётной записи не ограничен" test -z "$(sf sidorova 8)"
if id ivanov_old >/dev/null 2>&1; then
  p=$(sf ivanov_old 2); e=$(sf ivanov_old 8); s=$(getent passwd ivanov_old | cut -d: -f7)
  check "ivanov_old: вход запрещён" bash -c "[[ '${p:0:1}' == '!' || '${p:0:1}' == '*' ]] || [[ -n '$e' && '$e' -le $today ]] || [[ '$s' == */nologin || '$s' == */false ]]"
  check "ivanov_old: документы на месте" test -f /home/ivanov_old/dela.txt
else
  fail "учётная запись ivanov_old удалена, а её нужно было только заблокировать"
fi
finish
