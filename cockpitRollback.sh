#!/bin/bash
# Install/Update Script for Cockpit https://getcockpit.com
# Created by Marcel Caraballo marcel.caraballo@pradtke.de

# First of all, you need to assign execute permissions to the script
# chmod +x cockpitRollback.sh
# and then ./cockpitRollback.sh on a terminal

# Cockpit folder
# COCKPIT_DIR="/var/www/html"
COCKPIT_DIR="/var/www/cockpit"

# Temporal untar folder
TEMP_DIR="$HOME/cockpit/temp"

#Backup Extension
BAK_EXT='tar.gz'

# Create a timestamp
TIMESTAMP=$(date "+%Y.%m.%d_-_%T")

# Backup folder
BACKUP_DIR="$HOME/cockpit/backups"

# Logs Folder
LOG_DIR="$HOME/cockpit/logs/rollbacks"

# Logs Extension
LOG_EXT='log'

# Rollback temp folder
ROLLBACK_DIR="$TEMP_DIR/rollback"

# Log file
LOG_FILE="$TIMESTAMP.$LOG_EXT"

# Number of logs to store
MAX=3

# Cockpit Backup new name
COCKPIT_FILE_NAME="cockpit-core.$BAK_EXT"

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
  read -p "Do you want to proceed with the Rollback? (y/n): " choice
  echo -e "${RESET}"

  # Check the user's choice
  if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
    # User chose to proceed, so continue with the update

    # Start the Update
    process
  else
    # User chose not to proceed, exit with status 1 to indicate failure
    echo "Rollback canceled by the user."
    exit 1
  fi

}

# Function to clean the non working Cockpit Version
function remove {

  # Clean up the $COCKPIT_DIR
  log_message $BLUE "Cleaning the non working Cockpit Version..."
  rm -rf "$COCKPIT_DIR/*"

  # Check the exit status of the rm command
  if [ $? -eq 0 ]; then
    log_message $GREEN "$COCKPIT_DIR folder content deleted."
  else
    log_error "$COCKPIT_DIR folder content cannot be deleted. Are you Admin?"
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

  # Check if the temp directory exists, and create it if not
  check_or_create_folder $TEMP_DIR

  # Check if the $ROLLBACK_DIR directory exists, and create it if not
  check_or_create_folder $ROLLBACK_DIR

  # Check if the $LOG_DIR directory exists, and create it if not
  check_or_create_folder $LOG_DIR

}

function restore {

  # Backup Cockpit configuration files with the timestamp
  log_message $BLUE "Restoring up Cockpit CMS to the last working version..."

  # Backup of the last Cockpit Working Version
  BACKUP=$(ls -t $BACKUP_DIR | head -n 1)

  cp $BACKUP_DIR/$BACKUP $TEMP_DIR/$COCKPIT_FILE_NAME

  # Check the exit status of the cp command
  if [ $? -eq 0 ]; then
    log_message $GREEN "Backup rename successful."
  else
    log_error "Rollback rename failed."
    exit 1
  fi

  # Untar the file into $TEMP_DIR
  tar -xf $TEMP_DIR/$COCKPIT_FILE_NAME -C $ROLLBACK_DIR

  # Check the exit status of the tar command
  if [ $? -eq 0 ]; then
    log_message $GREEN "Untar successful."
  else
    log_error "Untar failed."
    exit 1
  fi

  # Copy the files to $COCKPIT_DIR
  cp -ru $ROLLBACK_DIR/* $COCKPIT_DIR/

  # Check the exit status of the cp command
  if [ $? -eq 0 ]; then
    log_message $GREEN "Rollback successful."
  else
    log_error "Rollback failed."
    exit 1
  fi

}

# Function to clean rollback file and old logs
function clean {

  # Clean up downloaded files
  log_message $BLUE "Cleaning up Rollback files..."
  rm -rf "$TEMP_DIR"

  # Check the exit status of the rm command
  if [ $? -eq 0 ]; then
    log_message $GREEN "Temp folder deleted."
  else
    log_error "Temp folder cannot be deleted."
  fi

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
  echo -e "$TIMESTAMP $SEP_LOG_MESSAGE ERROR: $ERROR_MESSAGE" | tee -a "$LOG_DIR/$LOG_FILE"

  # Reset Color
  echo -e "${RESET}"

}

function process {

  # clear the screen
  clear

  # print on the screen that the script is running
  echo -e "${LILA}Automated Rollback Script for Cockpit CMS"
  echo -e "${RESET}"
  sleep 1

  # create a $TEMP_DIR to extract the tar
  folders

  # Start logging
  log_message $YELLOW "Starting Cockpit CMS Rollback..."

  # clean the non working Cockpit Version
  remove

  # Restore process
  restore

  # delete $TEMP_DIR and old logs
  clean

  # End logging
  log_message $YELLOW "Cockpit CMS Rollback completed."

}

# Start the rollback if the user confirm it
start
