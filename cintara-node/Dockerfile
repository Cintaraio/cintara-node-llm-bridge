FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV CHAIN_ID=cintara_11001-1
ENV MONIKER=cintara-docker-node

# Install dependencies - exactly as per official guide
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    bash \
    wget \
    unzip \
    build-essential \
    git \
    sudo \
    expect \
    coreutils \
    && rm -rf /var/lib/apt/lists/*

# Create cintara user with sudo privileges - as per official guide
RUN useradd -ms /bin/bash cintara && \
    echo "cintara ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to cintara user
USER cintara
WORKDIR /home/cintara

# Clone the official cintara-testnet-script repository
RUN git clone https://github.com/Cintaraio/cintara-testnet-script.git

# Set working directory to the cloned repository
WORKDIR /home/cintara/cintara-testnet-script

# Make the setup script executable
RUN chmod +x cintara_ubuntu_node.sh

# Create data directory for blockchain data
RUN mkdir -p /home/cintara/data

# Switch back to root to copy files and set permissions
USER root

# Create /data directory that the script expects and set permissions
RUN mkdir -p /data && \
    chown cintara:cintara /data && \
    chmod 755 /data

# Copy our initialization scripts
COPY init-node.sh /home/cintara/init-node.sh
COPY entrypoint.sh /entrypoint.sh

# Set correct ownership and permissions
RUN chown cintara:cintara /home/cintara/init-node.sh && \
    chmod +x /home/cintara/init-node.sh && \
    chmod +x /entrypoint.sh

# Switch back to cintara user for non-privileged operations
USER cintara
WORKDIR /home/cintara

# Expose required ports
EXPOSE 26656 26657 1317 9090

# Use root entrypoint to handle permissions, then switch to cintara user
USER root
CMD ["/entrypoint.sh"]