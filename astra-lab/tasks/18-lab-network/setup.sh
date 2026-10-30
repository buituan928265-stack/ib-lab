#!/bin/bash
# Служба SSH слушает нестандартный порт. Интерфейса lab0, маршрута и записи repo.lab нет.
. /opt/astra/tasks/lib.sh
P=/etc/ssh/sshd_config.d/lab-port.conf
if [ "$1" = "--reset" ] || [ ! -f $P ]; then
  echo "Port $((2200 + RANDOM % 700))" > $P
  systemctl restart ssh
  # Удаляем все подключения NetworkManager, привязанные к lab0 (активные и нет).
  for c in $(nmcli -g UUID con show 2>/dev/null); do
    [ "$(nmcli -g connection.interface-name con show "$c" 2>/dev/null)" = lab0 ] && nmcli con del "$c" >/dev/null
  done
  ip link del lab0 2>/dev/null
  # /etc/hosts в контейнере смонтирован снаружи: правим на месте, без sed -i.
  grep -v 'repo\.lab' /etc/hosts > /tmp/hosts.$$ && cat /tmp/hosts.$$ > /etc/hosts; rm -f /tmp/hosts.$$
  rm -f /root/ssh-port.txt
fi
true
