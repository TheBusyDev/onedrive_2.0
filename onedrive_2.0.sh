#!/bin/bash

##################################################################################
# onedrive_2.0 by TheBusyDev
#
# This script is based on 'OneDrive Client for Linux by abraunegg':
# --> https://github.com/abraunegg/onedrive
# and inspired by this script by 'zzzdeb':
# --> https://github.com/zzzdeb/dotfiles/blob/master/scripts/tools/onedrive_log
##################################################################################

# Declare variables
BUSINESS_SHARED_FOLDERS_CONFIG="$HOME/.config/onedrive/business_shared_folders"
DIR="$HOME/.onedrive_log/"		# directory where logs will be saved
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H%M%S")
FILE="onedrive_${DATE}_${TIME}.log"	# .log filename

# Colors used to print colorful output
black="\033[1;30m"
red="\033[1;31m"
green="\033[1;32m"
yellow="\033[1;33m"
blue="\033[1;34m"
magenta="\033[1;35m"
cyan="\033[1;36m"
white="\033[1;37m"
normal="\033[0m"

# Print OneDrive logo as ASCII art
cd $(dirname "$0")

if [ -f onedrive_logo.txt ]
then
	cat onedrive_logo.txt
	printf "\n\n"
fi

# Title
printf "${blue}OneDrive Client for Linux... with awseome and colorful output! :)\n\n\n"

# Delete older .log files
if [ ! -d "$DIR" ]
then
	mkdir "$DIR"
	cd "$DIR"
else
	cd "$DIR"
	logs="$( ls )"
	logs_count=$( echo $logs | awk '{print NF}' )
	
	if [ $logs_count -ge 10 ]
	then
		rm $( echo $logs | awk '{print $1}' )
	fi
fi

# Check for new Business Shared Folders to be sync
if [ -f "$BUSINESS_SHARED_FOLDERS_CONFIG" ]
then
	i=0; # counter
	
	# read "$BUSINESS_SHARED_FOLDERS_CONFIG" file line by line
	while IFS= read -r line
	do
		c=${line:0:1} # first character from $line

		if [[ "$c" != "#" && "$c" != " " && "$c" != "" ]] # exclude comments and empty spaces
		then 
			business_shared_folders[$i]="$line"
			i=$(( $i+1 ))
		fi
	done < "$BUSINESS_SHARED_FOLDERS_CONFIG"
fi

if [[ -z $business_shared_folders ]] # true if $business_shared_folders is unset
then
	printf "${cyan}We didn't find any Business Shared Folders to sync..."
else	
	printf "${cyan}The following Business Shared Folders will be synced:"
	
	for folder in "${business_shared_folders[@]}"
	do
		printf "\n-> $folder"
	done
fi

printf "${normal}\n\n\n"

# Perform sync through 'OneDrive Client for Linux' by abraunegg
onedrive --synchronize --sync-shared-folders |
	tee "$FILE" | # save .log file in $FILE ($FILE is located in $DIR directory)
  	sed -u "s/Syncing/$(printf "${cyan}Syncing${normal}")/;
		s/Uploading/$(printf "${blue}Uploading${normal}")/;
        	s/Creating/$(printf "${blue}Creating${normal}")/;
        	s/Downloading/$(printf "${magenta}Downloading${normal}")/;
        	s/Moving/$(printf "${magenta}Moving${normal}")/;
        	s/WARNING:/$(printf "${yellow}⚠️  WARNING:${normal}")/;
        	s/Deleting/$(printf "${yellow}Deleting${normal}")/;
        	s/deleted/$(printf "${yellow}deleted${normal}")/;
    		s/Skipping/$(printf "${red}Skipping${normal}")/;
        	s/error/$(printf "${red}ERROR❎${normal}")/;
        	s/ERROR/$(printf "${red}ERROR❎${normal}")/;
        	s/done./$(printf "${green}done✔${normal}")/;" # turn output into an awesome and colorful text! :)

# Check for errors during sync and print error message if a problem occured
if [ ${PIPESTATUS[0]} == 0 ]
then
	printf "\n\n"
	grep -i "skip" "$FILE"	# look for skipped files during sync

	if [ $? == 0 ]
	then
		printf "\n\n${red}WARNING: Some files have been skipped!${normal}\n\n"
	fi

	grep -i "error" "$FILE"	# look for general errors occured during sync

	if [ $? == 0 ]
	then
		printf "\n\n${red}WARNING: Some errors occured!${normal}\n\n"
	fi

	printf "${cyan}Sync completed!\n"
else
	printf "\n\n${red}Ops, something went wrong...\nCheck your internet connection or your OneDrive account status!\n"
fi

# Print exit messsage
printf "${cyan}Log saved on $DIR$FILE\nPress [ENTER] to exit...${normal}"
read # wait for [ENTER] to be pressed and close the script

exit 0
