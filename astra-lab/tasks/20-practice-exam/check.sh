#!/bin/bash
. /opt/astra/tasks/lib.sh

echo "--- 1. Пользователь и группа"
check "группа smena существует" getent group smena
check "пользователь dezh входит в группу smena" bash -c 'id -nG dezh | grep -qw smena'
check "у dezh оболочка /bin/bash и домашний каталог /home/dezh" \
  bash -c '[ "$(getent passwd dezh | cut -d: -f6,7)" = "/home/dezh:/bin/bash" ] && [ -d /home/dezh ]'

echo "--- 2. Общий каталог"
D=/srv/smena
check "$D: владелец root, группа smena" test "$(stat -c '%U:%G' $D 2>/dev/null)" = root:smena
check "$D: права 2770 (SGID, остальным ничего)" test "$(stat -c '%a' $D 2>/dev/null)" = 2770
rm -f $D/.chk $D/.chk_n
check "dezh создаёт файл в $D, файл получает группу smena" \
  bash -c 'su -s /bin/bash dezh -c "echo t > $1/.chk" && [ "$(stat -c %G $1/.chk)" = smena ]' _ $D

echo "--- 3. ACL"
check "nachalnik видит список файлов в $D" as nachalnik "ls $D"
check "nachalnik читает новый файл в $D" as nachalnik "cat $D/.chk"
check_not "nachalnik не может создавать файлы в $D" as nachalnik "touch $D/.chk_n"
rm -f $D/.chk $D/.chk_n

echo "--- 4. Пакет"
check "пакет exam-agent установлен" bash -c 'dpkg-query -W -f="\${Status}" exam-agent 2>/dev/null | grep -q "install ok installed"'

echo "--- 5. Служба"
check "служба exam-agent включена" systemctl is-enabled --quiet exam-agent.service
check "служба exam-agent работает" systemctl is-active --quiet exam-agent.service
check "служба перезапускается при сбое" \
  bash -c 'case "$(systemctl show -p Restart --value exam-agent.service)" in on-failure|always|on-abnormal) exit 0;; *) exit 1;; esac'
P=$(systemctl show -p MainPID --value exam-agent.service 2>/dev/null)
check "процесс службы работает от пользователя dezh" test "$(ps -o user= -p "${P:-0}" 2>/dev/null | tr -d ' ')" = dezh

echo "--- 6. Расписание"
L=$(crontab -l -u dezh 2>/dev/null | grep -v '^[[:space:]]*#' | grep 'exam-agent --report' | head -1)
read -r MI HO DM MO DW _ <<<"$L"
check "в crontab dezh: exam-agent --report каждый день в 18:00" \
  bash -c '[[ "$1" =~ ^0?0$ && "$2" == 18 && "$3 $4 $5" == "* * *" ]]' _ "$MI" "$HO" "$DM" "$MO" "$DW"

echo "--- 7. Журнал"
A=$(cat /root/exam/journal-code.txt 2>/dev/null | tr -d ' \n')
check "в /root/exam/journal-code.txt записан код смены из журнала" \
  test "$(echo -n "$A" | md5sum | cut -d' ' -f1)" = "$(cat /var/lib/exam/code.md5 2>/dev/null)"

echo "--- 8. Архив"
AR=/root/exam/etc-exam.tar.gz
check "$AR — архив tar, сжатый gzip" bash -c "gzip -t $AR && tar -tzf $AR"
check "в архиве весь каталог etc/exam с подкаталогами" \
  bash -c "tar -tzf $AR | sed 's|^/||' | grep -qx 'etc/exam/app.conf' && tar -tzf $AR | sed 's|^/||' | grep -qx 'etc/exam/conf.d/db.conf'"

echo "--- 9. SUID"
check "в /opt/exam/bin не осталось файлов с SUID" bash -c '[ -d /opt/exam/bin ] && [ -z "$(find /opt/exam/bin -type f -perm -4000)" ]'
check "сами программы не удалены и запускаются" bash -c '/opt/exam/bin/id-copy -u && /opt/exam/bin/date-copy'

echo "--- 10. Скрипт"
S=/usr/local/bin/count-shell.sh
check "$S существует и исполняемый" test -x $S
for sh in /bin/bash /usr/sbin/nologin; do
  want=$(awk -F: -v s="$sh" '$7==s' /etc/passwd | wc -l)
  check "count-shell.sh $sh выводит $want" test "$(as nachalnik "$S $sh" 2>/dev/null | tr -d ' \n')" = "$want"
done
check_not "без аргумента — код возврата не 0" as nachalnik "$S"
check "без аргумента — в stdout пусто, подсказка в stderr" \
  bash -c '[ -x "$1" ] && [ -z "$(su -s /bin/bash nachalnik -c "$1" 2>/dev/null)" ] && [ -n "$(su -s /bin/bash nachalnik -c "$1" 2>&1)" ]' _ $S
finish
