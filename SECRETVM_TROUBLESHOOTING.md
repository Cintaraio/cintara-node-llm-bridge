# SecretVM Deployment Troubleshooting Guide

## Issue Summary
Based on your log file, the main issue is that the SecretVM environment is trying to bind mount directories that don't exist on the host system.

## Primary Error
```
Error response from daemon: failed to mount local volume: mount /data/secretvm/supervisor:/mnt/secure/volumes/docker_wd_supervisor_logs_secretvm/_data, flags: 0x1000: no such file or directory
```

## Root Cause
The `docker-compose.secretvm.yml` uses bind mounts that expect these directories to exist:
- `/data/secretvm/cintara`
- `/data/secretvm/home`
- `/data/secretvm/models`
- `/data/secretvm/logs`
- `/data/secretvm/supervisor`
- `/data/secretvm/attestation`

## Solutions (Choose One)

### Solution 1: Create Required Directories (Quick Fix)

```bash
# Run the setup script to create all required directories
./setup-secretvm-dirs.sh

# Then deploy with the original docker-compose
docker-compose -f docker-compose.secretvm.yml up -d
```

### Solution 2: Use Fixed Docker Compose (Recommended)

```bash
# Use the fixed version that doesn't require bind mounts
docker-compose -f docker-compose.secretvm-fixed.yml up -d

# This version uses Docker-managed volumes instead of bind mounts
```

### Solution 3: Manual Directory Setup

```bash
# Create the directories manually
sudo mkdir -p /data/secretvm/{cintara,home,models,logs,supervisor,attestation}
sudo chown -R $USER:$USER /data/secretvm
sudo chmod -R 755 /data/secretvm

# Create subdirectories
mkdir -p /data/secretvm/cintara/{config,data}
mkdir -p /data/secretvm/home/.cintarad
mkdir -p /data/secretvm/logs/{cintara,llama,bridge}

# Then deploy
docker-compose -f docker-compose.secretvm.yml up -d
```

## Verification Steps

1. **Check directories exist:**
   ```bash
   ls -la /data/secretvm/
   ```

2. **Test with fixed compose:**
   ```bash
   docker-compose -f docker-compose.secretvm-fixed.yml config
   ```

3. **Deploy and monitor:**
   ```bash
   docker-compose -f docker-compose.secretvm-fixed.yml up -d
   docker-compose -f docker-compose.secretvm-fixed.yml logs -f
   ```

4. **Health checks:**
   ```bash
   # Wait for services to start (5 minutes)
   sleep 300

   # Test all endpoints
   curl http://localhost:26657/status    # Cintara node
   curl http://localhost:8000/health     # LLM server
   curl http://localhost:8080/health     # AI bridge
   ```

## Other Logs Analysis

From your logs, I also noticed:
- ✅ Docker setup completed successfully
- ✅ Docker volumes were created successfully
- ❌ Bind mount failed due to missing directories
- ✅ No other critical errors found

## Files Provided

1. **`setup-secretvm-dirs.sh`** - Automated directory setup script
2. **`docker-compose.secretvm-fixed.yml`** - Fixed compose file using Docker volumes
3. **This troubleshooting guide**

## Image Compatibility

Your current setup is trying to use:
```yaml
image: public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified:secretvm-latest
```

But the available image is:
```yaml
image: public.ecr.aws/b8j2u1c6/cintaraio/cintara-unified:latest
```

The fixed docker-compose file uses the correct image tag.

## Recommended Next Steps

1. **Use Solution 2** (Fixed Docker Compose) for fastest deployment
2. **Monitor logs** during startup to ensure all services initialize properly
3. **Test functionality** once all health checks pass
4. **Consider using the production-minimal build** if you encounter llama.cpp build issues

## Quick Deploy Command

```bash
# One-command deployment with the fixed compose file
docker-compose -f docker-compose.secretvm-fixed.yml up -d --remove-orphans

# Monitor startup
docker-compose -f docker-compose.secretvm-fixed.yml logs -f cintara-unified
```

This should resolve the volume mount errors and get your SecretVM deployment running successfully.