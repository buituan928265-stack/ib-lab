#!/bin/bash
. /opt/astra/tasks/lib.sh

# 1. cron: в crontab пользователя backup строка с backup-db.sh в 02:30 по будним дням.
LINE=$(crontab -l -u backup 2>/dev/null | grep -v '^[[:space:]]*#' | grep '/usr/local/bin/backup-db.sh' | head -1)
check "в crontab пользователя backup есть запуск /usr/local/bin/backup-db.sh" test -n "$LINE"
read -r MIN HOUR DOM MON DOW _ <<<"$LINE"
DOW=${DOW,,}
check "время запуска 02:30" bash -c '[[ "$1" =~ ^0?30$ && "$2" =~ ^0?2$ ]]' _ "$MIN" "$HOUR"
check "каждый день месяца, каждый месяц (* *)" test "$DOM $MON" = "* *"
check "только по будним дням (пн–пт)" bash -c 'case "$1" in 1-5|mon-fri|1,2,3,4,5|mon,tue,wed,thu,fri) exit 0;; *) exit 1;; esac' _ "$DOW"
check "вывод скрипта дописывается в /var/log/backup-db.log" bash -c '[[ "$1" =~ \>\>[[:space:]]*/var/log/backup-db\.log ]]' _ "$LINE"
check "пользователь backup может писать в /var/log/backup-db.log" as backup "test -w /var/log/backup-db.log"
check_not "в crontab root задачу не дублировали" bash -c 'crontab -l -u root 2>/dev/null | grep -v "^[[:space:]]*#" | grep -q backup-db.sh'

# 2. Таймер systemd clean-upload.timer: каждые 15 минут, пропуски догоняются, включён.
T=clean-upload.timer
check "таймер $T включён (enabled)" systemctl is-enabled --quiet $T
check "таймер $T запущен (active)" systemctl is-active --quiet $T
check "таймер запускает clean-upload.service" test "$(systemctl show -p Triggers --value $T)" = clean-upload.service
CAL=$(systemctl show -p TimersCalendar --value $T | sed -n 's/.*OnCalendar=\([^;]*\) ;.*/\1/p' | head -1 | sed 's/ *$//')
# Считаем шаг между ближайшими срабатываниями: должен быть ровно 15 минут.
STEPS=$(systemd-analyze calendar --iterations=6 "$CAL" 2>/dev/null | grep -oE '[0-9]{2}:[0-9]{2}:[0-9]{2}' \
  | awk -F: '{t=$1*3600+$2*60+$3; if(NR>1){d=t-p; if(d<0)d+=86400; print d} p=t}' | sort -u | tr '\n' ' ')
check "расписание таймера — каждые 15 минут (OnCalendar)" test "$STEPS" = "900 "
check "пропущенные запуски выполняются после включения (Persistent=yes)" \
  test "$(systemctl show -p Persistent --value $T)" = yes
touch -d '10 days ago' /srv/upload/.chk_old; touch /srv/upload/.chk_new
check "служба clean-upload.service успешно отрабатывает" systemctl start clean-upload.service
check "служба удалила старый файл и не тронула новый" bash -c '[ ! -e /srv/upload/.chk_old ] && [ -e /srv/upload/.chk_new ]'
rm -f /srv/upload/.chk_old /srv/upload/.chk_new
finish
