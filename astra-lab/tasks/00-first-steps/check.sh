#!/bin/bash
. /opt/astra/tasks/lib.sh
SRC=/srv/office/archive/2026/notes/start-here.txt
D=/root/practice
check "каталог $D создан" test -d $D
check "файл start-here.txt скопирован в $D" test -f $D/start-here.txt
check "копия совпадает с исходной запиской" cmp -s $SRC $D/start-here.txt
check "файл $D/answer.txt создан" test -f $D/answer.txt
check "в answer.txt записано верное кодовое слово" test "$(cat $D/answer.txt 2>/dev/null | tr -d ' \t\r' | grep -v '^$')" = "kedr-17"
finish
