clear
echo "Собираю учебную машину Debian 12 и готовлю задание. Первый запуск — 3–5 минут..."
while [ ! -f /tmp/lab-ready ]; do sleep 3; done
clear
echo "Учебная машина готова. Войдите в неё командой:"
echo
echo "    lab"
echo
