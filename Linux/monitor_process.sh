#!/bin/bash

LOG_DIR="/var/log/process_monitor"
LOG_FILE_PATH="$LOG_DIR/process_mon.log"

function gen_logs() {
	if [! -d "$LOG_DIR" ]; then
		echo "Log directory not found. Creating $LOG_DIR..."
		sudo mkdir -p "$LOG_DIR"

		if [ $? -ne 0 ]; then
			echo "Error: Failed to create log directory: $LOG_DIR. Exiting."
			exit 1
		fi
		echo "Log directory created sucessfully"
	fi

	if [ ! -f "$LOG_DIR" ]; then
		echo "Log file not found. Creating $LOG_FILE_PATH..."
		sudo touch "$LOG_FILE_PATH"
		
		if [ $? -ne 0 ]; then
			echo "Error: Failed to create log file: $LOG_FILE_PATH. Exiting."
			exit 1
		fi

		echo "Log file created sucessfully"
		echo "Success: Log file creation successful" >> $LOG_FILE_PATH
	fi
}

gen_logs

top_cpu=$(ps aux --sort=-%cpu | awk 'NR==2 {
printf("{\"pid\":%s,\"name\":\"%s\",\"cpu_percent\":%s}", $2, $11, $3)
}')
top_mem=$(ps aux --sort=-%mem | awk 'NR==2 {
printf("{\"pid\":%s,\"name\":\"%s\",\"mem_percent\":%s}", $2, $11, $4)
}')


echo "{
	\"time\":\"$(date +%Y-%m-%dT%H:%M:%S)\",
	\"top_cpu\":$top_cpu,
	\"top_ram\":$top_mem
}" >> $LOG_FILE_PATH


