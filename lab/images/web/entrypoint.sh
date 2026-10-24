#!/bin/sh
set -e
# Маршрут по умолчанию от Docker ведёт в интернет — заменяем его учебным шлюзом
# или убираем совсем: лаборатория изолирована
if [ -n "$GATEWAY" ]; then
  ip route replace default via "$GATEWAY"
else
  ip route del default 2>/dev/null || true
fi
# archive.test не отвечает на ping, хотя веб-сервис на нём работает (урок 08)
if [ "$ROLE" = "archive" ]; then
  iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
fi
exec python3 -u /srv/server.py
