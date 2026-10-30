#!/bin/bash
. /opt/astra/tasks/lib.sh
cd /
# mkdeb имя версия "зависимости" "описание" — собрать простой пакет в /srv/debs
mkdeb() {
  local n=$1 v=$2 dep=$3 desc=$4 b; b=$(mktemp -d)
  mkdir -p "$b/DEBIAN" "$b/usr/share/$n"
  { echo "Package: $n"; echo "Version: $v"; echo "Architecture: all"
    echo "Maintainer: Astra Lab <lab@example.com>"; [ -n "$dep" ] && echo "Depends: $dep"
    echo "Description: $desc"; } > "$b/DEBIAN/control"
  echo "$n $v" > "$b/usr/share/$n/VERSION"
  dpkg-deb --root-owner-group -b "$b" "/srv/debs/${n}_${v}_all.deb" >/dev/null
  rm -rf "$b"
}
if [ "$1" = "--reset" ]; then
  dpkg --purge corp-agent corp-common >/dev/null 2>&1
  grep -l "/srv/repo" /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources /etc/apt/sources.list 2>/dev/null | while read -r f; do
    [ "$f" = /etc/apt/sources.list ] && sed -i '\|/srv/repo|d' "$f" || rm -f "$f"; done
  rm -rf /srv/repo /srv/debs
  apt-get update >/dev/null 2>&1 || true
fi
if [ ! -d /srv/debs ]; then
  mkdir -p /srv/debs
  mkdeb corp-common 1.0 "" "Common files for the corporate agent"
  mkdeb corp-agent 2.1 "corp-common (>= 1.0)" "Corporate monitoring agent"
fi
true
