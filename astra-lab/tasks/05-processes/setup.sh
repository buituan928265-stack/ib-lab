#!/bin/bash
. /opt/astra/tasks/lib.sh
ensure_user buh_ivanova; ensure_user uchet
B=/usr/local/bin; S=/var/lib/uchet; M=/var/lib/.astra-05
mkdir -p $S /var/log/uchet; chown uchet:uchet $S /var/log/uchet
cat > $B/year-report <<'X'
#!/bin/bash
# Годовой отчёт: долго считает
while :; do :; done
X
cat > $B/uchet-sync <<'X'
#!/bin/bash
L=/var/lib/uchet/sync.lock
trap 'rm -f $L; echo "$(date +%T) остановлена корректно" >> /var/log/uchet/sync.log; exit 0' TERM
echo $$ > $L
while :; do sleep 1; done
X
cat > $B/uchet-agent <<'X'
#!/bin/bash
trap 'echo "$(date +%T) настройки перечитаны (HUP)" >> /var/log/uchet/agent.log' HUP
echo "$(date +%T) запущен, PID $$" >> /var/log/uchet/agent.log
while :; do sleep 1; done
X
chmod 755 $B/year-report $B/uchet-sync $B/uchet-agent
start() { su -s /bin/bash "$1" -c "setsid $2 >/dev/null 2>&1 < /dev/null &"; }
if [ "$1" = "--reset" ] || [ ! -f $M ]; then
  pkill -x year-report; pkill -KILL -x uchet-sync; pkill -KILL -x uchet-agent
  sleep 0.5
  rm -f $S/sync.lock /var/log/uchet/agent.log /var/log/uchet/sync.log
  start buh_ivanova $B/year-report
  start uchet $B/uchet-sync
  start uchet $B/uchet-agent
  sleep 1
  pgrep -x uchet-agent > $M
fi
true
