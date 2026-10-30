#!/bin/bash
# Служба report-gen падает: каталог данных принадлежит root, а служба работает от пользователя report.
# Журнал systemd хранится только в памяти. Отдельного файла журнала и ротации для службы нет.
. /opt/astra/tasks/lib.sh
id report >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin -d /var/lib/report-gen report

cat > /usr/local/bin/report-gen <<'S'
#!/bin/bash
# Учебная служба: раз в 10 секунд пишет отчёт в /var/lib/report-gen.
DIR=/var/lib/report-gen
echo "report-gen запущена от пользователя $(id -un)"
if ! touch "$DIR/.probe" 2>/dev/null; then
  # <3> в начале строки — приоритет err для журнала systemd
  echo "<3>ОШИБКА: нет права записи в каталог $DIR (пользователь $(id -un))" >&2
  exit 1
fi
rm -f "$DIR/.probe"
while true; do
  date '+%F %T' > "$DIR/last-report.txt"
  echo "отчёт сформирован: $DIR/last-report.txt"
  sleep 10
done
S
chmod 755 /usr/local/bin/report-gen

cat > /etc/systemd/system/report-gen.service <<'U'
[Unit]
Description=Учебная служба формирования отчётов

[Service]
User=report
ExecStart=/usr/local/bin/report-gen
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
U

if [ "$1" = "--reset" ] || [ ! -d /var/lib/report-gen ]; then
  systemctl stop report-gen 2>/dev/null
  rm -rf /var/lib/report-gen; mkdir -p /var/lib/report-gen
  chown root:root /var/lib/report-gen; chmod 755 /var/lib/report-gen
  rm -f /etc/syslog-ng/conf.d/report-gen.conf /etc/logrotate.d/report-gen /var/log/report-gen.log*
  systemctl reload syslog-ng 2>/dev/null
  # Журнал systemd — только в памяти (как будто постоянное хранение не настроено).
  rm -rf /etc/systemd/journald.conf.d /var/log/journal
  sed -i 's/^#\?Storage=.*/#Storage=auto/' /etc/systemd/journald.conf
  systemctl restart systemd-journald
fi
systemctl daemon-reload
systemctl reset-failed report-gen 2>/dev/null
systemctl enable report-gen >/dev/null 2>&1
systemctl restart report-gen 2>/dev/null
true
