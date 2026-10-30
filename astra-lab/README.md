# Учебная машина тренажёра «Экзамен администратора Astra Linux»

Debian 12 с systemd: на нём построена Astra Linux 1.8, команды администратора совпадают. Внутри 24 задания с автопроверкой.
Курс неофициальный и не связан с ГК «Астра».

## В браузере (Killercoda)

Откройте ссылку на задание из курса на Stepik и зарегистрируйтесь на Killercoda (бесплатно). Учебная машина соберётся сама за 3–5 минут.

## На своём компьютере (Docker)

Нужен Docker Desktop (Windows, macOS) или Docker Engine (Linux). Откройте терминал в этой папке и выполните:

    docker build -t astra-lab .
    docker run -d --name astra-lab --privileged --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw --tmpfs /run --tmpfs /run/lock astra-lab
    docker exec -it astra-lab bash -l

В Git Bash на Windows перед `docker run` выполните `export MSYS_NO_PATHCONV=1`.

Внутри машины:

    astra list           # список заданий
    astra task ID        # условие задания
    astra check ID       # проверка и код для Stepik
    astra reset ID       # начать задание заново

Задания 13 и 14 создают учебные диски (loop-устройства). Закончив с ними, выполните `astra reset` и удалите контейнер: `docker rm -f astra-lab`.

## На настоящей Astra (по желанию)

Официальный контейнер Astra Linux каждый скачивает сам, для собственного обучения:

    docker pull registry.astralinux.ru/library/astra/ubi18:latest

Мандатный доступ и systemd в контейнере Astra не работают. Подробнее — в модуле 00 курса.
