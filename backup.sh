#!/bin/sh
set -eo

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
  run-parts -a "pre-backup" --exit-on-error "${HOOKS_DIR}"
fi

# Print date
echo "=== Doing backup at $(date) ==="

# Make backup
if [[ "$MOUNTED_FOLDER" == */ ]];then
    source="${MOUNTED_FOLDER::-1}"
else
    source="$MOUNTED_FOLDER"
fi

MONTHLY_DIR="${BACKUP_DIR}/monthly/${VOLUME}-$(date +%Y%m)"

DAY=$(date +%Y%m%d)
MONTH=$(date +%Y%m)
if [[ ! -d "$MONTHLY_DIR" ]];then
    mkdir -p "$MONTHLY_DIR"
    echo "Full backup"
else
    echo "Incremental backup"
    find "${MONTHLY_DIR}/${DAY}.tar.gz" -type f
    if [[ $? -ne 0 ]]; then
        echo "Existing backup. Clean it"
        rm -rf "${MONTHLY_DIR}/${DAY}.tar.gz"
        rm -rf "${MONTHLY_DIR}/${DAY}.snap"
    fi
    # find last snap
    SNAP=$(find "${MONTHLY_DIR}" -type f -name "*.snap" | sort | tail -1)
    if [[ $? -eq 0 ]]; then
        echo "Existing snap. Copy it"
        cp "$SNAP" "${MONTHLY_DIR}/${DAY}.snap"
    fi
fi
echo "Making tarball"
tar cvzpf "${MONTHLY_DIR}/${DAY}.tar.gz" -g "${MONTHLY_DIR}/${DAY}.snap" "$source"
echo "Backup created successfully"

echo "Clean Months"
number_of_months=$(find "${BACKUP_DIR}/monthly/" -type d -not -path "${BACKUP_DIR}/monthly/" | wc -l)
echo "Current number of months: $number_of_months"
if [[ $number_of_months -gt $KEEP_MONTHS ]]; then
    to_remove=$((number_of_months - KEEP_MONTHS))
    for dir in $(find "${BACKUP_DIR}/monthly/" -type d -not -path "${BACKUP_DIR}/monthly/" | sort | head -n $to_remove); do
        echo rm -rf "$dir"
    done
fi

# Post-backup hook
if [ -d "${HOOKS_DIR}" ]; then
  run-parts -a "prepostbackup" --reverse --exit-on-error "${HOOKS_DIR}"
fi
