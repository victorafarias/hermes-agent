# Backup dos dados do Hermes Agent (~/.hermes) na VPS
param (
    [string]$VpsHost = "31.97.163.164",
    [string]$VpsUser = "root"
)

Write-Host "Iniciando backup dos dados do Hermes na VPS..." -ForegroundColor Cyan
$sshTarget = "$($VpsUser)@$($VpsHost)"
$cmd = "mkdir -p /root/backups && BACKUP_FILE=\"/root/backups/hermes_$(date +%Y%m%d_%H%M%S).tar.gz\" && tar -czf \$BACKUP_FILE -C /root .hermes && ls -lh \$BACKUP_FILE"

ssh -o BatchMode=yes $sshTarget $cmd
Write-Host "Backup concluido com sucesso!" -ForegroundColor Green
