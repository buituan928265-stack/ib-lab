#!/bin/bash
# Скрипты резервной копии и очистки есть, но расписаний для них нет.
. /opt/astra/tasks/lib.sh
ensure_user backup
mkdir -p /srv/backup /srv/upload
chown backup:backup /srv/backup

cat > /usr/local/bin/backup-db.sh <<'S'
#!/bin/bash
# Учебная «резервная копия»: архив нескольких файлов из /etc.
tar -czf "/srv/backup/db-$(date +%F_%H%M).tar.gz" -C /etc hostname hosts 2>/dev/null
echo "$(date '+%F %T') копия создана"
S
cat > /usr/local/bin/clean-upload.sh <<'S'
#!/bin/bash
# Удаляет из /srv/upload файлы старше 7 дней.
find /srv/upload -type f -mtime +7 -print -delete
S
chmod 755 /usr/local/bin/backup-db.sh /usr/local/bin/clean-upload.sh

if [ "$1" = "--reset" ]; then
  crontab -r -u backup 2>/dev/null
  systemctl disable --now clean-upload.timer 2>/dev/null
  rm -f /etc/systemd/system/clean-upload.timer /etc/systemd/system/clean-upload.service
  rm -f /etc/systemd/system/timers.target.wants/clean-upload.timer
  rm -f /srv/backup/* /var/log/backup-db.log
  systemctl daemon-reload
fi
true
