#!/bin/bash
. /opt/astra/tasks/lib.sh
D=/srv/office/archive/2026/notes
if [ "$1" = "--reset" ]; then
  rm -rf /root/practice /srv/office
fi
if [ ! -f $D/start-here.txt ]; then
  mkdir -p $D /srv/office/archive/2025 /srv/office/docs
  echo "Это не та записка. Ищите дальше." > /srv/office/docs/readme.txt
  cat > $D/start-here.txt <<'TXT'
Привет! Вы нашли записку.
Кодовое слово: kedr-17
Запишите его в /root/practice/answer.txt и запустите astra check 00-first-steps.
TXT
fi
true
