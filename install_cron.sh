#!/bin/bash

BACKUP_SCRIPT="$(pwd)/backup.sh"
LOG_FILE="/var/log/custom_backup.log"

echo "Installing cron job for daily backups at 2 AM..."

# Ensure log file exists
sudo touch "$LOG_FILE"
sudo chmod 666 "$LOG_FILE"

# Add cron job
( crontab -l 2>/dev/null; echo "0 2 * * * $BACKUP_SCRIPT >> $LOG_FILE 2>&1" ) | crontab -

echo "Cron job installed:"
echo "   0 2 * * * $BACKUP_SCRIPT >> $LOG_FILE 2>&1"
echo
echo "Use 'crontab -l' to verify."
