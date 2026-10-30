#!/bin/bash
. /opt/astra/tasks/lib.sh
st() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null; }
check "в /root/paket.txt записан пакет, которому принадлежит /usr/bin/lsattr" test "$(cat /root/paket.txt 2>/dev/null | tr -d ' \t\r\n')" = e2fsprogs
s=$(st old-agent)
if [[ "$s" == *config-files* ]]; then
  fail "old-agent удалён, но его настройки остались (состояние rc) — нужна полная очистка"
else
  check "пакет old-agent удалён полностью" bash -c "! dpkg-query -W -f='\${Status}' old-agent 2>/dev/null | grep -q 'installed'"
fi
check "файла /etc/old-agent.conf нет" test ! -e /etc/old-agent.conf
check "openssh-server защищён от обновления (hold)" bash -c "apt-mark showhold | grep -qx openssh-server"
check "report-lib установлен" bash -c "dpkg-query -W -f='\${Status}' report-lib 2>/dev/null | grep -q 'install ok installed'"
check "report-tool установлен" bash -c "dpkg-query -W -f='\${Status}' report-tool 2>/dev/null | grep -q 'install ok installed'"
finish
