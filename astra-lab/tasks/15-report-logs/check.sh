#!/bin/bash
. /opt/astra/tasks/lib.sh
check "служба report-gen работает (active)" systemctl is-active --quiet report-gen
check "служба report-gen включена в автозапуск" systemctl is-enabled --quiet report-gen
check "служба по-прежнему работает от пользователя report" test "$(systemctl show -p User --value report-gen)" = report
check_not "каталог /var/lib/report-gen не открыт на запись всем" \
  bash -c '[ -n "$(find /var/lib/report-gen -maxdepth 0 -perm -o+w)" ]'
check "отчёт обновляется: last-report.txt моложе минуты" \
  bash -c '[ -n "$(find /var/lib/report-gen/last-report.txt -mmin -1 2>/dev/null)" ]'

J=$(ls -d /var/log/journal/*/ 2>/dev/null | head -1)
check "журнал systemd пишется на диск (/var/log/journal/…/system.journal)" test -f "${J}system.journal"

# syslog-ng: свежее сообщение службы должно попасть в отдельный файл.
TAG="chk-$RANDOM$RANDOM"
logger -t report-gen "проверка $TAG"
sleep 2
check "сообщения report-gen попадают в /var/log/report-gen.log" grep -q "$TAG" /var/log/report-gen.log
check_not "в /var/log/report-gen.log нет сообщений других программ" \
  bash -c "logger -t other-app 'чужое $TAG'; sleep 2; grep -q 'чужое $TAG' /var/log/report-gen.log"
check "конфигурация syslog-ng без ошибок (syslog-ng -s)" syslog-ng -s

# logrotate: разбор пробного запуска и настоящая ротация копии настроек на временном файле.
D=$(logrotate -d /etc/logrotate.conf 2>&1 | awk '/^rotating pattern:/{f=/\/var\/log\/report-gen\.log/} f')
check "logrotate знает про /var/log/report-gen.log" test -n "$D"
check "ротация ежедневно" grep -q "after 1 days" <<<"$D"
check "хранится 7 старых файлов" grep -q "(7 rotations)" <<<"$D"
# Блок настроек, где упомянут файл, переносим на временный файл и проверяем поведение.
T=$(mktemp -d)
F=$(grep -ls '/var/log/report-gen\.log' /etc/logrotate.conf /etc/logrotate.d/* | head -1)
{
  grep -E '^[[:space:]]*(no)?(compress|missingok)[[:space:]]*$' /etc/logrotate.conf
  echo "$T/x.log {"
  awk '/\/var\/log\/report-gen\.log/{f=1} f{print} f&&/^[[:space:]]*}/{exit}' "$F" 2>/dev/null \
    | sed -e '0,/{/d' -e '/^[[:space:]]*\(postrotate\|prerotate\|firstaction\|lastaction\)/,/endscript/d' \
    | grep -vE '^[[:space:]]*(olddir|su|create|dateext|dateformat)([[:space:]]|$)'
} > "$T/conf"
check "ротация не падает, если файла нет (missingok)" logrotate -s "$T/state" "$T/conf"
echo a > "$T/x.log"; logrotate -f -s "$T/state" "$T/conf" >/dev/null 2>&1
echo b > "$T/x.log"; logrotate -f -s "$T/state" "$T/conf" >/dev/null 2>&1
check "старые файлы сжимаются" bash -c "ls $T/x.log*.gz"
rm -rf "$T"
finish
