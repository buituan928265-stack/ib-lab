# Учебная машина тренажёра Astra Linux: Debian 12 (основа Astra Linux 1.8) с systemd.
# Служба журналов — syslog-ng, как в Astra Linux SE 1.7/1.8 (rsyslog там вынесен в расширенный репозиторий).
FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive container=docker
RUN apt-get update && apt-get install -y --no-install-recommends \
      systemd systemd-sysv dbus sudo vim nano less man-db bash-completion locales \
      acl attr e2fsprogs xfsprogs btrfs-progs parted fdisk lvm2 cryptsetup udev \
      procps psmisc lsof cron anacron at rsync tar gzip bzip2 xz-utils zstd cpio \
      iproute2 iputils-ping dnsutils net-tools network-manager curl ca-certificates \
      syslog-ng-core logrotate gawk sed grep findutils file tree screen tmux kmod \
      dpkg-dev apt-utils openssh-server \
    && sed -i 's/^# *ru_RU.UTF-8/ru_RU.UTF-8/' /etc/locale.gen && locale-gen \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Не запускать в контейнере службы, которые требуют настоящего железа.
RUN systemctl mask systemd-udevd.service systemd-udevd-kernel.socket systemd-udevd-control.socket \
      getty@.service systemd-logind.service NetworkManager-wait-online.service 2>/dev/null || true

COPY astra /usr/local/bin/astra
COPY tasks /opt/astra/tasks
RUN chmod 755 /usr/local/bin/astra && echo "astra-lab" > /etc/hostname

ENV LANG=ru_RU.UTF-8
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
