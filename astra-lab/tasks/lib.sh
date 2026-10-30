# Общие функции проверок. Подключение: . /opt/astra/tasks/lib.sh
FAILS=0
ok()   { echo "OK:   $*"; }
fail() { echo "FAIL: $*"; FAILS=$((FAILS+1)); }
# check "описание" команда... — OK, если команда успешна
check()    { local d=$1; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else fail "$d"; fi; }
# check_not "описание" команда... — OK, если команда завершилась ошибкой
check_not(){ local d=$1; shift; if "$@" >/dev/null 2>&1; then fail "$d"; else ok "$d"; fi; }
as()       { local u=$1; shift; su -s /bin/bash "$u" -c "$*"; }
finish()   { [ "$FAILS" -eq 0 ]; }
ensure_user()  { id "$1" >/dev/null 2>&1 || useradd -m -s /bin/bash "$1"; }
ensure_group() { getent group "$1" >/dev/null || groupadd "$1"; }
