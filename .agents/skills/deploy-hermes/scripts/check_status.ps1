# Verificação de status e saúde do Hermes Agent na VPS
param (
    [string]$VpsHost = "31.97.163.164",
    [string]$VpsUser = "root",
    [string]$Domain = "hermes.ovictorfarias.com.br"
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Status do Hermes Agent na VPS ($VpsHost)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$sshTarget = "$($VpsUser)@$($VpsHost)"

Write-Host "`n1. Verificando Containers Docker:" -ForegroundColor Yellow
ssh -o BatchMode=yes $sshTarget "docker ps -a --filter 'name=hermes' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

Write-Host "`n2. Verificando Rede Traefik (root_default):" -ForegroundColor Yellow
ssh -o BatchMode=yes $sshTarget "docker inspect hermes --format 'IP no root_default: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'"

Write-Host "`n3. Ultimos logs do Hermes:" -ForegroundColor Yellow
ssh -o BatchMode=yes $sshTarget "docker logs --tail 25 hermes"

Write-Host "`n4. Testando rota externa HTTPS em https://$($Domain):" -ForegroundColor Yellow
try {
    $res = curl.exe -k -s -I "https://$Domain"
    $res | Out-String | Write-Host
} catch {
    Write-Host "Erro ao consultar HTTPS: $_" -ForegroundColor Red
}
