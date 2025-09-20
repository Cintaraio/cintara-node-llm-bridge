FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root
ENV CHAIN_ID=cintara_11001-1
ENV MONIKER=cintara-docker-node

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    jq \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Go
RUN wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz && \
    rm go1.21.6.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/root/go"
ENV GOBIN="/root/go/bin"

# Clone and build Cintara
RUN git clone https://github.com/Cintaraio/cintara.git /root/cintara && \
    cd /root/cintara && \
    make install

# Create working directory
WORKDIR /root

# Copy initialization script
COPY init-node.sh /root/init-node.sh
RUN chmod +x /root/init-node.sh

# Create data directory
RUN mkdir -p /root/.cintarad

# Expose ports
EXPOSE 26656 26657 1317 9090

# Initialize and start node
CMD ["/root/init-node.sh"]