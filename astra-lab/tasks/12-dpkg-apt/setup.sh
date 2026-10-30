#!/bin/bash
. /opt/astra/tasks/lib.sh
cd /
mkdeb() {  # имя версия "зависимости" каталог [conffile]
  local n=$1 v=$2 dep=$3 out=$4 conf=$5 b; b=$(mktemp -d)
  mkdir -p "$b/DEBIAN" "$b/usr/share/$n"
  { echo "Package: $n"; echo "Version: $v"; echo "Architecture: all"
    echo "Maintainer: Astra Lab <lab@example.com>"; [ -n "$dep" ] && echo "Depends: $dep"
    echo "Description: Training package $n"; } > "$b/DEBIAN/control"
  echo "$n $v" > "$b/usr/share/$n/VERSION"
  if [ -n "$conf" ]; then
    mkdir -p "$b/etc"; echo "server=10.0.0.5" > "$b$conf"; echo "$conf" > "$b/DEBIAN/conffiles"
  fi
  dpkg-deb --root-owner-group -b "$b" "$out/${n}_${v}_all.deb" >/dev/null
  rm -rf "$b"
}
if [ "$1" = "--reset" ]; then
  dpkg --purge report-tool report-lib old-agent >/dev/null 2>&1
  apt-mark unhold openssh-server >/dev/null 2>&1
  rm -f /root/paket.txt /etc/old-agent.conf; rm -rf /root/pkgs
fi
if [ ! -d /root/pkgs ]; then
  mkdir -p /root/pkgs
  mkdeb report-lib 1.0 "" /root/pkgs
  mkdeb report-tool 1.0 "report-lib (>= 1.0)" /root/pkgs
fi
if ! dpkg-query -W old-agent >/dev/null 2>&1 && [ "$1" = "--reset" -o ! -f /var/lib/astra-lab/12-dpkg-apt.done ]; then
  T=$(mktemp -d); mkdeb old-agent 0.9 "" "$T" /etc/old-agent.conf
  dpkg -i "$T"/old-agent_0.9_all.deb >/dev/null 2>&1; rm -rf "$T"
  mkdir -p /var/lib/astra-lab; touch /var/lib/astra-lab/12-dpkg-apt.done
fi
true
