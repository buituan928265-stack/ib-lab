#!/bin/bash
. /opt/astra/tasks/lib.sh
D=/srv/exchange
if [ "$1" = "--reset" ] || [ ! -d $D ]; then
  rm -rf $D /root/big_files.txt
  mkdir -p "$D/otchety/2026" "$D/scan" "$D/obmen ivanova" "$D/arhiv"
  old() { for f in "$@"; do mkdir -p "$(dirname "$f")"; echo "данные" > "$f"; touch -d '20 days ago' "$f"; done; }
  new() { for f in "$@"; do mkdir -p "$(dirname "$f")"; echo "данные" > "$f"; touch -d '2 days ago' "$f"; done; }
  old "$D/1c_export.tmp" "$D/otchety/2026/q3.tmp" "$D/scan/scan_0412.tmp" "$D/obmen ivanova/черновик.tmp"
  new "$D/upload_1.tmp" "$D/scan/scan_0930.tmp"
  old "$D/tmp_notes.txt" "$D/otchety/2026/q3.tmp.bak" "$D/otchety/2026/q3.ods" "$D/arhiv/readme.txt"
  head -c 7M /dev/zero > "$D/scan/scan_full.pdf"
  head -c 12M /dev/zero > "$D/obmen ivanova/video.mp4"
  head -c 9M /dev/zero > "$D/arhiv/base_2025.tar"
  head -c 3M /dev/zero > "$D/otchety/2026/small.pdf"
  ln -s otchety/2026/q3.ods "$D/q3_link.ods"
  ln -s /srv/exchange/arhiv/readme.txt "$D/scan/readme"
  ln -s /srv/old_share/plan.ods "$D/plan.ods"
  ln -s ../nofile.txt "$D/arhiv/nofile.txt"
  ln -s otchety/2025 "$D/otchety_2025"
  chmod -R a+rwX $D
fi
true
