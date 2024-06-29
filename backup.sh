#!/bin/sh
#set -eo

CONFIG_FILE="/config.json"
HOOKS_DIR="/hooks"
BACKUP_DIR=${BACKUP_DIR:-/backup}
if [ -d "${HOOKS_DIR}" ]; then
    on_error(){
      run-parts -a "error" "${HOOKS_DIR}"
    }
    trap 'on_error' ERR
fi

# Pre-backup hook
if [ -d "${HOOKS_DIR}" ]; then
    echo "=== Running Pre-backup"
    run-parts -a "pre-backup" --exit-on-error "${HOOKS_DIR}"
fi

# Print date
echo "=== Doing backup at $(date) ==="

# Mariadb
if [[ ! -d "/backup" ]]; then
    mkdir "/backup"
fi
cat "$CONFIG_FILE" | jq -r '.mariadb[] | .host + "|" + .port + "|" + .password' | while IFS="|" read -r MARIADB_HOST MARIADB_PORT MARIADB_PASSWORD
do
    echo "=== Backup Mariadb ${MARIADB_HOST} ==="
    mariadb-dump --all-databases \
                 --host=$MARIADB_HOST \
                 --port=$MARIADB_PORT \
                 --password=$MARIADB_PASSWORD > /backup/${MARIADB_HOST}_dump.sql
done

echo "=== Start backup at $BORG_REPOSITORY ==="

# Backup
INCLUDE=$(cat "$CONFIG_FILE" | jq -r '.include | join(" ")')
echo "Include: $INCLUDE"
EXCLUDE=$(cat "$CONFIG_FILE" | jq -r '.exclude | map("--exclude \"" + . + "\"") | join(" ")')
echo "Exclude: $EXCLUDE"
WITHIN=$(cat "$CONFIG_FILE" | jq -r '.prune.within')
echo "Within: $WITHIN"
WEEKLY=$(cat "$CONFIG_FILE" | jq -r '.prune.weekly')
echo "Weekly: $WEEKLY"
MONTHLY=$(cat "$CONFIG_FILE" | jq -r '.prune.monthly')
echo "Monthly: $MONTHLY"
cat "$CONFIG_FILE" | jq -r '.repositories[] | .bin + "|" + .path + "|" + .pass' | while IFS="|" read -r BORG_BIN BORG_REPOSITORY BORG_PASSPHRASE
do
    echo "=== Start backup at $BORG_REPOSITORY ==="
    echo "Borg binary: ${BORG_BIN}"
    echo "Passphrase: ${BORG_PASSPHRASE}"
    export BORG_PASSPHRASE
    borg create -v --stats \
         "$BORG_REPOSITORY"::'{hostname}-{now:%Y-%m-%d}' \
         $INCLUDE \
         $EXCLUDE \
         --remote-path "$BORG_BIN"
    echo "=== End backup and start prune at $BORG_REPOSITORY ==="
    borg prune -v                          \
               --stats                     \
               --list                      \
               --keep-within=$WITHIN       \
               --keep-weekly=$WEEKLY       \
               --keep-monthly=$MONTHLY     \
               --remote-path "$BORG_BIN"   \
               -- "$BORG_REPOSITORY"
    echo "=== End prune at $BORG_REPOSITORY ==="
done

# Post-backup hook
if [ -d "${HOOKS_DIR}" ]; then
    echo "=== Running Post-backup"
    run-parts -a "post-backup" --reverse --exit-on-error "${HOOKS_DIR}"
fi
