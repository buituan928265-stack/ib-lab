#!/bin/sh
# Шлюз лаборатории: маршрутизация между lan и lan2, NAT в «интернет» (wan)
# и правило, которое выпускает наружу только веб (TCP 80, 443) и ping.
set -e

# Docker даёт маршрут в интернет через свой шлюз — убираем: лаборатория изолирована
ip route del default 2>/dev/null || true

ifname() { ip -o -4 addr show | awk -v ip="$1" '$4 ~ "^"ip"/" {print $2; exit}'; }
LAN=$(ifname 192.168.10.1)
LAN2=$(ifname 192.168.11.1)
WAN=$(ifname 203.0.113.10)

iptables -F
iptables -t nat -F
iptables -P FORWARD DROP
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# Внутренние сети видят друг друга полностью
iptables -A FORWARD -i "$LAN" -o "$LAN2" -j ACCEPT
iptables -A FORWARD -i "$LAN2" -o "$LAN" -j ACCEPT
# Наружу — только нужные сервисы
iptables -A FORWARD -i "$LAN" -o "$WAN" -p tcp -m multiport --dports 80,443 -j ACCEPT
iptables -A FORWARD -i "$LAN" -o "$WAN" -p icmp -j ACCEPT
# NAT: внутренние адреса заменяются внешним адресом шлюза
iptables -t nat -A POSTROUTING -o "$WAN" -j MASQUERADE

echo "router: lan=$LAN lan2=$LAN2 wan=$WAN, правила применены"
exec dnsmasq -k -C /etc/dnsmasq.conf
