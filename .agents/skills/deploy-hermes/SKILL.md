---
name: deploy-hermes
description: >-
  Faz deploy, atualizações, gerenciamento de containers e verificações de status do
  sistema Hermes Agent na VPS (31.97.163.164) via SSH, Docker Compose e Traefik
  sob o domínio hermes.ovictorfarias.com.br. Use esta skill sempre que o usuário pedir
  para fazer deploy, atualizar, verificar o status ou diagnosticar o Hermes na VPS.
---

# Deploy do Hermes Agent na VPS com Traefik

Esta skill contém as instruções, scripts e configurações para realizar o deploy contínuo,
atualizações e monitoramento do **Hermes Agent** na VPS via Docker Compose integrado ao **Traefik**.

## Parâmetros da Infraestrutura

- **Host VPS**: `31.97.163.164`
- **Usuário SSH**: `root`
- **Comando SSH**: `ssh root@31.97.163.164`
- **Diretório do Projeto**: `/root/hermes`
- **Diretório de Dados Persistentes**: `/root/.hermes` (montado em `/opt/data` no container)
- **Domínio Público**: `hermes.ovictorfarias.com.br`
- **Porta Web do Hermes**: `9119` (Dashboard SPA + WebSocket API)
- **Rede Docker do Traefik**: `root_default` (rede externa gerenciada pelo Traefik)
- **Certificado TLS**: `mytlschallenge` (Let's Encrypt HTTP-01/TLS Challenge via Traefik)

---

## Procedimento de Deploy / Atualização

### Opção 1: Execução Automática via Script (Recomendada)

No Windows (PowerShell), execute o script de deploy:
```powershell
& .agents/skills/deploy-hermes/scripts/deploy.ps1
```

Ou diretamente na VPS (Bash):
```bash
bash /root/hermes/.agents/skills/deploy-hermes/scripts/deploy.sh
```

### Opção 2: Procedimento Manual Passo a Passo

Caso precise rodar manualmente via SSH:

1. **Conectar à VPS e acessar o diretório:**
   ```bash
   ssh root@31.97.163.164
   cd /root/hermes
   ```

2. **Atualizar o repositório:**
   ```bash
   git fetch origin
   git pull origin main
   ```

3. **Garantir a estrutura de dados persistentes:**
   ```bash
   mkdir -p /root/.hermes
   chmod 700 /root/.hermes
   ```

4. **Garantir configuração do `.env` e autenticação do Dashboard:**
   Se `/root/.hermes/.env` não existir ou faltar credenciais do dashboard:
   ```bash
   if ! grep -q "HERMES_DASHBOARD_BASIC_AUTH_USERNAME" /root/.hermes/.env 2>/dev/null; then
     SECRET=$(openssl rand -base64 32)
     cat >> /root/.hermes/.env <<EOF
   HERMES_DASHBOARD_BASIC_AUTH_USERNAME=admin
   HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=HermesAdmin$(openssl rand -hex 4)
   HERMES_DASHBOARD_BASIC_AUTH_SECRET=${SECRET}
   EOF
     chmod 600 /root/.hermes/.env
   fi
   ```

5. **Aplicar o arquivo Docker Compose para o Traefik:**
   Copie o template de compose se necessário:
   ```bash
   cp .agents/skills/deploy-hermes/templates/docker-compose.traefik.yml docker-compose.traefik.yml
   docker compose -f docker-compose.traefik.yml up -d
   ```

6. **Verificar os logs de inicialização:**
   ```bash
   docker logs -f --tail 50 hermes
   ```

---

## Verificação e Diagnóstico de Saúde

Para verificar o status completo da aplicação e do roteamento Traefik:

No Windows:
```powershell
& .agents/skills/deploy-hermes/scripts/check_status.ps1
```

Na VPS:
```bash
bash /root/hermes/.agents/skills/deploy-hermes/scripts/check_status.sh
```

### Checagens Manuais:
- **Container rodando:** `docker ps | grep hermes`
- **Resposta HTTP Traefik:** `curl -I https://hermes.ovictorfarias.com.br`
- **Logs do Traefik:** `docker logs --tail 50 root-traefik-1`
- **Rede do container:** `docker inspect hermes --format '{{json .NetworkSettings.Networks}}'` (deve conter `root_default`)

---

## Backup e Recuperação

Antes de realizar grandes migrações ou alterações destrutivas:

```powershell
& .agents/skills/deploy-hermes/scripts/backup.ps1
```

Na VPS:
```bash
mkdir -p /root/backups
tar -czf /root/backups/hermes_$(date +%Y%m%d_%H%M%S).tar.gz -C /root .hermes
```

---

## Arquivos e Referências

- [Template Docker Compose](file:///c:/Users/Administrator/hermes/.agents/skills/deploy-hermes/templates/docker-compose.traefik.yml)
- [Template de Variáveis de Ambiente](file:///c:/Users/Administrator/hermes/.agents/skills/deploy-hermes/templates/.env.production.example)
- [Guia de Arquitetura e Portas](file:///c:/Users/Administrator/hermes/.agents/skills/deploy-hermes/references/architecture.md)
- [Guia de Troubleshooting](file:///c:/Users/Administrator/hermes/.agents/skills/deploy-hermes/references/troubleshooting.md)
