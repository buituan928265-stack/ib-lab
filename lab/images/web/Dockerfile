FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 iproute2 iptables \
 && rm -rf /var/lib/apt/lists/*
COPY certs/portal.crt certs/portal.key /etc/lab-tls/
COPY images/web/server.py /srv/server.py
COPY images/web/entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
