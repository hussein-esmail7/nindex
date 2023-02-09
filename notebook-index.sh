#!/bin/bash

# nindex.sh
# Hussein Esmail
# Description: This program will use fzf to open my notebook pages quickly
#   Allows search by notebook number and page, or by index entry name.

# TODO: Add an `-m` option that prints a list of pages that match a query, and
# include the title of each page in that query. Essentially a grep of the cache
# TODO: Move cache file somewhere else
# TODO: Make fzf optional

# Values that are here only
FOLDER_CONFIG="$HOME/.config/nindex"
CONFIG_QUIET=1 # Quiet mode by default. Pass "-v" for verbose
CONFIG_SCAN=0 # Do not rescan files unless told
STR_SEP="|"
ERR_NOPAGE="No page selected!"
RUN_FZF=1 # True by default, use -n for not running fzf
PRINT_RECENT=0 # True if using -r. Exits program if true

# Default config values
FILE_LIST="${FOLDER_CONFIG}/cache.txt"
FZF_PROMPT="Notebook Search: "
STR_EMPTY="=== NO ENTRY ===" # If notebook page has no index entry

if [ ! -f "$FOLDER_CONFIG" ] ; then
	echo "[ERROR] ${FOLDER_CONFIG} does not exist!"
	echo "Please create this file and see https://github.com/hussein-esmail7/nindex for guidelines"
	exit 1
fi

source "${FOLDER_CONFIG}/config"

# Variable check:
if [ -z "$NOTEBOOK_FOLDER" ] ; then
	echo "[ERROR] `NOTEBOOK_FOLDER` variable not defined in ${FOLDER_CONFIG}"
fi
if [ -z "$NOTEBOOK_INDEX" ] ; then
	echo "[ERROR] `NOTEBOOK_INDEX` variable not defined in ${FOLDER_CONFIG}"
fi

# Checking for command arguments
while getopts ":ehnrsv:" opt; do
	case $opt in
		e)
			$EDITOR "$NOTEBOOK_INDEX" # Edit the index file
			exit 1
			;;
		h)  # Help message
			echo "usage: ./nindex, ni"
			echo ""
			echo "This program quickly opens a specific notebook page quickly"
			echo "Allows search by notebook number and page, or by index"
			echo "entry name."
			echo ""
			echo "Requirements: fzf"
			echo ""
			echo "Arguments:"
			echo "-e: Edit index file in default editor, then exit program."
			echo "    Current file path:"
			echo "    '$NOTEBOOK_INDEX'"
			echo "-h: Prints this help message, then exit program."
			echo "-r: Print the most recent page entry, then exit program"
			echo "-s: Rescan index file before searching in fzf"
			echo "-v: Verbose mode. Program is quiet by default."
			echo ""
			echo "See https://github.com/hussein-esmail7/nindex"
			echo "for more info"
			exit 1
			;;
		n)  # Do not run fzf. Useful if you just want to scan
			RUN_FZF=0
			shift
			;;
		r)	# Print the most recent page entry, then exit program
			PRINT_RECENT=1
			shift
			;;
		s)
			CONFIG_SCAN=1 # Rescan files before showing the fzf menu
			shift
			;;
		v)
			CONFIG_QUIET=0 # Verbose mode
			shift
			;;
		\?)
			echo "ERROR: '$opt' is an invalid option!"
			exit 1
			;;
	esac
done

args="$@" # Get any arguments from user. Must be after the options part above

if [ ! -f "$FILE_LIST" ] ; then
	# Notebook cache file does not exist, '-s' needs to be run
	CONFIG_SCAN=1
	echo "Warning: $FILE_LIST does not exist!"
	echo "         Automatically running with scan ('-s')"
	echo "         File located at '$(pwd)/$FILE_LIST'"
fi

# TODO: Reduce the loops below to this line:
# find . -name "N*-P*.jpg" -type f -execdir basename '{}' ';' | sort

