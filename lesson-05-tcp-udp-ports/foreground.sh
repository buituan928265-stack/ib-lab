clear
echo "Готовлю учебную лабораторию. Первый запуск занимает 3–5 минут..."
while [ ! -f /tmp/lab-ready ]; do sleep 2; done
cd /root/ib-lab/lab
clear
echo "Лаборатория готова. Войдите в учебный компьютер:"
echo
echo "    docker compose exec student bash"
echo
