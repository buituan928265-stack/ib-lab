#!/bin/bash
. /opt/astra/tasks/lib.sh
S=/usr/local/bin/cleanlogs
if [ ! -f $S ]; then fail "скрипт $S не найден"; finish; exit; fi
check "скрипт исполняемый" test -x $S
run() { OUT=$("$@" 2>/tmp/.cl_err); RC=$?; ERR=$(cat /tmp/.cl_err); rm -f /tmp/.cl_err; }
# mk каталог — набор файлов: 6 журналов разного возраста, один с пробелом, плюс посторонние файлы
mk() {
  rm -rf "$1"; mkdir -p "$1/old"
  local i=1
  for f in "app 1.log" app2.log app3.log app4.log app5.log app6.log; do
    echo x > "$1/$f"; touch -d "$i days ago" "$1/$f"; i=$((i+1))
  done
  echo x > "$1/notes.txt"; touch -d "30 days ago" "$1/notes.txt"
  echo x > "$1/app.log.gz"; touch -d "40 days ago" "$1/app.log.gz"
  echo x > "$1/old/arch.log"; touch -d "50 days ago" "$1/old/arch.log"
}
left() { (cd "$1" && find . -type f | sed 's|^\./||' | LC_ALL=C sort | tr '\n' '|'); }
T=$(mktemp -d)
mk "$T/a"; run $S "$T/a" 2
check "N=2: остались 2 самых новых .log и все посторонние файлы" test "$(left "$T/a")" = "app 1.log|app.log.gz|app2.log|notes.txt|old/arch.log|"
check "N=2: вывод «Удалено: 4», код 0" test "$(tail -1 <<< "$OUT")" = "Удалено: 4" -a "$RC" = 0
mk "$T/b"; touch -d "100 days ago" "$T/b/app 1.log"; run $S "$T/b" 3
check "N=3: удалён старый файл с пробелом в имени, свежие на месте" test "$(left "$T/b")" = "app.log.gz|app2.log|app3.log|app4.log|notes.txt|old/arch.log|"
check "N=3: вывод «Удалено: 3»" test "$(tail -1 <<< "$OUT")" = "Удалено: 3"
mk "$T/c"; run $S "$T/c" 10
check "N=10 (больше, чем файлов): ничего не удалено, «Удалено: 0»" test "$(left "$T/c")" = "app 1.log|app.log.gz|app2.log|app3.log|app4.log|app5.log|app6.log|notes.txt|old/arch.log|" -a "$(tail -1 <<< "$OUT")" = "Удалено: 0"
mk "$T/d"; run $S "$T/d" 0
check "N=0: удалены все .log верхнего уровня, подкаталог цел" test "$(left "$T/d")" = "app.log.gz|notes.txt|old/arch.log|" -a "$(tail -1 <<< "$OUT")" = "Удалено: 6"
mk "$T/e"
run $S "$T/e" abc;  check "N=abc: код 2, сообщение в stderr" test "$RC" = 2 -a -n "$ERR"
run $S "$T/e" -1;   check "N=-1: код 2" test "$RC" = 2
run $S "$T/e" 2.5;  check "N=2.5: код 2" test "$RC" = 2
run $S "$T/e";      check "один аргумент: код 2" test "$RC" = 2
run $S "$T/e" 1 2;  check "три аргумента: код 2" test "$RC" = 2
run $S "$T/net" 2;  check "нет каталога: код 1, сообщение в stderr" test "$RC" = 1 -a -n "$ERR"
run $S "$T/e/notes.txt" 2; check "файл вместо каталога: код 1" test "$RC" = 1
check "при ошибках ничего не удалено" test "$(left "$T/e")" = "app 1.log|app.log.gz|app2.log|app3.log|app4.log|app5.log|app6.log|notes.txt|old/arch.log|"
mkdir -p "$T/пустой"; run $S "$T/пустой" 3
check "пустой каталог: «Удалено: 0», код 0" test "$(tail -1 <<< "$OUT")" = "Удалено: 0" -a "$RC" = 0
rm -rf "$T"
finish
