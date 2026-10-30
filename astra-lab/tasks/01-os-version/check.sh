#!/bin/bash
. /opt/astra/tasks/lib.sh
F=/root/version.txt
if [ ! -f $F ]; then fail "файл $F не найден"; finish; exit; fi
OS=$(. /etc/os-release; echo "$PRETTY_NAME")
K=$(uname -r)
# Убираем \r (файл могли набрать в Windows) и пробелы в конце строк
T=$(tr -d '\r' < $F | sed 's/[[:space:]]*$//' | grep -v '^$')
check "в файле ровно две непустые строки" test "$(printf '%s\n' "$T" | wc -l)" -eq 2
check "строка os= совпадает с PRETTY_NAME из /etc/os-release" grep -qxF "os=$OS" <<< "$T"
check "строка kernel= совпадает с выводом uname -r" grep -qxF "kernel=$K" <<< "$T"
finish
