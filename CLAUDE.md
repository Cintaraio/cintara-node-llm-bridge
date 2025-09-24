- I was able to generate the image successfully, however, getting this error during cintara node setup - "23 7.635 Enter the Name for the node:
#23 7.636 ============================================================================================================
#23 7.965 ===========================Copy these keys with mnemonics and save it in safe place ===================================
#23 8.131 password must be at least 8 characters
#23 8.131 password must be at least 8 characters
#23 8.131 EOF
#23 8.131 Error: too many failed passphrase attempts         #23 8.132 too many failed passphrase attempts
#23 8.138 Node will be configured at runtime" - I went ahead and deployed the image on secret network using docker-compose.secretvm-ecr.yml. Secret VM throwing the below error - 📊 Starting all services with supervisor...
Error: Format string 'bash -c \'source /home/cintara/node-config.env 2>/dev/null || true; mkdir -p /data/.tmp-cintarad; chown -R cintara:cintara /data; if command -v cintarad >/dev/null 2>&1 && [ -f "/data/.tmp-cintarad/config/config.toml" ]; then echo "Starting preconfigured node..."; cintarad start --home /data/.tmp-cintarad --rpc.laddr tcp://0.0.0.0:26657 --grpc.address 0.0.0.0:9090 --api.address tcp://0.0.0.0:1317 --api.enable true --log_level info; else echo "Configuring node..."; cd /home/cintara/cintara-testnet-script && source /home/cintara/node-config.env && printf "%sn%sn" "cintara-unified-node" "y" | ./cintara_ubuntu_node.sh && cintarad start --home /data/.tmp-cintarad --rpc.laddr tcp://0.0.0.0:26657 -grpc.address 0.0.0.0:9090 --api.address tcp://0.0.0.0:1317 --api.enable true --log_level info; fi\'' for 'program:cintara-node.command' is badly formatted: not enough arguments for format string in section 'program:cintara-node' (file: '/etc/supervisor/conf.d/supervisord.conf')
For help, use /usr/bin/supervisord -h
- I was able to generate the image successfully, however, getting this error during cintara node setup - "23 7.635 Enter the Name for the node:
#23 7.636 ============================================================================================================
#23 7.965 ===========================Copy these keys with mnemonics and save it in safe place ===================================
#23 8.131 password must be at least 8 characters
#23 8.131 password must be at least 8 characters
#23 8.131 EOF
#23 8.131 Error: too many failed passphrase attempts         #23 8.132 too many failed passphrase attempts
#23 8.138 Node will be configured at runtime" - I went ahead and deployed the image on secret network using docker-compose.secretvm-ecr.yml. Secret VM throwing the below error -" 📊 Starting all services with supervisor...
Error: Format string 'bash -c \'source /home/cintara/node-config.env 2>/dev/null || true; mkdir -p /data/.tmp-cintarad; chown -R cintara:cintara /data; if command -v cintarad >/dev/null 2>&1 && [ -f "/data/.tmp-cintarad/config/config.toml" ]; then echo "Starting preconfigured node..."; cintarad start --home /data/.tmp-cintarad --rpc.laddr tcp://0.0.0.0:26657 --grpc.address 0.0.0.0:9090 --api.address tcp://0.0.0.0:1317 --api.enable true --log_level info; else echo "Configuring node..."; cd /home/cintara/cintara-testnet-script && source /home/cintara/node-config.env && printf "%sn%sn" "cintara-unified-node" "y" | ./cintara_ubuntu_node.sh && cintarad start --home /data/.tmp-cintarad --rpc.laddr tcp://0.0.0.0:26657 -grpc.address 0.0.0.0:9090 --api.address tcp://0.0.0.0:1317 --api.enable true --log_level info; fi\'' for 'program:cintara-node.command' is badly formatted: not enough arguments for format string in section 'program:cintara-node' (file: '/etc/supervisor/conf.d/supervisord.conf')
For help, use /usr/bin/supervisord -h"
- I was able to generate the image successfully, however, getting this error during cintara node setup - "23 7.635 Enter the Name for the node:
#23 7.636 ============================================================================================================
#23 7.965 ===========================Copy these keys with mnemonics and save it in safe place ===================================
#23 8.131 password must be at least 8 characters
#23 8.131 password must be at least 8 characters
#23 8.131 EOF
#23 8.131 Error: too many failed passphrase attempts         #23 8.132 too many failed passphrase attempts
#23 8.138 Node will be configured at runtime" - I went ahead and deployed the image on secret network using docker-compose.secretvm-ecr.yml. Secret VM throwing the below error - 📊 Starting all services with supervisor...
Error: Format string 'bash -c \'source /home/cintara/node-config.env 2>/dev/null || true; mkdir -p /data/.tmp-cintarad; chown -R cintara:cintara /data; if command -v cintarad >/dev/null 2>&1 && [ -f "/data/.tmp-cintarad/config/config.toml" ]; then echo "Starting preconfigured node..."; cintarad start --home /data/.tmp-cintarad --rpc.laddr tcp://0.0.0.0:26657 --grpc.address 0.0.0.0:9090 --api.address tcp://0.0.0.0:1317 --api.enable true --log_level info; else echo "Configuring node..."; cd /home/cintara/cintara-testnet-script && source /home/cintara/node-config.env && printf "%sn%sn" "cintara-unified-node" "y" | ./cintara_ubuntu_node.sh && cintarad start --home /data/.tmp-cintarad --rpc.laddr tcp://0.0.0.0:26657 -grpc.address 0.0.0.0:9090 --api.address tcp://0.0.0.0:1317 --api.enable true --log_level info; fi\'' for 'program:cintara-node.command' is badly formatted: not enough arguments for format string in section 'program:cintara-node' (file: '/etc/supervisor/conf.d/supervisord.conf')
For help, use /usr/bin/supervisord -h