#!/bin/sh
# Сеть компьютера ученика: шлюз и DNS — роутер 192.168.10.1.
# Учебные сети внутренние, поэтому Docker не задаёт шлюз сам.
sudo ip route replace default via 192.168.10.1
lab reset --quiet
mkdir -p "$HOME/answers" "$HOME/captures"
exec sleep infinity
