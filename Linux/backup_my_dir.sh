#!/bin/bash
# Enable strict mode for better error handling
set -euo pipefail

# Define paths for your script
BACKUP_BASE_DIR="$HOME/personal_files_backup"
SOURCE_PATH="$HOME/Cloud"

# Get current date and timestamp
DATE=$(date +'%Y-%m-%d')
TIMESTAMP=$(date +'%Y-%m-%d_%H%M%S')

# Define backup and log paths using the date
BACKUP_DIR="$BACKUP_BASE_DIR/cloud_dir_backup-$DATE"
BACKUP_FILENAME="cloud_files_bak-$TIMESTAMP.tar.gz"
DEST_PATH="$BACKUP_DIR/$BACKUP_FILENAME"
LOG_PATH="$BACKUP_DIR/cloud_files_bak_log-$TIMESTAMP.log"


# Check if a backup for today already exists
if [ -d "$BACKUP_DIR" ]; then
    echo "Backup directory for $DATE already exists. Skipping."
    exit 0
fi

# Create backup directory and the log file
mkdir -p "$BACKUP_DIR"
touch "$LOG_PATH"

# Log the start of the script
echo "[$TIMESTAMP] Starting backup script..." >> "$LOG_PATH"

# Find files and create the backup, redirecting all output to the log file
echo "[$TIMESTAMP] Finding .sh, .py, and .txt files inside the cloud directory." >> "$LOG_PATH"
find "$SOURCE_PATH" \
    \( -name "venv" -o -name ".gitignore" \) -prune -o \
    \( -type f \( -name "*.sh" -o -name "*.py" -o -name "*.txt" \) \) -print0 | tar --null -czvf "$DEST_PATH" --files-from=- >> "$LOG_PATH" 2>&1

# Check the exit status of the tar command and log the result
if [ $? -eq 0 ]; then
    echo "[$TIMESTAMP] Backup Successful: Archived and Compressed files to $DEST_PATH" >> "$LOG_PATH"
else
    echo "[$TIMESTAMP] Backup Failed: Error encountered during backup." >> "$LOG_PATH"
    exit 1
fi

exit 0