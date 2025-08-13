#!/bin/bash

TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)
SOURCE_PATH="/var/log"
BACKUP_DIR="/var/log/backup"
BACKUP_FILENAME="var_log_bak-$TIMESTAMP.tar.gz"
DEST_PATH="$BACKUP_DIR/$BACKUP_FILENAME"
LOG_PATH="$BACKUP_DIR/backup_log-$TIMESTAMP.log"

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

mkdir -p "$BACKUP_DIR"

function make_directory() {
	read -p "Enter the directory path: " COPY_DEST_DIR

	if [ ! -d "$COPY_DEST_DIR" ]; then
		echo -e "${YELLOW}Directory $COPY_DEST_DIR does not exist.${RESET}"
		read -p "Do you want to create it?(yes/no) " USER_PROMPT

		USER_PROMPT=$(echo "$USER_PROMPT" | tr '[:upper:]' '[:lower:]')

		if [[ "$USER_PROMPT" == "yes" || "$USER_PROMPT" == "y" ]]; then
			echo "$(date +%Y-%m-%d-%H%M%S)Directory for copying backup is being created." >> "$LOG_PATH"
			mkdir -p "$COPY_DEST_DIR"
			if [ $? -eq 0 ]; then
				echo "$(date +%Y-%m-%d-%H%M%S)Dirctory for copying backup created successfully." >> "$LOG_PATH"
				echo -e "${GREEN}Directory created successfully.{RESET}"
			else
				echo "$(date +%Y-%m-%d-%H%M%S)Directory for copying backup failed to create." >> "$LOG_PATH"
				echo -e "${RED}Directtory creation failed.{RESET}"
				exit 1
			fi
		else
			echo -e "${RED}Copy operation aborted.{RESET}"
		fi
	fi

	echo -e "${YELLOW}Copying backup to '$COPY_DEST_DIR'...${RESET}"
	cp "$DEST_PATH" "$COPY_DEST_DIR"

	if [ $? -eq 0 ]; then
		echo "$(date +%Y-%m-%d-%H%M%S)Backup file copied successfully." >> "$LOG_PATH"
		echo -e "${GREEN}Success: Backup file copied to '$COPY_DEST_DIR'${RESET}"
	else
		echo "$(date +%Y-%m-%d-%H%M%S)Backup file can not be copied." >> "$LOG_PATH"
		echo -e "${RED}Failed: Backup file could not be copied. Check the log for more details.${RESET}"
		exit 1
	fi
}

function make_log() {
	if [! -f "$LOG_PATH" ]; then
		echo "$(date +%Y-%m-%d-%H%M%S)No log file found. Attempting to create one." >> "$LOG_PATH"
		touch "$LOG_PATH"
		echo "$(date +%Y-%m-%d-%H%M%S) Log file created successfully at $LOG_PATH." >> "$LOG_PATH"
		echo "------------------------------------------------" >> "$LOG_PATH"
		echo "" >> "$LOG_PATH"
	fi
}

make_log

echo "--- Backup Process Started at $TIMESTAMP ---" >> "$LOG_PATH"
echo "$(date +%Y-%m-%d-%H%M%S) Attempting to create backup: $BACKUP_FILENAME" >> "$LOG_PATH"
echo "------------------------------------------------" >> "$LOG_PATH"
echo "" >> "$LOG_PATH"

sudo find "$SOURCE_PATH" -name "*.log" -mtime +30 -print0 | sudo tar --null -czvf "$DEST_PATH" --files-from=- >> "$LOG_PATH" 2>&1

if [ $? -eq 0 ]; then
    echo "--- Backup Successful ---" >> "$LOG_PATH"
    echo "$(date +%Y-%m-%d-%H%M%S) Success: Archived and compressed files." >> "$LOG_PATH"
    echo -e "${GREEN}Backup created successfully: $BACKUP_FILENAME${RESET}"

    read -p "Do you want to copy this backup to another directory? (yes/no) " USER_RESPONSE
    LOWER_RESPONSE=$(echo "$USER_RESPONSE" | tr '[:upper:]' '[:lower:]')
    if [[ "$LOWER_RESPONSE" == "yes" || "$LOWER_RESPONSE" == "y" ]]; then
        make_directory
    fi
else
    echo "--- Backup Failed ---" >> "$LOG_PATH"
    echo "$(date +%Y-%m-%d-%H%M%S) Error encountered during backup." >> "$LOG_PATH"
    echo -e "${RED}Backup Failed: See $LOG_PATH for details.${RESET}"
    exit 1
fi

echo "The script log can be found at: $LOG_PATH"

exit 0	
