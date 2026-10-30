#!/bin/bash
. /opt/astra/tasks/lib.sh
check "в /srv/repo лежат пакеты corp-agent и corp-common" bash -c "ls /srv/repo/corp-agent_*.deb /srv/repo/corp-common_*.deb"
check "в /srv/repo есть индекс Packages" bash -c "{ zcat -f /srv/repo/Packages.gz 2>/dev/null; cat /srv/repo/Packages 2>/dev/null; } | grep -q '^Package: corp-agent'"
check "репозиторий подключён файлом в /etc/apt/sources.list.d/" bash -c "grep -lsE '^[^#]*/srv/repo' /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources | grep -q ."
check "apt видит corp-agent в локальном репозитории" bash -c "apt-cache policy corp-agent 2>/dev/null | grep -q '/srv/repo'"
check "corp-agent установлен" bash -c "dpkg-query -W -f='\${Status}' corp-agent 2>/dev/null | grep -q 'install ok installed'"
check "corp-common установлен" bash -c "dpkg-query -W -f='\${Status}' corp-common 2>/dev/null | grep -q 'install ok installed'"
check "corp-common установлен автоматически, как зависимость" bash -c "apt-mark showauto | grep -qx corp-common"
finish
