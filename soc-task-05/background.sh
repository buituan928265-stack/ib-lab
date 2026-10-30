#!/bin/bash
# Готовит учебный SIEM: клонирует репозиторий, поднимает OpenSearch и загружает журналы.
set -x
REPO="https://github.com/buituan928265-stack/soc-lab.git"
for i in $(seq 1 60); do docker info >/dev/null 2>&1 && break; sleep 2; done
if ! docker compose version >/dev/null 2>&1; then
  apt-get update -qq && apt-get install -y -qq docker-compose-plugin || apt-get install -y -qq docker-compose-v2
fi
sysctl -w vm.max_map_count=262144
git clone --depth 1 "$REPO" /root/soc-lab
cd /root/soc-lab
# Интерфейс SIEM открываем через прокси Killercoda, поэтому слушаем не только 127.0.0.1.
sed -i 's/127.0.0.1:5601:5601/5601:5601/' compose.yaml
docker compose up -d --build
# loader завершается после загрузки журналов и настройки правил Sigma
for i in $(seq 1 450); do
  [ "$(docker compose ps -a --format '{{.State}}' loader)" = "exited" ] && break; sleep 2
done
for i in $(seq 1 90); do curl -s -o /dev/null http://127.0.0.1:5601/api/status && break; sleep 2; done
touch /tmp/lab-ready
