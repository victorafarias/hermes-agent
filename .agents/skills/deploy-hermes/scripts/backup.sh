#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/root/backups"
mkdir -p "$BACKUP_DIR"

BACKUP_FILE="$BACKUP_DIR/hermes_$(date +%Y%m%d_%H%M%S).tar.gz"
echo "Gerando backup de /root/.hermes em $BACKUP_FILE..."
tar -czf "$BACKUP_FILE" -C /root .hermes
ls -lh "$BACKUP_FILE"
echo "Backup gerado com sucesso!"
