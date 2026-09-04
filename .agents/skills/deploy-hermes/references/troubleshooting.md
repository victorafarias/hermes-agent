# Guia de Troubleshooting - Hermes com Traefik

## 1. Erro 404 (Not Found) no Domínio

**Sintoma:** Ao acessar `https://hermes.ovictorfarias.com.br`, o Traefik retorna `404 page not found`.

**Possíveis Causas & Soluções:**
- **Container fora da rede `root_default`:**
  Verifique com `docker inspect hermes --format '{{json .NetworkSettings.Networks}}'`. Se não contiver `root_default`, certifique-se de que a rede foi declarada como `external: true` no compose.
- **Labels do Traefik incorretos ou ausentes:**
  Verifique com `docker inspect hermes --format '{{json .Config.Labels}}'`.
- **Container não está em execução (`exited`):**
  Rode `docker ps -a --filter "name=hermes"` e `docker logs hermes` para checar o erro de boot.

---

## 2. Erro 502 (Bad Gateway) no Domínio

**Sintoma:** O Traefik reconhece a rota, mas não consegue conectar ao container.

**Possíveis Causas & Soluções:**
- **Porta incorreta no label do Traefik:**
  O Hermes Dashboard roda na porta **`9119`**. O label DEVE ser:
  `traefik.http.services.hermes.loadbalancer.server.port=9119`
- **Dashboard falhou ao iniciar:**
  Verifique `docker logs hermes`. Se faltarem as variáveis `HERMES_DASHBOARD_BASIC_AUTH_USERNAME` e `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD`, o dashboard recusa inicializar em `0.0.0.0` (fail-closed por segurança).

---

## 3. "Authentication Required" / Falha de Login no Dashboard

**Sintoma:** A página pede login mas as credenciais não funcionam.

**Solução:**
- As credenciais ficam salvas em `/root/.hermes/.env` na VPS.
- Para verificar as credenciais configuradas:
  ```bash
  grep "HERMES_DASHBOARD_BASIC_AUTH" /root/.hermes/.env
  ```
- Para redefinir a senha:
  Altere a linha `HERMES_DASHBOARD_BASIC_AUTH_PASSWORD` em `/root/.hermes/.env` e reinicie o container:
  ```bash
  docker restart hermes
  ```

---

## 4. Problema de Permissão em `/opt/data`

**Sintoma:** Logs mostram `Permission denied` ao tentar criar ou ler arquivos de configuração ou bancos de dados SQLite.

**Solução:**
- No Docker Compose, defina:
  ```yaml
  environment:
    - HERMES_UID=0
    - HERMES_GID=0
  ```
- No host VPS, garanta permissões:
  ```bash
  chmod -R 700 /root/.hermes
  ```
