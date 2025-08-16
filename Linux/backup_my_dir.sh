#!/bin/bash
source ./colors.sh

# Timestamp definition
DATE=$(date +'%Y-%m-%d')
TIMESTAMP=$(date +'%Y-%m-%d_%H%M%S')

# Define checksum
CHECKSUM_FILE="/tmp/backup.md5"

# Define paths
SOURCE_PATH="~/Cloud"
BACKUP_DIR="$HOME/personal_files_backup/cloud_dir_backup-$DATE"
BACKUP_FILENAME="cloud_files_bak-$TIMESTAMP.tar.gz"

DEST_PATH="$BACKUP_DIR/$BACKUP_FILENAME"
LOG_PATH="$BACKUP_DIR/cloud_files_bak_log-$TIMESTAMP.log"

if [ -d "$BACKUP_DIR" ]; then
    echo "Backup directory for $DATE already exists. Skipping." >> "$LOG_PATH"
    exit 0
fi

# Create an archive directory
mkdir -p "$BACKUP_DIR"

# Create log file
function make_log() {
    if [ ! -f "$LOG_PATH" ]; then
        echo "'$TIMESTAMP' No log file found. Attempting to create one..."
        touch "$LOG_PATH"
        echo "'$TIMESTAMP' Log file created successfully. Path: $LOG_PATH" >> "$LOG_PATH"
        echo "" >> "$LOG_PATH"
    fi
}

make_log

# Check if backup already exists.
find ~/Cloud \
    \( -name "venv" -o -name ".gitignore" \) -prune -o \
    \( -type f \( -name "*.sh" -o -name "*.py" -o -name "*.txt" \) \) -print0 \
    | xargs -0 md5sum | sort > /tmp/current.md5

if [ -f "$CHECKSUM_FILE" ] && cmp -s /tmp/current.md5 "$CHECKSUM_FILE"; then
    echo "'$TIMESTAMP' No changes since last backup. Skipping." >> "$LOG_PATH"
    rm /tmp/current.md5
    exit 0
else
    mv /tmp/current.md5 "$CHECKSUM_FILE"
fi

echo "'$TIMESTAMP' Finding .sh, .py, and .txt files inside the cloud directory" >> "$LOG_PATH"

# Find the desired files and create backup
find ~/Cloud \
    \( -name "venv" -o -name ".gitignore" \) -prune -o \
    \( -type f \( -name "*.sh" -o -name "*.py" -o -name "*.txt" \) \) -print0 | tar --null -czvf \
    $DEST_PATH --files-from=- >> "$LOG_PATH" 2>&1

if [ $? -eq 0 ]; then
    echo "'$TIMESTAMP' Backup Successful" >> "$LOG_PATH"
    echo "'$TIMESTAMP' Success: Archived and Compressed files." >> "$LOG_PATH"
    echo "" >> "$LOG_PATH"
else
    echo "'$TIMESTAMP' Backup Failed" >> "$LOG_PATH"
    echo "$TIMESTAMP' Error encountered during backup." >> "$LOG_PATH"
    echo "" >> "$LOG_PATH"
    exit 1
fi

exit 0