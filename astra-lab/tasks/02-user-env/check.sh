#!/bin/bash
. /opt/astra/tasks/lib.sh
# Команда в оболочке, которую пользователь получает при входе (login + interactive)
login_sh() { su - "$1" -c "bash -lic $(printf %q "$2")" 2>/dev/null; }
id smirnov >/dev/null 2>&1 || { fail "нет пользователя smirnov — выполните astra reset 02-user-env"; finish; exit; }
check "UCHET_HOME=/opt/uchet после входа" test "$(login_sh smirnov 'echo $UCHET_HOME')" = "/opt/uchet"
check "UCHET_HOME видна запущенным программам (export)" test "$(login_sh smirnov 'bash -c "echo \$UCHET_HOME"')" = "/opt/uchet"
check "uchetctl запускается по имени" test "$(login_sh smirnov 'command -v uchetctl')" = "/opt/uchet/bin/uchetctl"
P=$(login_sh smirnov 'echo $PATH')
check "в PATH остались /usr/bin и /bin" bash -c "echo ':$P:' | grep -q ':/usr/bin:' && echo ':$P:' | grep -q ':/bin:'"
check "uchetlog — это псевдоним" bash -c "su - smirnov -c \"bash -lic 'alias uchetlog'\" 2>/dev/null | grep -q uchetlog"
check "uchetlog выводит последние 20 строк журнала" test "$(login_sh smirnov 'uchetlog')" = "$(tail -n 20 /var/log/uchet/uchet.log)"
check_not "у petrova нет UCHET_HOME" test -n "$(login_sh petrova 'echo $UCHET_HOME')"
check_not "у petrova нет псевдонима uchetlog" bash -c "su - petrova -c \"bash -lic 'alias uchetlog'\" 2>/dev/null"
finish
