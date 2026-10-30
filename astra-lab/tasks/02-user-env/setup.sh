#!/bin/bash
. /opt/astra/tasks/lib.sh
ensure_user smirnov; ensure_user petrova
mkdir -p /opt/uchet/bin /var/log/uchet
cat > /opt/uchet/bin/uchetctl <<'S'
#!/bin/bash
echo "uchet: служба работает, каталог ${UCHET_HOME:-не задан}"
S
chmod 755 /opt/uchet/bin/uchetctl
if [ "$1" = "--reset" ] || [ ! -s /var/log/uchet/uchet.log ]; then
  for i in $(seq 1 60); do
    printf '2026-10-30 09:%02d:00 INFO запись %d обработана\n' $((i % 60)) "$i"
  done > /var/log/uchet/uchet.log
  chmod 644 /var/log/uchet/uchet.log
fi
if [ "$1" = "--reset" ]; then
  for u in smirnov petrova; do
    for f in .bashrc .profile .bash_logout; do cp /etc/skel/$f /home/$u/$f; chown $u:$u /home/$u/$f; done
    rm -f /home/$u/.bash_profile /home/$u/.bash_login /home/$u/.bash_aliases
  done
  rm -f /etc/profile.d/*uchet*
  sed -i '/uchet/d' /etc/bash.bashrc /etc/profile /etc/environment 2>/dev/null
fi
true
