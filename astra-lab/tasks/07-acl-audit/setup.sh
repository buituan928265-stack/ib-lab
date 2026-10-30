#!/bin/bash
. /opt/astra/tasks/lib.sh
ensure_group buh
ensure_user buh_chief; ensure_user auditor
usermod -aG buh buh_chief; gpasswd -d auditor buh >/dev/null 2>&1
if [ "$1" = "--reset" ] || [ ! -d /srv/reports ]; then
  rm -rf /srv/reports; mkdir -p /srv/reports
  for m in 2026-08 2026-09 2026-10; do echo "Отчёт за $m" > /srv/reports/report_$m.txt; done
  chown -R buh_chief:buh /srv/reports; chmod 750 /srv/reports; chmod 640 /srv/reports/*
fi
true
