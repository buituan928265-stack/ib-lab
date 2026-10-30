#!/bin/bash
. /opt/astra/tasks/lib.sh
L=/var/lib/astra-lab
# Снимок: владельцы, права и ACL всех объектов, в стабильном порядке
snap() { (cd "$1" && find . -printf '%p %u %g %m\n' | sort && find . -print0 | sort -z | xargs -0 getfacl -p 2>/dev/null); }
same() { diff -q <(snap "$1") "$2" >/dev/null; }
check "исходный /srv/proekt не изменён" same /srv/proekt $L/proekt.ref
A=/backup/proekt.tar.xz
if [ -f $A ]; then
  check "архив $A сжат xz" bash -c "file -b $A | grep -q '^XZ'"
  T=$(mktemp -d)
  tar --acls --xattrs -xf $A -C "$T" 2>/dev/null
  P=$(find "$T" -type f -path '*/docs/plan.txt' -printf '%h\n' 2>/dev/null | head -1)
  P=${P%/docs}
  if [ -n "$P" ]; then
    check "в архиве все файлы проекта" test -f "$P/docs/dogovor.txt" -a -f "$P/chertezhi/ch1.dwg"
    check "в архиве сохранены владельцы, права и ACL" same "$P" $L/proekt.ref
  else
    fail "в архиве $A не найдены файлы проекта"
  fi
  rm -rf "$T"
else
  fail "архив $A не создан"
fi
if [ -d /srv/arhiv ]; then
  check "/srv/arhiv восстановлен со всеми файлами" test -f /srv/arhiv/docs/otchet-09.txt -a -f /srv/arhiv/chertezhi/ch1.dwg
  check "/srv/arhiv: владельцы и права как до удаления" bash -c "diff -q <(cd /srv/arhiv && find . -printf '%p %u %g %m\n' | sort) <(grep -E '^\.[^ ]* [^ ]+ [^ ]+ [0-7]+$' $L/arhiv.ref)"
  check "/srv/arhiv: ACL как до удаления" same /srv/arhiv $L/arhiv.ref
else
  fail "каталог /srv/arhiv не восстановлен"
fi
finish
