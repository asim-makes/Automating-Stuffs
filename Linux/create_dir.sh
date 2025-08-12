#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Global log file
LOG_FILE="$HOME/create_dir.log"

create_log_file() {
	if [ -e "$LOG_FILE" ]; then
		echo "$(date '+%Y-%m-%d %H:%M:%S') - Log file $LOG_FILE already exists." >> "$LOG_FILE"
	else
		touch "$LOG_FILE"
		echo "$(date '+%Y-%m-%d %H:%M:%S') - Log file: $LOG_FILE created successfully." >> "$LOG_FILE"
	fi
}

get_valid_directory() {
	local base_path_input="Where do you want to create the new directory? (Press Enter for default): "
	local base_path
	
	while true; do
		read -p "$base_path_input" base_path
		
		if [[ -z "$base_path" ]]; then
			echo "$PWD" # Return the current working directory
			return
		fi
		
		if [[ ! "$base_path" =~ ^/ ]]; then
			base_path="$HOME/$base_path" 
		fi
		
		local resolved_path
		resolved_path=$(readlink -f "$base_path")
		
		if [[ -d "$resolved_path" ]]; then
			echo "$resolved_path"
			return
		else
			echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: The path '$resolved_path' is not a valid directory." >> "$LOG_FILE"
			echo "${RED}'$resolved_path' is not a valid directory.{NC}" >&2
			base_path_input="Please enter a valid, full directory path:"
		fi
	done
}

validate_dirname() {
	local dirname="$1"
	
	if [[ -z "$dirname" ]]; then
		echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Directory cannot be empty." >> "$LOG_FILE"
		echo "${RED}Directory cannot be empty.{NC}" >&2
		return 1
	fi
	
	return 0
}


create_directory() {
	echo
	local dir_list=()
	local base_path

	echo "Enter the directories you want to create:"
    echo "Example:"
    echo "Project1/src/main"
    echo "Project1/assets"
    echo "Project1/static/app"
    echo "(Press Ctrl+D when done)"
    echo

	while IFS= read -r line; do
		[[ -n "$line" ]] && dir_list+=("$line")
	done

	if [[ ${#dir_list[0]} -eq 0 ]]; then
		echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: No directories entered." >> "$LOG_FILE"
		echo -e "${RED}Error: No directories entered.${NC}" >&2
		return
	fi
	
	
	# Display some directories and then get a valid base path.
	echo
	echo "-------------------------Directory Listing------------------------- "
	ls -ld "$HOME"/*/ 2>/dev/null
	echo "--------------------------------------------------------------------"
	echo
	
	base_path=$(get_valid_directory)
	
	if [[ -n "$base_path" ]]; then
		# Preview
		temp_dir=$(mktemp -d)
		for dir in "${dir_list[@]}"; do
			mkdir -p "$temp_dir/$dir"
		done

		echo
		echo "Preview of directory structure under: $base_path"
		if command -v tree >/dev/null 2>&1; then
            tree "$temp_dir" | sed "1s|$temp_dir|$base_path|"
        else
            find "$temp_dir" -print | sed "s|$temp_dir|$base_path|"
        fi
        echo

		rm -rf "$temp_dir"

		read -p "Do you want to proceed with creating '$full_path'? (y/n): " confirm
		if [[ "$confirm" != "y" ]]; then
			echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Directory creation failed." >> "$LOG_FILE"
			echo -e "${RED}An error occured. Please check the log file.${NC}"
			return
		fi

		echo "Attempting to create a new directory..."

		all_success=true

		for dir in "${dir_list[@]}"; do
			full_path="$base_path/$dir"	
			
			if [[ -e "$full_path" ]]; then
				echo "$(date '+%Y-%m-%d %H:%M:%S') - Info: Directory '$full_path' already exists." >> "$LOG_FILE"
			else
				mkdir -p "$full_path"
				if [[ $? -eq 0 ]]; then
					echo "$(date '+%Y-%m-%d %H:%M:%S') - Success: Successfully created directory." >> "$LOG_FILE"
				else
					echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Successfully created directory." >> "$LOG_FILE"
					all_success=false
				fi
			fi
		done

		echo "--- $(date '+%Y-%m-%d %H:%M:%S') --- Attempt Finished ---" >> "$LOG_FILE"

		if $all_success; then
			echo -e "${GREEN}Success: All directories processed successfully.${NC}"
		else
			echo -e "${RED}Error encountered. Check the logs for more details.${NC}" >&2
		fi
	fi
    		
}


display_main_menu() {
    echo "---------------------------"
    echo "       Main Menu"
    echo "---------------------------"
    echo "1. Create a new directory"
    echo "2. Exit"
    echo "---------------------------"
    echo
}


main() {
    create_log_file
    while true; do
        display_main_menu
        read -p "Enter your choice: " choice

        case "$choice" in 
            1) create_directory ;;
            2) echo "Exiting script. Goodbye!" ; break ;;
            *) echo "Invalid choice. Please enter 1 or 2." >&2 ;;
        esac
        echo
    done
}


# Start the script
main

