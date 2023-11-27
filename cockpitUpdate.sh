#!/bin/bash
# Install/Update Script for Cockpit https://getcockpit.com
# Created by Marcel Caraballo

# First of all, you need to assign execute permissions to the script
# chmod +x cockpitUpdate.sh
# and then ./cockpitUpdate.sh on a terminal

# Cockpit folder
COCKPIT_DIR="/var/www/cockpit"

# Cockpit master Source
# The download link seems to always be the same; it could be stored in a variable
# and passed as a parameter when executing the script like
# ./cockpitUpdate.sh files.getcockpit.com/releases/master/cockpit-core.zip
# or only the name of the file ./cockpitUpdate.sh cockpit-core.zip
COCKPIT_FILE_NAME="cockpit-core"
COCKPIT_SOURCE="https://files.getcockpit.com/releases/master/$COCKPIT_FILE_NAME.zip"

# Create a timestamp
TIMESTAMP=$(date "+%Y.%m.%d_-_%T")

# Backup folder
BACKUP_DIR="$HOME/cockpit/backups"

#Backup Extension
BAK_EXT='tar.gz'

# Number of backups and logs to store
MAX=3

# Temporal download folder
TEMP_DIR="$HOME/cockpit/temp"

# Logs Folder
LOG_DIR="$HOME/cockpit/logs/updates"

# Logs Extension
LOG_EXT='log'

# Log file
LOG_FILE="$TIMESTAMP.$LOG_EXT"

# ANSI escape codes for colors
# BLUE='\033[0;94m'
BLUE='\033[1;36m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
LILA='\033[1;35m'

# Date-Log messages/error separator
SEP_LOG_MESSAGE="|"

# ANSI escape code to reset text color to default
RESET='\033[0m'

function start {

  # clear the screen
  clear

  # Prompt the user for confirmation
  echo -e "${RED}"
  read -p "Do you want to proceed with the Update? (y/n): " choice
  echo -e "${RESET}"

  # Check the user's choice
  if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
    # User chose to proceed, so continue with the update

    # Start the Update
    process
  else
    # User chose not to proceed, exit with status 1 to indicate failure
    echo "Update canceled by the user."
    exit 1
  fi

}

function check_or_create_folder () {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
  fi

  # Check the exit status of the mkdir command
  if [ $? -ne 0 ]; then
    echo -e "${RED}"
    echo -e "ERROR: Directory creation failed: $1. Are logged as an Admin?"
    echo -e "${RESET}"
    exit 1
  fi
}

function folders {

  # Check if the backup directory exists, and create it if not
  check_or_create_folder $BACKUP_DIR

  # Check if the log directory exists, and create it if not
  check_or_create_folder $LOG_DIR

  # Check if the temp directory exists, and create it if not
  check_or_create_folder $TEMP_DIR

}

function backup {

  # Backup Cockpit configuration files with the timestamp
  log_message $BLUE "Backing up Cockpit CMS..."

  # Uncomment to store the folder without compression
  #cp -r $COCKPIT_DIR "$BACKUP_DIR/cockpit_$TIMESTAMP"

  # Backup the folder into a tar file
  tar -czf "$BACKUP_DIR/$TIMESTAMP.$BAK_EXT" -C $COCKPIT_DIR .

  # Check the exit status of the tar command
  if [ $? -eq 0 ]; then
    log_message $GREEN "Backup creation successful: $BACKUP_DIR/$TIMESTAMP.$BAK_EXT"
  else
    log_error "Backup creation failed."
    exit 1
  fi

}

function download {

  # Download the latest release
  log_message $BLUE "Downloading the latest Cockpit CMS release..."
  wget $COCKPIT_SOURCE -O "$TEMP_DIR/$COCKPIT_FILE_NAME.zip"

  # Check the exit status of the wget command
  if [ $? -eq 0 ]; then
    log_message $GREEN "Download successful."
  else
    log_error "Failed to download the latest Cockpit CMS release. Check your internet connection or the URL."
    exit 1
  fi

}

