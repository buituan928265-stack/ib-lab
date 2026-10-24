FROM debian:bookworm-slim
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      sudo bash-completion iproute2 iputils-ping traceroute dnsutils curl \
      netcat-openbsd procps tcpdump openssl ca-certificates python3 nano less git man-db \
 && rm -rf /var/lib/apt/lists/*

# Ученик работает обычным пользователем; sudo — для tcpdump и настроек сети стенда
RUN useradd -m -s /bin/bash student \
 && echo 'student ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/student \
 && chmod 440 /etc/sudoers.d/student

# Учебный удостоверяющий центр: браузер и curl доверяют portal.test без отключения проверок
COPY certs/ca.crt /usr/local/share/ca-certificates/ib-lab-ca.crt
RUN update-ca-certificates

COPY labs /opt/lab/labs
COPY certs/old-portal.crt /opt/lab/labs/06/old-portal.crt
COPY images/student/lab.py /usr/local/bin/lab
COPY images/student/entrypoint.sh /entrypoint.sh
COPY images/student/bashrc.lab /etc/profile.d/lab.sh
RUN sed -i 's/\r$//' /entrypoint.sh /usr/local/bin/lab /etc/profile.d/lab.sh \
 && chmod +x /entrypoint.sh /usr/local/bin/lab \
 && echo '. /etc/profile.d/lab.sh' >> /etc/bash.bashrc

USER student
WORKDIR /home/student
ENTRYPOINT ["/entrypoint.sh"]
