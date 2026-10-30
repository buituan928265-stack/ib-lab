#!/bin/bash
. /opt/astra/tasks/lib.sh
if [ "$1" = "--reset" ]; then
  for u in sidorova kuznetsov ivanov_old; do userdel -r "$u" >/dev/null 2>&1; rm -rf "/home/$u"; done
  groupdel kadry >/dev/null 2>&1
  rm -f /etc/skel/PRAVILA.txt
fi
if ! id ivanov_old >/dev/null 2>&1; then
  useradd -m -s /bin/bash -c "Иванов (уволен)" ivanov_old
  echo 'ivanov_old:Old_Pa55word' | chpasswd
  echo "Документы отдела" > /home/ivanov_old/dela.txt; chown ivanov_old: /home/ivanov_old/dela.txt
fi
true
