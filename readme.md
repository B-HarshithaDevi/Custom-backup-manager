# Custom Backup Manager

A smart backup system supporting versioning, incremental and differential backups, encryption, compression, and retention management.

---

## Features

- Configurable backup sources & destination
- Supports backup types:
  - Full backup
  - Incremental backup
  - Differential backup
- Compression:
  - `tar` (no compression)
  - `tar.gz` (compressed)
- Encryption:
  - `openssl`
  - `gpg`
  - Password verification before backup
- Retention policy (keeps last N backups)
- Automatic scheduled backups via cron
- Restore script included

---

## File Structure

- `backup.sh` → Script to perform backups
- `restore.sh` → Script to restore backups
- `backup.conf` → Configuration file for directories, backup type, compression, encryption, and retention
- `install_cron.sh` → Script to schedule daily backups automatically
- `readme.md` → This file
- `backups/` → Directory where backups are stored

---

## Usage

### Backup

Run backup script with optional type:

```bash
./backup.sh full
./backup.sh incremental
./backup.sh differential
./backup.sh   # Uses default type in backup.conf
```
Note: Some code snippets were assisted by AI tools (ChatGPT), but all logic and modifications were fully understood and implemented by the author.

