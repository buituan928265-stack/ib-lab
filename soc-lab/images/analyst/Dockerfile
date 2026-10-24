FROM debian:bookworm-slim
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 curl jq less nano ca-certificates procps \
 && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash analyst
COPY data /lab/data
COPY labs /opt/soc/labs
COPY sigma /lab/sigma
COPY images/analyst/soc.py /usr/local/bin/soc
COPY images/analyst/bashrc.soc /etc/profile.d/soc.sh
RUN sed -i 's/\r$//' /usr/local/bin/soc /etc/profile.d/soc.sh \
 && chmod +x /usr/local/bin/soc && chmod -R a+rX /lab /opt/soc \
 && echo '. /etc/profile.d/soc.sh' >> /etc/bash.bashrc
USER analyst
WORKDIR /home/analyst
CMD ["sleep", "infinity"]
