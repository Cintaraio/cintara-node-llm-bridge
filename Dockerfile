FROM ubuntu:22.04
RUN apt-get update && apt-get install -y wget ca-certificates curl jq bash git sudo && rm -rf /var/lib/apt/lists/*

# Create cintara user with specific UID/GID to match host user
RUN groupadd -g 1000 cintara && \
    useradd -u 1000 -g 1000 -ms /bin/bash cintara && \
    echo "cintara ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV CINTARA_HOME=/data/.tmp-cintarad
USER root

# Download cintarad binary
RUN wget -q https://github.com/Cintaraio/cintara-testnet-script/releases/download/ubuntu22.04/cintarad -O /usr/local/bin/cintarad \
 && chmod 0755 /usr/local/bin/cintarad

# Copy genesis file and entrypoint
COPY genesis.json /genesis.json
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && chown cintara:cintara /usr/local/bin/entrypoint.sh /genesis.json

# Create data directory and set permissions
RUN mkdir -p /data && chown -R 1000:1000 /data

USER cintara
EXPOSE 26656 26657
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]