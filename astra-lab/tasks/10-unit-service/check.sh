#!/bin/bash
. /opt/astra/tasks/lib.sh
U=report-agent.service
prop() { systemctl show -p "$1" --value $U 2>/dev/null; }
F=$(prop FragmentPath)
if [ -z "$F" ] || [ ! -f "$F" ]; then fail "юнит $U не найден (нужен файл в /etc/systemd/system)"; finish; exit; fi
check "юнит-файл лежит в /etc/systemd/system" test "${F%/*}" = /etc/systemd/system
check "systemd перечитал юнит-файл (daemon-reload)" test "$(prop NeedDaemonReload)" = no
check "служба запускает /usr/local/bin/report-agent" bash -c "systemctl show -p ExecStart --value $U | grep -q 'path=/usr/local/bin/report-agent '"
check "служба включена в автозапуск (enabled)" test "$(systemctl is-enabled $U 2>/dev/null)" = enabled
check "автозапуск в обычном режиме: multi-user.target хочет службу" bash -c "systemctl show -p Wants --value multi-user.target | tr ' ' '\n' | grep -qx $U"
check "служба запущена (active)" test "$(systemctl is-active $U)" = active
P=$(prop MainPID)
check "процесс агента работает от имени reporter" test "$(ps -o user= -p "${P:-0}" 2>/dev/null | tr -d ' ')" = reporter
# Проверка перезапуска при сбое: убиваем процесс и ждём новый
if [ "$(systemctl is-active $U)" = active ] && [ "${P:-0}" -gt 0 ]; then
  kill -KILL "$P" 2>/dev/null
  NP=0
  for i in $(seq 1 16); do
    sleep 0.5
    NP=$(prop MainPID)
    [ "$(systemctl is-active $U)" = active ] && [ "${NP:-0}" -gt 0 ] && [ "$NP" != "$P" ] && break
  done
  check "после аварийного завершения служба перезапустилась сама (не дольше 5 с)" bash -c "[ \"\$(systemctl is-active $U)\" = active ] && [ ${NP:-0} -gt 0 ] && [ ${NP:-0} != $P ]"
else
  fail "после аварийного завершения служба перезапустилась сама (не проверено: служба не запущена)"
fi
finish
