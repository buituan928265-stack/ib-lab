#!/bin/bash
. /opt/astra/tasks/lib.sh
D=/srv/otdel
if [ ! -d $D ]; then fail "каталог $D не найден"; finish; exit; fi
check "владелец root, группа otdel" test "$(stat -c '%U:%G' $D)" = "root:otdel"
check "на каталоге стоит SGID" test -g $D
A=$(stat -c '%a' $D)
check "остальным доступ закрыт (последняя цифра прав 0)" test "${A: -1}" = 0
check_not "smirnov не видит содержимое" as smirnov "ls $D"
rm -f $D/.chk_i $D/.chk_p
check "ivanova создаёт файл" as ivanova "touch $D/.chk_i"
check "новый файл получает группу otdel" test "$(stat -c '%G' $D/.chk_i 2>/dev/null)" = "otdel"
check "petrov дописывает в файл ivanova" as petrov "echo x >> $D/.chk_i"
check "petrov создаёт файл" as petrov "touch $D/.chk_p"
check "ivanova дописывает в файл petrov" as ivanova "echo x >> $D/.chk_p"
as ivanova "mkdir -p $D/.chk_dir" >/dev/null 2>&1
check "новый подкаталог тоже получает группу otdel" test "$(stat -c '%G' $D/.chk_dir 2>/dev/null)" = "otdel"
rm -rf $D/.chk_i $D/.chk_p $D/.chk_dir
finish
