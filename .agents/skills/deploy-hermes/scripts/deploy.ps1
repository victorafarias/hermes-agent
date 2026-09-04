# Deploy do Hermes Agent na VPS (31.97.163.164) via SSH
param (
    [string]$VpsHost = "31.97.163.164",
    [string]$VpsUser = "root",
    [string]$ProjectDir = "/root/hermes",
    [string]$Domain = "hermes.ovictorfarias.com.br"
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Iniciando Deploy do Hermes Agent na VPS ($VpsHost)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Comando remoto a ser executado na VPS
$remoteScript = @'
set -e
echo "==> Atualizando repositorio em /root/hermes..."
cd /root/hermes
git fetch origin
git pull origin main

echo "==> Garantindo diretorio de dados /root/.hermes..."
mkdir -p /root/.hermes
chmod 700 /root/.hermes

if [ ! -f /root/.hermes/.env ]; then
    echo "==> Criando /root/.hermes/.env inicial com credenciais do Dashboard..."
    SECRET=$(openssl rand -base64 32)
    RAND_PW="Hermes_$(openssl rand -hex 6)"
    cat > /root/.hermes/.env <<EOF
HERMES_DASHBOARD_BASIC_AUTH_USERNAME=admin
HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${RAND_PW}
HERMES_DASHBOARD_BASIC_AUTH_SECRET=${SECRET}
EOF
    chmod 600 /root/.hermes/.env
    echo "==> Credenciais geradas:"
    echo "    Usuario: admin"
    echo "    Senha:   ${RAND_PW}"
else
    # Verificar se as credenciais existem
    if ! grep -q "HERMES_DASHBOARD_BASIC_AUTH_USERNAME" /root/.hermes/.env; then
        echo "==> Adicionando credenciais do Dashboard ao .env existente..."
        SECRET=$(openssl rand -base64 32)
        RAND_PW="Hermes_$(openssl rand -hex 6)"
        cat >> /root/.hermes/.env <<EOF
HERMES_DASHBOARD_BASIC_AUTH_USERNAME=admin
HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=${RAND_PW}
HERMES_DASHBOARD_BASIC_AUTH_SECRET=${SECRET}
EOF
        echo "==> Credenciais adicionadas:"
        echo "    Usuario: admin"
        echo "    Senha:   ${RAND_PW}"
    fi
fi

echo "==> Aplicando Docker Compose com suporte a Traefik..."
cp .agents/skills/deploy-hermes/templates/docker-compose.traefik.yml docker-compose.traefik.yml
docker compose -f docker-compose.traefik.yml up -d

echo "==> Aguardando inicializacao do container hermes..."
sleep 5
docker ps | grep hermes || true

echo "==> Verificando logs iniciais..."
docker logs --tail 30 hermes
'@

Write-Host "==> Executando rotina remota via SSH..." -ForegroundColor Yellow
$sshTarget = "$($VpsUser)@$($VpsHost)"
ssh -o BatchMode=yes $sshTarget $remoteScript

Write-Host "`n==> Testando resposta HTTPS externa em https://$($Domain)..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
try {
    $response = Invoke-WebRequest -Uri "https://$Domain" -Method Head -TimeoutSec 15 -SkipCertificateCheck -ErrorAction SilentlyContinue
    if ($response.StatusCode -lt 500) {
        Write-Host "==> SUCESSO! Rota ativa. Codigo HTTP: $($response.StatusCode)" -ForegroundColor Green
    } else {
        Write-Host "==> AVISO: Codigo HTTP retornado: $($response.StatusCode). Verifique os logs." -ForegroundColor Yellow
    }
} catch {
    Write-Host "==> Teste de conexao HTTP: $_" -ForegroundColor Yellow
}

Write-Host "`nDeploy finalizado! Acesse: https://$($Domain)" -ForegroundColor Green
