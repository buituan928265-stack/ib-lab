#!/bin/bash
. /opt/astra/tasks/lib.sh
check "файлы sudoers проходят visudo -c" visudo -c
check "файл /etc/sudoers не изменён" md5sum -c --status /var/lib/astra-lab/sudoers.md5
check "правило для dezhurny лежит в /etc/sudoers.d/" bash -c "grep -ls dezhurny /etc/sudoers.d/* | grep -q ."
check_not "dezhurny не в группах sudo и root" bash -c "id -nG dezhurny | grep -qwE 'sudo|root'"
check "dezhurny перезапускает cron без пароля" as dezhurny "sudo -n systemctl restart cron"
check_not "dezhurny не может остановить cron" as dezhurny "sudo -n systemctl stop cron"
check_not "dezhurny не может перезапустить другую службу" as dezhurny "sudo -n systemctl restart ssh"
check_not "dezhurny не может запустить оболочку" as dezhurny "sudo -n /bin/bash -c true"
check_not "dezhurny не может читать /etc/shadow" as dezhurny "sudo -n cat /etc/shadow"
systemctl is-active -q cron || systemctl start cron >/dev/null 2>&1
finish
