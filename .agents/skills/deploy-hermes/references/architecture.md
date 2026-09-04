# Arquitetura do Hermes Agent com Traefik na VPS

## Visão Geral

O deploy do **Hermes Agent** nesta VPS foi desenhado para operar de forma integrada com o ecossistema Docker existente, aproveitando o **Traefik** como proxy reverso e gerenciador de certificados SSL automáticos via Let's Encrypt.

```mermaid
flowchart TD
    Internet([Cliente / Navegador]) -->|HTTPS :443| Traefik[Traefik Proxy (root-traefik-1)]
    Traefik -->|Roteamento Host hermes.ovictorfarias.com.br| HermesContainer[Container: hermes]
    
    subgraph Docker Network: root_default
        Traefik
        HermesContainer
    end

    subgraph Host VPS
        DataDir["/root/.hermes (Volume montado em /opt/data)"]
        SourceDir["/root/hermes (Codigo fonte e compose)"]
    end

    HermesContainer -->|Persistencia| DataDir
```

## Componentes

1. **Traefik (`root-traefik-1`)**:
   - Rede Docker: `root_default`
   - Entrypoint seguro: `websecure` (porta 443)
   - Resolução ACME: `mytlschallenge` (HTTP challenge / TLS)
   - Modo Docker Provider: inspeciona os labels do container `hermes` dinamicamente.

2. **Container Hermes (`hermes`)**:
   - Imagem: `nousresearch/hermes-agent:latest`
   - Processo Principal: `gateway run` gerenciado pelo `s6-overlay`.
   - Dashboard Web: ativado com `HERMES_DASHBOARD=true`, escutando na porta **9119** (`0.0.0.0:9119`).
   - Autenticação: Basic Auth (`HERMES_DASHBOARD_BASIC_AUTH_USERNAME` e `_PASSWORD`) obrigatório para binds não-loopback.
   - Volume: `/root/.hermes` mapeado para `/opt/data`.

3. **Portas**:
   - **9119**: Porta interna do dashboard FastAPI / Uvicorn + WebSocket RPC. Mapeada pelo label `traefik.http.services.hermes.loadbalancer.server.port=9119`.
   - **8642**: Porta opcional do API Server do gateway (quando habilitado).
