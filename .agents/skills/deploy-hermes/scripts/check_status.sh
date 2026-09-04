#!/usr/bin/env bash
set -euo pipefail

DOMAIN="hermes.ovictorfarias.com.br"

echo "=========================================================="
echo "Status do Hermes Agent na VPS"
echo "=========================================================="

echo -e "\n1. Containers:"
docker ps -a --filter "name=hermes" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n2. Rede Traefik (root_default):"
docker inspect hermes --format 'IP na rede root_default: {{with index .NetworkSettings.Networks "root_default"}}{{.IPAddress}}{{end}}' || true

echo -e "\n3. Logs Recentes:"
docker logs --tail 25 hermes

echo -e "\n4. Teste HTTP Interno:"
curl -s -I http://127.0.0.1:9119 || true

echo -e "\n5. Teste HTTPS Externo:"
curl -s -k -I "https://$DOMAIN" || true
