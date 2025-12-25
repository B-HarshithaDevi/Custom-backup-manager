#!/bin/bash

# Custom Backup Manager

# Load configuration
CONFIG_FILE="backup.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config file not found!"
    exit 1
fi

source "$CONFIG_FILE"

# OVERRIDE BACKUP TYPE IF USER GIVES ARGUMENT

# Usage:
#   ./backup.sh full
#   ./backup.sh incremental
#   ./backup.sh differential
#   ./backup.sh   ← uses backup.conf default
# --------------------------------------------------
if [ ! -z "$1" ]; then
    BACKUP_TYPE="$1"
fi

# Create log file if not exists
touch "$LOG_FILE"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "Backup started (Type: $BACKUP_TYPE)."

# PASSWORD + VERIFICATION

echo "Enter encryption password"
read -sp "Password: " PASS1
echo
read -sp "Verify Password: " PASS2
echo

if [ "$PASS1" != "$PASS2" ]; then
    echo "Passwords do not match. Exiting..."
    log "Password mismatch. Backup aborted."
    exit 1
fi

ENCRYPTION_PASSWORD="$PASS1"
echo "Password verified."
log "Password verified."

# Validate directories

if [ ! -d "$DEST_DIR" ]; then
    mkdir -p "$DEST_DIR"
    log "Created backup directory."
fi

TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
BACKUP_DIR="$DEST_DIR/backup_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

log "Backup directory: $BACKUP_DIR"

# BACKUP MODE HANDLING

case "$BACKUP_TYPE" in

    full)
        log "Performing FULL backup."
        echo "FULL backup running..."
        for SRC in $SOURCE_DIRS; do
            rsync -av --delete "$SRC" "$BACKUP_DIR"
        done
        ;;

    incremental)
        log "Performing INCREMENTAL backup."
        echo "INCREMENTAL backup running..."
        LINK_DEST=$(ls -dt "$DEST_DIR"/backup_* 2>/dev/null | sed -n '2p')

        for SRC in $SOURCE_DIRS; do
            if [ -d "$LINK_DEST" ]; then
                rsync -av --delete --link-dest="$LINK_DEST" "$SRC" "$BACKUP_DIR"
            else
                rsync -av --delete "$SRC" "$BACKUP_DIR"
            fi
        done
        ;;

    differential)
        log "Performing DIFFERENTIAL backup."
        echo "DIFFERENTIAL backup running..."
        BASE=$(ls -dt "$DEST_DIR"/backup_* 2>/dev/null | tail -n 1)

        for SRC in $SOURCE_DIRS; do
            if [ -d "$BASE" ]; then
                rsync -av --delete --compare-dest="$BASE" "$SRC" "$BACKUP_DIR"
            else
                rsync -av --delete "$SRC" "$BACKUP_DIR"
            fi
        done
        ;;

    *)
        echo "Invalid BACKUP_TYPE: $BACKUP_TYPE"
        log "Invalid backup type."
        exit 1
        ;;
esac

# COMPRESSION

ARCHIVE="$BACKUP_DIR.tar"

if [ "$COMPRESSION" = "tar.gz" ]; then
    ARCHIVE="$ARCHIVE.gz"
    tar -czf "$ARCHIVE" -C "$DEST_DIR" "$(basename "$BACKUP_DIR")"
elif [ "$COMPRESSION" = "tar" ]; then
    tar -cf "$ARCHIVE" -C "$DEST_DIR" "$(basename "$BACKUP_DIR")"
else
    log "No compression applied."
fi

log "Compression completed: $ARCHIVE"

# Remove uncompressed backup folder
rm -rf "$BACKUP_DIR"

# ENCRYPTION

if [ "$ENCRYPTION" = "openssl" ]; then
    openssl enc -aes-256-cbc -salt -in "$ARCHIVE" -out "$ARCHIVE.enc" -pass pass:"$ENCRYPTION_PASSWORD"
    rm "$ARCHIVE"
    ARCHIVE="$ARCHIVE.enc"
    log "OpenSSL encryption done."

elif [ "$ENCRYPTION" = "gpg" ]; then
    echo "$ENCRYPTION_PASSWORD" | \
    gpg --batch --yes --passphrase-fd 0 -c "$ARCHIVE"
    rm "$ARCHIVE"
    ARCHIVE="$ARCHIVE.gpg"
    log "GPG encryption done."

else
    log "No encryption applied."
fi

echo "Backup created: $ARCHIVE"
log "Final backup stored: $ARCHIVE"

# RETENTION POLICY

COUNT=$(ls -dt "$DEST_DIR"/backup_* 2>/dev/null | wc -l)

if [ "$COUNT" -gt "$RETENTION_COUNT" ]; then
    REMOVE=$(ls -dt "$DEST_DIR"/backup_* | tail -n $(($COUNT - $RETENTION_COUNT)))
    rm -rf $REMOVE
    log "Removed old backups due to retention policy."
fi

log "Backup completed successfully."
echo "Backup completed successfully!"
