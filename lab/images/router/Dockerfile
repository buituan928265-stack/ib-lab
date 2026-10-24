FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends iproute2 iptables dnsmasq-base \
 && rm -rf /var/lib/apt/lists/*
COPY images/router/dnsmasq.conf /etc/dnsmasq.conf
COPY images/router/entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
