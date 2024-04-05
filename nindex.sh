#!/bin/bash

# nindex.sh
# Hussein Esmail
# Description: This program will use fzf to open my notebook pages quickly
#   Allows search by notebook number and page, or by index entry name.

# Values that are here only
FOLDER_CONFIG="$HOME/.config/nindex"
FILE_LIST=".file_list_tmp" # Cache file name
STR_SEP="|"
ERR_NOPAGE="No page selected!"
DISABLE_ERR_NOPAGE=1 # Disable the "No page selected!" error.
C_FILE_PATH="./ni_get_index"

# Default config values
FZF_PROMPT="Notebook Search: "
STR_EMPTY="=== NO ENTRY ===" # If notebook page has no index entry

if [ ! -f "$FOLDER_CONFIG/config" ] ; then
	echo "[ERROR] ${FOLDER_CONFIG}/config does not exist!"
	echo "Please create this file and see https://github.com/hussein-esmail7/nindex for guidelines"
	exit 1
fi

# Check for path values in config file
source "${FOLDER_CONFIG}/config"
[ -z "$NOTEBOOK_FOLDER" ] && echo "[ERROR] `NOTEBOOK_FOLDER` variable not defined in ${FOLDER_CONFIG}"
[ -z "$NOTEBOOK_INDEX" ]  && echo "[ERROR] `NOTEBOOK_INDEX` variable not defined in ${FOLDER_CONFIG}"

args="$@" # Get any arguments from user. Must be after the options part above

if [[ "$1" =~ [0-9]{1,2}$ && "$2" =~ [0-9]{1,3}$ ]] ; then
 	# Cases: "09 123", "9 123", "9 12"
 	# First number is notebook number, and second is page (which
 	# doesn't have to be 3 digits)
 	tmp_n_num=$(echo "$args" | awk '{print $1}')
 	tmp_n_num=$(printf "%02d\n" $tmp_n_num)
 	tmp_p_num=$(echo "$args" | awk '{print $2}')
 	tmp_p_num=$(printf "%03d\n" $tmp_p_num)
 	P_CHOICE="N${tmp_n_num}-P${tmp_p_num}"
elif [[ "$1" =~ [n|N][0-9]{1,2}$ && -z "$2" ]] ; then
	# Cases: "N09", "n12", "n1"
 	# When only one number is given with a prefix "n" (or "N"), indicates the notebook number
 	# Run fzf but only with the pages of that notebook
	grep_str=$(echo "$1" | tr "n" "N") # Make "n" capital if needed. So we can grep the index file (case-sensitive)
	if [[ "${#grep_str}" -eq 2 ]] ; then
		# When the string is 2 characters long, put a 0 in between
		# Ex. "N1" to "N01"
		grep_str="${grep_str:0:1}"0"${grep_str:1}"
	fi
	# echo "Searching $grep_str only..."
	IFS=$'\n';
	cd "$( dirname "${BASH_SOURCE[0]}" )" ; "$C_FILE_PATH" "$NOTEBOOK_FOLDER" "$NOTEBOOK_INDEX" | grep "$grep_str" | sort > "$FILE_LIST"

	# TODO: Pass all unprocessed arguments to fzf as a query
	P_CHOICE=$(cat "$FILE_LIST" | fzf --tac --prompt="$FZF_PROMPT" | cut -d " " -f1)

elif [[ "$1" =~ [0-9]{1,3}$ && -z "$2" ]] ; then
	# Cases: "09", "123", "12"
 	# When only one number is given, which indicates the page number.
 	# This will output the most recent notebook page that has that page number
	cd "$( dirname "${BASH_SOURCE[0]}" )" ; "$C_FILE_PATH" "$NOTEBOOK_FOLDER" "$NOTEBOOK_INDEX" | sort -r > "$FILE_LIST"
	tmp_p_num=$(echo "$args" | awk '{print $1}')
 	tmp_p_num=$(printf "%03d\n" $tmp_p_num)
	P_CHOICE=$(grep -m1 "P$tmp_p_num" "$FILE_LIST" | cut -d " " -f1)
elif [[ "$1" == "-h" || "$1" == "help" ]] ; then
	# Help message
	echo "usage: ./nindex, ni"
	echo ""
	echo "This program quickly opens a specific notebook page quickly"
	echo "Allows search by notebook number and page, or by index"
	echo "entry name."
	echo ""
	echo "Requirements: fzf"
	echo ""
	echo "Arguments:"
	echo "edit, -e: Edit index file in default editor, then exit program."
	echo "    Current file path:"
	echo "    '$NOTEBOOK_INDEX'"
	echo "help, -h: Prints this help message, then exit program."
	echo "list, -l: Prints the entire index, then exit program."
	echo ""
	echo "https://github.com/hussein-esmail7/nindex"
	exit 1
elif [[ "$1" == "-e" || "$1" == "edit" ]] ; then
	# Edit the index file
	$EDITOR "$NOTEBOOK_INDEX"
	exit 1
elif [[ "$1" == "-l" || "$1" == "list" ]] ; then
	# Print the index, then exit
	cd "$( dirname "${BASH_SOURCE[0]}" )" ; "$C_FILE_PATH" "$NOTEBOOK_FOLDER" "$NOTEBOOK_INDEX" | sort
	exit 1
else # Run as normal
	IFS=$'\n';
	cd "$( dirname "${BASH_SOURCE[0]}" )" ; "$C_FILE_PATH" "$NOTEBOOK_FOLDER" "$NOTEBOOK_INDEX" | sort > "$FILE_LIST"

	# TODO: Pass all unprocessed arguments to fzf as a query
	P_CHOICE=$(cat "$FILE_LIST" | fzf --tac --prompt="$FZF_PROMPT" | cut -d " " -f1)
fi

# [ ! -z "$P_CHOICE" ] && echo "PCHOICE: $P_CHOICE"
rm -f "$FILE_LIST" # Delete temporary cache file

if [[ "$P_CHOICE" != *"\n"* ]] ; then
	# If no option is given in fzf, it may return the whole list. This can be
	# caught by seeing if $P_CHOICE is multiple lines

	# Find the chosen file
	FILE_LOCATION=$(find "$NOTEBOOK_FOLDER" -name "$P_CHOICE*")
	# Explanation for "$P_CHOICE*" part:
	#   At first, I had "$P_CHOICE.jpg", but this does not find the pages that
	#   may have " - rescan" in the file name. "$P_CHOICE" does not return
	#   anything because it thinks that's the whole file name, so I need the
	#   wildcard

	# Open the file

	if [[ ! -f "$FILE_LOCATION" ]] ; then # Check if file exists first
		echo "File does not exist!"
		exit 1
	elif [[ $OSTYPE == "darwin"* ]] ; then # macOS
		open "$FILE_LOCATION"
	elif [[ "$OSTYPE" == "linux-gnu"* ]]; then # Linux
		okular "$FILE_LOCATION" & > /dev/null
	fi
fi

exit 0
