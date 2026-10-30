#!/bin/bash
# Пробный практический экзамен: исходное состояние для 10 пунктов.
. /opt/astra/tasks/lib.sh
ensure_user nachalnik

reset_all() {
  systemctl disable --now exam-agent.service 2>/dev/null
  rm -f /etc/systemd/system/exam-agent.service /etc/systemd/system/multi-user.target.wants/exam-agent.service
  systemctl daemon-reload
  crontab -r -u dezh 2>/dev/null
  pkill -u dezh 2>/dev/null; userdel -r dezh 2>/dev/null; groupdel smena 2>/dev/null
  dpkg -P exam-agent >/dev/null 2>&1
  rm -rf /srv/smena /root/exam /usr/local/bin/count-shell.sh /opt/exam /etc/exam /var/lib/exam
}
[ "$1" = "--reset" ] && reset_all

if [ ! -d /opt/exam ]; then
  # Пакет exam-agent собираем на месте: интернет для задания не нужен.
  B=$(mktemp -d)
  mkdir -p "$B/DEBIAN" "$B/usr/bin"
  cat > "$B/DEBIAN/control" <<'C'
Package: exam-agent
Version: 1.0
Architecture: all
Maintainer: Astra Trainer <trainer@example.com>
Description: Учебный агент для пробного экзамена
C
  cat > "$B/usr/bin/exam-agent" <<'S'
#!/bin/bash
# Учебный агент: с ключом --report печатает сводку, без ключей работает как служба.
if [ "$1" = "--report" ]; then echo "$(date '+%F %T') отчёт агента: пользователь $(id -un)"; exit 0; fi
while true; do echo "exam-agent работает от пользователя $(id -un)"; sleep 30; done
S
  chmod 755 "$B/usr/bin/exam-agent"
  mkdir -p /opt/exam/bin
  dpkg-deb --build --root-owner-group "$B" /opt/exam/exam-agent_1.0_all.deb >/dev/null
  rm -rf "$B"

  # Лишний SUID на копии программы.
  cp /usr/bin/id /opt/exam/bin/id-copy; chmod 4755 /opt/exam/bin/id-copy
  cp /usr/bin/date /opt/exam/bin/date-copy; chmod 755 /opt/exam/bin/date-copy

  # Конфигурация, которую нужно заархивировать.
  mkdir -p /etc/exam/conf.d
  echo "mode=exam" > /etc/exam/app.conf
  echo "host=db.local" > /etc/exam/conf.d/db.conf
  echo "level=info" > /etc/exam/conf.d/log.conf

  # Код смены. Для проверки храним его хеш.
  mkdir -p /var/lib/exam; chmod 700 /var/lib/exam
  CODE=$((100000 + RANDOM % 900000))
  echo -n "$CODE" > /var/lib/exam/.code
  echo -n "$CODE" | md5sum | cut -d' ' -f1 > /var/lib/exam/code.md5
fi
# Пишем код в журнал при каждом запуске astra task: журнал в памяти пропадает после перезапуска машины.
logger -t exam-setup -p user.warning "код смены: $(cat /var/lib/exam/.code)"
true