function install {

  # Unzip the downloaded file
  log_message $BLUE "Unzipping the downloaded release..."
  unzip "$TEMP_DIR/$COCKPIT_FILE_NAME.zip" -d "$TEMP_DIR/" > /dev/null

  # Check the exit status of the unzip command
  if [ $? -eq 0 ]; then
    log_message $GREEN "Unzip successful."
  else
    log_error "Unzip failed."
    exit 1
  fi

  # Copy the new files
  log_message $BLUE "Copying the new Cockpit CMS files..."
  cp -ru $TEMP_DIR/$COCKPIT_FILE_NAME/* $COCKPIT_DIR/

  # Check the exit status of the cp command
  if [ $? -eq 0 ]; then
    log_message $GREEN "Copy successful: $TEMP_DIR/$COCKPIT_FILE_NAME copied to $COCKPIT_DIR"
  else
    log_error "Copy failed. Cockpit CMS could not be updated."
    exit 1
  fi

}

# Function to clean download files, old backups and old logs
function clean {

  # Clean up downloaded files
  log_message $BLUE "Cleaning up downloaded files..."
  rm -rf "$TEMP_DIR"

  # Check the exit status of the rm command
  if [ $? -eq 0 ]; then
    log_message $GREEN "Temp folder deleted."
  else
    log_error "Temp folder cannot be deleted."
  fi

  # Delete the old Backup(s) file(s)
  delete_files $BACKUP_DIR $BAK_EXT 'Backup(s)'

  # Delete the old Log(s) file(s)
  delete_files $LOG_DIR $LOG_EXT 'Log(s)'

}

# Function to delete old files
function delete_files {

  local DIR_EXT="$1/*.$2";
  local TYPE=$3

  FILES_TO_RETAIN=$(ls -t $DIR_EXT | head -n $MAX)

  # Loop through all files in the directory
  for FILE in $DIR_EXT; do
    # Check if the file is not in the list of files to retain
    if ! echo "$FILES_TO_RETAIN" | grep -q "$FILE"; then
      # If not in the list, remove the file
      rm -f "$FILE"
      log_message $GREEN "Removed old $TYPE: $FILE. Only $MAX will be stored."
    fi
  done

}

# Function to log messages to both stdout and the log file
function log_message() {

  # Check if the log file exists, and create it if not
  if [ ! -f "$LOG_DIR/$LOG_FILE" ]; then
    touch "$LOG_DIR/$LOG_FILE"
  fi

  local COLOR=$1
  local MESSAGE="$2"

  # Apply a color
  echo -e "${COLOR}"

  # Add the message to the log
  echo -e "$TIMESTAMP $SEP_LOG_MESSAGE $MESSAGE" | tee -a "$LOG_DIR/$LOG_FILE"

  # Reset Color
  echo -e "${RESET}"

}

# Function to log errors to both stdout and the log file
function log_error() {

  local ERROR_MESSAGE="$1"

  # Apply Red color
  echo -e "${RED}"

  # Add the error to the log
  echo -e "$TIMESTAMP $SEP_LOG_MESSAGE ERROR: $ERROR_MESSAGE" | tee -a "$LOG_DIR/$LOG_FILE",

  # Reset Color
  echo -e "${RESET}"

}

function process {

  # clear the screen
  clear

  # print on the screen that the script is running
  echo -e "${LILA}Automated Install/Update Script for Cockpit CMS"
  echo -e "${RESET}"
  sleep 1

  # Create the necessary folders
  folders

  # Start logging
  log_message $YELLOW "Starting Cockpit CMS update..."

  # Backup process
  backup

  # Download process
  download

  # Installation process
  install

  # clean download files and old backups (only the last 5 will be stored)
  clean

  # End logging
  log_message $YELLOW "Cockpit CMS update completed."

}

# Start the update if the user confirm it
start
