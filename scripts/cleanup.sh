#!/usr/bin/env bash
docker compose down || true
docker rm -f $(docker ps -aq --filter "name=cintara-phase1-cintara-node-run") 2>/dev/null || true
docker network rm cintara-phase1-net 2>/dev/null || true
read -p "Clear chain data? (y/N) " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then rm -rf ./data/.tmp-cintarad; fi