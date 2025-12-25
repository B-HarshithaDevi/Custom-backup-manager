#!/bin/bash

echo "Custom Backup Restore Tool"

# --- Ask for backup file ---
read -p "Enter path to backup file (.enc): " BACKUP_FILE

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "File not found!"
    exit 1
fi

# --- Ask for password twice ---
read -s -p "Enter password: " PASS1
echo
read -s -p "Verify password: " PASS2
echo

if [[ "$PASS1" != "$PASS2" ]]; then
    echo "Passwords do not match!"
    exit 1
fi

# --- Ask for restore directory ---
read -p "Enter restore directory: " RESTORE_DIR

mkdir -p "$RESTORE_DIR"

TEMP_DECRYPT="/tmp/decrypted_$$.tar.gz"

echo "Decrypting..."
if ! echo "$PASS1" | openssl enc -aes-256-cbc -d -salt -in "$BACKUP_FILE" -out "$TEMP_DECRYPT" 2>/tmp/restore_error; then
    echo "Decryption failed!"
    cat /tmp/restore_error
    rm -f "$TEMP_DECRYPT"
    exit 1
fi

echo "Extracting backup..."
tar -xzf "$TEMP_DECRYPT" -C "$RESTORE_DIR"

rm -f "$TEMP_DECRYPT"

echo "Restore complete!"
echo "Files restored to: $RESTORE_DIR"
