#!/bin/bash
# Собирает учебную машину (Debian 12 + systemd) и готовит задание.
set -x
REPO="https://github.com/buituan928265-stack/astra-lab.git"
for i in $(seq 1 60); do docker info >/dev/null 2>&1 && break; sleep 2; done
git clone --depth 1 "$REPO" /root/astra-lab
cd /root/astra-lab
docker build -t astra-lab .
docker run -d --name astra-lab --hostname astra-lab --privileged --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw --tmpfs /run --tmpfs /run/lock astra-lab
for i in $(seq 1 60); do
  s=$(docker exec astra-lab systemctl is-system-running 2>/dev/null); [ "$s" = running ] || [ "$s" = degraded ] && break; sleep 2
done
docker exec astra-lab astra task 06-new-staff >/dev/null 2>&1
printf '#!/bin/bash
exec docker exec -it astra-lab bash -l
' > /usr/local/bin/lab && chmod +x /usr/local/bin/lab
touch /tmp/lab-ready
