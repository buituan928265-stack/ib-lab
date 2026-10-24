#!/bin/bash
# Готовит учебную лабораторию: клонирует репозиторий и поднимает учебные компьютеры.
set -x
REPO="https://github.com/buituan928265-stack/ib-lab.git"
for i in $(seq 1 60); do docker info >/dev/null 2>&1 && break; sleep 2; done
if ! docker compose version >/dev/null 2>&1; then
  apt-get update -qq && apt-get install -y -qq docker-compose-plugin || apt-get install -y -qq docker-compose-v2
fi
# Docker 28+ отбрасывает пакеты к контейнеру из «чужой» сети ещё на хосте (правила raw PREROUTING
# для мостов). Наш учебный роутер маршрутизирует как раз такие пакеты, поэтому мостовой трафик
# не пропускаем через iptables хоста; изоляцию обеспечивает сам учебный роутер.
sysctl -w net.bridge.bridge-nf-call-iptables=0
git clone --depth 1 "$REPO" /root/ib-lab
cd /root/ib-lab/lab
docker compose up -d --build
for i in $(seq 1 90); do docker compose exec -T student true >/dev/null 2>&1 && break; sleep 2; done
touch /tmp/lab-ready
