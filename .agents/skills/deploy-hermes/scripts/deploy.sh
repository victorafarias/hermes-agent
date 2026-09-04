#!/usr/bin/env bash
set -euo pipefail

DOMAIN="hermes.ovictorfarias.com.br"
PROJECT_DIR="/root/hermes"
DATA_DIR="/root/.hermes"

echo "=========================================================="
echo "Iniciando Deploy do Hermes Agent na VPS com Traefik"
echo "=========================================================="

cd "$PROJECT_DIR"

echo "==> Atualizando repositorio git..."
git fetch origin
git pull origin main

echo "==> Garantindo diretorio de dados $DATA_DIR..."
mkdir -p "$DATA_DIR"
chmod 700 "$DATA_DIR"

if [ ! -f "$DATA_DIR/.env" ]; then
    echo "==> Gerando $DATA_DIR/.env com credenciais do Dashboard..."
    SECRET=$(openssl rand -base64 32)
    RAND_PW="Hermes_$(openssl rand -hex 6)"
    cat > "$DATA_DIR/.env" <<EOF
HERMES_DASHBOARD_BASIC_AUTH_USERNAME=admin
HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${RAND_PW}
HERMES_DASHBOARD_BASIC_AUTH_SECRET=${SECRET}
EOF
    chmod 600 "$DATA_DIR/.env"
    echo "==> Credenciais criadas:"
    echo "    Usuario: admin"
    echo "    Senha:   ${RAND_PW}"
else
    if ! grep -q "HERMES_DASHBOARD_BASIC_AUTH_USERNAME" "$DATA_DIR/.env"; then
        echo "==> Adicionando credenciais do Dashboard ao .env existente..."
        SECRET=$(openssl rand -base64 32)
        RAND_PW="Hermes_$(openssl rand -hex 6)"
        cat >> "$DATA_DIR/.env" <<EOF
HERMES_DASHBOARD_BASIC_AUTH_USERNAME=admin
HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${RAND_PW}
HERMES_DASHBOARD_BASIC_AUTH_SECRET=${SECRET}
EOF
        echo "==> Credenciais adicionadas:"
        echo "    Usuario: admin"
        echo "    Senha:   ${RAND_PW}"
    fi
fi

echo "==> Aplicando Docker Compose para Traefik..."
cp "$PROJECT_DIR/.agents/skills/deploy-hermes/templates/docker-compose.traefik.yml" "$PROJECT_DIR/docker-compose.traefik.yml"
docker compose -f "$PROJECT_DIR/docker-compose.traefik.yml" up -d

echo "==> Aguardando inicializacao..."
sleep 5
docker ps --filter "name=hermes"

echo "==> Verificando conectividade local..."
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:9119 || true

echo "=========================================================="
echo "Deploy finalizado! Acesse: https://$DOMAIN"
echo "=========================================================="
