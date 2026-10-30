#!/bin/bash
. /opt/astra/tasks/lib.sh

# 1–2. Интерфейс, адрес и маршрут — сейчас в системе.
check "интерфейс lab0 существует" ip link show lab0
check "у lab0 адрес 10.20.0.1/24" bash -c 'ip -4 -o addr show dev lab0 | grep -q "inet 10\.20\.0\.1/24 "'
check "сеть 10.30.0.0/16 доступна через 10.20.0.254 на lab0" \
  bash -c 'ip route get 10.30.7.7 | grep -q "via 10\.20\.0\.254 dev lab0"'
check "остальной трафик по-прежнему идёт не через lab0" bash -c '! ip route get 8.8.8.8 | grep -q "dev lab0"'

# То же самое сохранено в подключении NetworkManager (переживёт перезагрузку).
C=$(nmcli -g UUID,DEVICE con show 2>/dev/null | awk -F: '$2=="lab0"{print $1; exit}')
[ -z "$C" ] && for u in $(nmcli -g UUID con show 2>/dev/null); do
  [ "$(nmcli -g connection.interface-name con show "$u")" = lab0 ] && { C=$u; break; }
done
check "есть подключение NetworkManager для lab0" test -n "$C"
check "в подключении задан адрес 10.20.0.1/24" bash -c '[ -n "$1" ] && nmcli -g ipv4.addresses con show "$1" | grep -q "10\.20\.0\.1/24"' _ "$C"
check "в подключении задан маршрут 10.30.0.0/16 через 10.20.0.254" \
  bash -c '[ -n "$1" ] && nmcli -g ipv4.routes con show "$1" | grep -q "10\.30\.0\.0/16 10\.20\.0\.254"' _ "$C"
check "подключение включается автоматически" bash -c '[ -n "$1" ] && [ "$(nmcli -g connection.autoconnect con show "$1")" = yes ]' _ "$C"

# 3. Имя repo.lab.
check "имя repo.lab указывает на 10.20.0.5" bash -c 'getent ahostsv4 repo.lab | head -1 | grep -q "^10\.20\.0\.5[[:space:]]"'
check "имя repo (короткое) тоже указывает на 10.20.0.5" bash -c 'getent ahostsv4 repo | head -1 | grep -q "^10\.20\.0\.5[[:space:]]"'

# 4. Порт SSH.
REAL=$(ss -Htlnp 2>/dev/null | awk '/"sshd"/{n=split($4,a,":"); print a[n]; exit}')
check "в /root/ssh-port.txt записан порт, который слушает sshd" test "$(cat /root/ssh-port.txt 2>/dev/null | tr -d ' \n')" = "$REAL"
finish
