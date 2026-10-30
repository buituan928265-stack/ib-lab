#!/bin/bash
. /opt/astra/tasks/lib.sh
ensure_group proekt
for u in rukovod inzhener1 inzhener2 auditor; do ensure_user "$u"; done
usermod -aG proekt inzhener1; usermod -aG proekt inzhener2; usermod -aG proekt rukovod
mkdir -p /backup /var/lib/astra-lab
# Снимок: владельцы, права и ACL всех объектов, в стабильном порядке
snap() { (cd "$1" && find . -printf '%p %u %g %m\n' | sort && find . -print0 | sort -z | xargs -0 getfacl -p 2>/dev/null); }
mk_tree() {  # $1 — каталог
  local D=$1
  rm -rf "$D"; mkdir -p "$D/docs" "$D/chertezhi"
  echo "План работ" > "$D/docs/plan.txt"
  echo "Смета" > "$D/docs/smeta.txt"
  echo "Договор" > "$D/docs/dogovor.txt"
  echo "Чертёж 1" > "$D/chertezhi/ch1.dwg"
  chown -R rukovod:proekt "$D"
  chown inzhener1 "$D/chertezhi/ch1.dwg"
  chmod 2770 "$D" "$D/docs" "$D/chertezhi"
  chmod 640 "$D"/docs/*.txt "$D/chertezhi/ch1.dwg"
  chmod 600 "$D/docs/dogovor.txt"
  setfacl -m u:auditor:rx "$D" "$D/docs"
  setfacl -m u:auditor:r "$D/docs/plan.txt" "$D/docs/smeta.txt"
  setfacl -m d:g:proekt:rwX "$D/docs" "$D/chertezhi"
  setfacl -m u:inzhener2:rw "$D/chertezhi/ch1.dwg"
}
if [ "$1" = "--reset" ] || [ ! -d /srv/proekt ]; then
  rm -f /backup/proekt.tar.xz
  mk_tree /srv/proekt
  snap /srv/proekt > /var/lib/astra-lab/proekt.ref
fi
if [ "$1" = "--reset" ] || [ ! -f /backup/arhiv-2026-09.tar.gz ]; then
  mk_tree /srv/arhiv
  echo "Отчёт за сентябрь" > /srv/arhiv/docs/otchet-09.txt
  chown rukovod:proekt /srv/arhiv/docs/otchet-09.txt; chmod 640 /srv/arhiv/docs/otchet-09.txt
  setfacl -m u:auditor:r /srv/arhiv/docs/otchet-09.txt
  snap /srv/arhiv > /var/lib/astra-lab/arhiv.ref
  tar --acls --xattrs -czf /backup/arhiv-2026-09.tar.gz -C / srv/arhiv
  rm -rf /srv/arhiv
fi
[ "$1" = "--reset" ] && rm -rf /srv/arhiv
true
