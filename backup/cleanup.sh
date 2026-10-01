#!/usr/bin/env bash
set -Eeuo pipefail

: "${BACKUP_DIR:?BACKUP_DIR is required}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
    echo "RETENTION_DAYS must be a non-negative integer" >&2
    exit 2
fi

backup_dir="$(cd "$BACKUP_DIR" 2>/dev/null && pwd)" || {
    echo "BACKUP_DIR does not exist: $BACKUP_DIR" >&2
    exit 2
}

if [[ "$backup_dir" == "/" ]]; then
    echo "refusing to clean the filesystem root" >&2
    exit 2
fi

find "$backup_dir" -maxdepth 1 -type f -name '*.dump' -mtime "+$RETENTION_DAYS" -print -delete
