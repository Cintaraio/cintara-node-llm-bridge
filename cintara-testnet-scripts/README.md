# Cintara Testnet Node Setup

<div align="center">
  <img src="https://img.shields.io/badge/Ubuntu-22.04-orange.svg" alt="Ubuntu 22.04">
  <img src="https://img.shields.io/badge/Network-Testnet-blue.svg" alt="Testnet">
  <img src="https://img.shields.io/badge/Status-Active-green.svg" alt="Active">
</div>

This repository provides an automated setup script for running a Cintara blockchain node on the testnet network. The script handles the complete installation and configuration process, making it easy to participate in the Cintara testnet.

## 🔧 System Requirements

Before running the setup script, ensure your system meets the following requirements:

| Component | Minimum Requirement | Recommended |
|-----------|-------------------|-------------|
| **Operating System** | Ubuntu 20.04 or 22.04 | Ubuntu 22.04 LTS |
| **Memory (RAM)** | 4GB | 8GB+ |
| **Storage** | 20GB available | 50GB+ SSD |
| **CPU** | 2 cores | 4+ cores |
| **Network** | Stable internet connection | High-speed broadband |

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Cintaraio/cintara-testnet-script.git
cd cintara-testnet-script
```

### 2. Make the Script Executable

```bash
chmod +x cintara_ubuntu_node.sh
```

### 3. Run the Setup Script

```bash
./cintara_ubuntu_node.sh
```

**Note:** The script will prompt you to enter a name for your node. Choose a unique, memorable name for identification on the network.

### 4. Monitor Your Node

The blockchain will start syncing automatically in the background as a systemd service. You can monitor the progress using:

```bash
# View real-time logs
journalctl -u cintarachain.service -f

# View recent logs
journalctl -u cintarachain.service -n 100

# Check service status
systemctl status cintarachain.service
```

## 📋 What the Script Does

The setup script automatically handles:

- ✅ **System Dependencies**: Installs required packages (build-essential, jq, wget, unzip)
- ✅ **Go Installation**: Sets up Go programming language environment
- ✅ **Binary Download**: Downloads the appropriate Cintarad binary for your Ubuntu version
- ✅ **Cosmovisor Setup**: Installs and configures Cosmovisor for seamless upgrades
- ✅ **Node Initialization**: Creates and configures your node with genesis file
- ✅ **Key Generation**: Creates validator keys (save the mnemonic securely!)
- ✅ **Network Configuration**: Sets up peer connections and network parameters
- ✅ **Service Creation**: Configures systemd service for automatic startup
- ✅ **Blockchain Sync**: Starts the node and begins syncing with the network

## 🔑 Important Security Notes

### 🚨 Save Your Keys!

During the setup process, the script will generate a mnemonic phrase for your validator keys. **This is critically important:**

1. **Write down the mnemonic phrase** that appears during setup
2. **Store it in a secure location** (offline backup recommended)
3. **Never share your mnemonic** with anyone
4. **You'll need this mnemonic** to restore your validator if needed

### Key Information Displayed

After setup, the script will display:
- **Tendermint Public Key**: Your validator's public key
- **Wallet Address**: Your node's wallet address
- **Node ID**: Your node's unique identifier

## 🔍 Node Management Commands

### Service Management
```bash
# Start the service
sudo systemctl start cintarachain.service

# Stop the service
sudo systemctl stop cintarachain.service

# Restart the service
sudo systemctl restart cintarachain.service

# Enable auto-start on boot
sudo systemctl enable cintarachain.service

# Disable auto-start
sudo systemctl disable cintarachain.service
```

### Node Information
```bash
# Check node status
cintarad status --home /data/.tmp-cintarad

# View node info
cintarad tendermint show-node-id --home /data/.tmp-cintarad

# Check validator info
cintarad tendermint show-validator --home /data/.tmp-cintarad

# View account balance
cintarad query bank balances [your-address] --home /data/.tmp-cintarad
```

### Logs and Monitoring
```bash
# Real-time logs
journalctl -u cintarachain.service -f

# Logs from last hour
journalctl -u cintarachain.service --since "1 hour ago"

# Export logs to file
journalctl -u cintarachain.service > cintara_logs.txt
```

## 🌐 Network Information

- **Chain ID**: `cintara_11001-1`
- **Token Denom**: `cint`
- **RPC Port**: `26657`
- **API Port**: `1317`
- **P2P Port**: `26656`

## 🛠️ Troubleshooting

### Common Issues

**1. Permission Denied Error**
```bash
chmod +x cintara_ubuntu_node.sh
```

**2. Node Not Syncing**
```bash
# Check if service is running
systemctl status cintarachain.service

# Restart the service
sudo systemctl restart cintarachain.service
```

**3. Disk Space Issues**
```bash
# Check available space
df -h

# Clean up old logs
sudo journalctl --vacuum-time=7d
```

**4. Network Connection Issues**
- Ensure ports 26656, 26657, and 1317 are open
- Check firewall settings
- Verify internet connectivity

### Getting Help

If you encounter issues:

1. **Check the logs** first using `journalctl -u cintarachain.service -f`
2. **Review the error messages** for specific issues
3. **Join the community** for support and discussions
4. **Open an issue** on this repository with detailed error logs

## 📚 Additional Resources

- [Cintara Documentation] (TODO)
- [Cosmos SDK Documentation](https://docs.cosmos.network/)
- [Tendermint Documentation](https://docs.tendermint.com/)

## 🤝 Contributing

We welcome contributions to improve this setup script! Please:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with your improvements

## ⚠️ Disclaimer

This is testnet software. Use at your own risk. Always backup your keys and configuration files. Never use real funds or mainnet keys with testnet software.

---

<div align="center">
  <p><strong>Happy Validating! 🚀</strong></p>
  <p><em>Join the Cintara testnet and help secure the network!</em></p>
</div>