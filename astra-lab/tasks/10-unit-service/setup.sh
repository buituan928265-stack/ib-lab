#!/bin/bash
. /opt/astra/tasks/lib.sh
id reporter >/dev/null 2>&1 || useradd -r -s /usr/sbin/nologin -d /nonexistent reporter
cat > /usr/local/bin/report-agent <<'S'
#!/bin/bash
# Учебный агент: каждые 5 секунд пишет строку в стандартный вывод
while true; do
  echo "report-agent: работаю от имени $(id -un), PID $$"
  sleep 5
done
S
chmod 755 /usr/local/bin/report-agent
if [ "$1" = "--reset" ]; then
  systemctl disable --now report-agent.service >/dev/null 2>&1
  rm -f /etc/systemd/system/report-agent.service /lib/systemd/system/report-agent.service
  rm -rf /etc/systemd/system/report-agent.service.d
  systemctl daemon-reload
  systemctl reset-failed report-agent.service >/dev/null 2>&1
fi
true
