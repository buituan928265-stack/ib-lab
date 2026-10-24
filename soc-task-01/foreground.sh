clear
echo "Готовлю учебный SIEM: скачиваю образы и загружаю журналы. Первый запуск — 5–10 минут..."
while [ ! -f /tmp/lab-ready ]; do sleep 3; done
cd /root/ib-lab/soc-lab
clear
docker compose logs loader | tail -n 3
echo
echo "Учебный SIEM готов. Рабочее место аналитика:"
echo
echo "    docker compose exec analyst bash"
echo