if [ $CONFIG_SCAN -eq 1 ] ; then
	# If '-s' option is passed or index file does not exist
	if [ $CONFIG_QUIET -eq 0 ] ; then
		echo "Scanning..."
	fi

	# Getting the list of files that qualify to an array.
	# Cannot do name=($(cmd)) because that converts each word to an array
	# entry, not by line. Example: "../path/N09-P123 - rescan.jpg" becomes
	#	1. "N09-P123"
	#	2. "-"
	#	3. "rescan.jpg"
	# What I want is "N09-P123 - rescan.jpg"
	files=$(find "$NOTEBOOK_FOLDER" -name "N*-P*.jpg" -type f -execdir basename '{}' ';' | sort)
	SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
	IFS=$'\n'      # Change IFS to newline char
	files=($files) # split the `names` string into an array by the same name
	IFS=$SAVEIFS   # Restore original IFS

	final=()
	# Iterate through each index of $files
	# `for i in ${files[@]}` gives you by word, not by line (same as issue above)
	for (( i=0; i<${#files[@]}; i++ )) ; do
		# Get rid of .jpg at the end, then only keep first word for error handling
		pageNum=${files[$i]%".jpg"}
		# Only keep first word, in case the file name is still "N09-P123 - rescan"
		pageNum=$(echo "$pageNum" | while read -a ar; do echo "${ar[0]}" ; done)
		# Get the .tex entry of that page and remove the LaTeX formatting
		pTitle=$(grep $pageNum $NOTEBOOK_INDEX | cut -d] -f2- | xargs -0)
		if [ "${#pTitle}" -eq 0 ] ; then
			# If there is no entry for this page, set to $STR_EMPTY
			pTitle="$STR_EMPTY"
			echo "$pageNum is EMPTY!"
		fi
		final+=("$pageNum $STR_SEP $pTitle") # Add formatted line to array
	done
	printf "%s\n"  "${final[@]}" > "$FILE_LIST" # Write lines to file
	if [ $CONFIG_QUIET -eq 0 ] ; then
		echo "Done"
	fi
fi

if [ $PRINT_RECENT -eq 1 ] ; then
	# Print the most recent page entries, then exit program
	# At the moment, print the 5 most recent pages because the most recent page
	# may be page 200 (Index 3/3) but you may be missing pages 100-197
	cat "$FILE_LIST" | tail -5
	exit 0 # Exit the program
fi

if [ $CONFIG_QUIET -eq 0 ] ; then
	# Print the whole list of text that will be passed to fzf
	cat "$FILE_LIST"
fi


# Feed lines to fzf
if [ $RUN_FZF -eq 1 ] ; then
	if [ "${#args}" -eq 0 ] ; then
		# If the user did not provide an initial query
		# P_CHOICE = User's page choice
		P_CHOICE=$(cat "$FILE_LIST" | fzf --tac --prompt="$FZF_PROMPT" | cut -d " " -f1)
	else
		# Full regex of everything: ((n|N)?[0-9]{1,2}(-| ))?(p|P)?[0-9]{1,3}
		# Below, I am splitting this up for better understanding
		if [[ "$args" =~ (n|N)[0-9]{2}(-| )(p|P)?[0-9]{3}$ ]] ; then
			# Cases: "N10-P100", "n10 p100", "n10-p100"
			# If the user gave the notebook and page number they want
			# Match formatting if in case it is not exact
			# Replace whitespace with "-" and make everything uppercase
			P_CHOICE=$(echo "${args// /-}" | tr '[:lower:]' '[:upper:]')
			# "// /-": Replace spaces with "-"
			# tr: Make all letters in variable uppercase
		elif [[ "$args" =~ [0-9]{1,2}(-| ){1}[0-9]{1,3}$ ]] ; then
			# Cases: "09 123", "9 123", "9 12"
			# First number is notebook number, and second is page (which
			# doesn't have to be 3 digits)
			tmp_n_num=$(echo "$args" | awk '{print $1}')
			tmp_n_num=$(printf "%02d\n" $tmp_n_num)
			tmp_p_num=$(echo "$args" | awk '{print $2}')
			tmp_p_num=$(printf "%03d\n" $tmp_p_num)
			P_CHOICE="N${tmp_n_num}-P${tmp_p_num}"
			echo "$P_CHOICE"
		elif [[ "$args" =~ (p|p)?[0-9]{1,3}$ ]] ; then
			# Cases: "p102", "102", "26" (for pages below 100)
			# In this case, automatically get the latest notebook with that
			# page number.
			tmp_p_num=${args//p}		# Get rid of "p" if it exists
			tmp_p_num=${tmp_p_num//P}	# Get rid of "P" if it exists
			tmp_p_num=$(printf "%03d\n" $tmp_p_num) # 3 digits with 0 padding
			# In the line above, you need to 0 pad this number because if you
			# search for page 12, page 112 would be the most recent result, so
			# we need an explicit "012".
			# Part 1: (grep) Query against index, returns qualifying pages
			#		"|" character added in case that number occurs in a page
			#		title.  Ex: "MATH 1025" for the "102" query.
			# Part 2: (sort) In case notebook order is not correct (latest last)
			# Part 3: (tail) Get the last line (the most up to date one)
			# Part 4: (cut) Get line up to the first whitespace (ex. N10-P102)
			P_CHOICE=$(grep "$tmp_p_num |" "$FILE_LIST" | sort | tail -n1 | cut -d " " -f1)
		else
			# If the user gave an uncertain initial query
			P_CHOICE=$(cat "$FILE_LIST" | fzf --tac --prompt="$FZF_PROMPT" --query "$args" | cut -d " " -f1)
		fi
	fi
	# FZF argument explanations:
	# --tac		--> Reverse the order of the output: Best match is at bottom
	# --prompt	--> Change the prompt line while in fzf: Configurable by user

	if [ "${#P_CHOICE}" -eq 0 ] ; then
		echo "$ERR_NOPAGE"
		exit 1
	fi

	FILE_LOCATION=$(find "$NOTEBOOK_FOLDER" -name "$P_CHOICE*")
	# Explanation for "$P_CHOICE*" part:
	#   At first, I had "$P_CHOICE.jpg", but this does not find the pages that
	#   may have " - rescan" in the file name. "$P_CHOICE" does not return
	#   anything because it thinks that's the whole file name, so I need the
	#   wildcard

	if [ $CONFIG_QUIET -eq 0 ] ; then
		# Print the fill path of the chosen file
		echo "Location: $FILE_LOCATION"
	fi

	if [ -z "$FILE_LOCATION" ] ; then
		# If the file does not exist, exit the program and return an error
		echo "$P_CHOICE does not exist!"
		exit 1
	fi

	if [[ $OSTYPE == "darwin"* ]] ; then
		# User is using a macOS machine
		open "$FILE_LOCATION"
	elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
		# NOTE: At the moment, Linux applications open the images into Okular
		okular "$FILE_LOCATION" & > /dev/null
	fi
fi

exit 0
