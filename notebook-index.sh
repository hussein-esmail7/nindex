#!/bin/bash

# notebook-index.sh
# Hussein Esmail
# Description: This program will use fzf to open my notebook pages quickly
#   Allows search by notebook number and page, or by index entry name.

# TODO: Add an `-m` option that prints a list of pages that match a query, and include the title of each page in that query. Essentially a grep of the cache

FOLDER_NOTEBOOKS="$HOME/Documents/Notebooks"
INDEX_FILE="$HOME/Documents/Notebooks/N-Indexes.tex"
CONFIG_QUIET=1 # Quiet mode by default. Pass "-v" for verbose
CONFIG_SCAN=0 # Do not rescan files unless told
FILE_FZFNAMES="$HOME/git/notebook-index/notebookcache.txt"
FZF_PROMPT="Notebook Search: "
STR_SEP="|"
STR_EMPTY="=== NO ENTRY ===" # If notebook page has no index entry
ERR_NOPAGE="No page selected!"
RUN_FZF=1 # True by default, use -n for not running fzf
PRINT_RECENT=0 # True if using -r. Exits program if true

# Checking for command arguments
while getopts ":ehnrsv:" opt; do
	case $opt in
		e)
			$EDITOR "$INDEX_FILE" # Edit the index file
			exit 1
			;;
		h)  # Help message
			echo "usage: ./notebook-index, ni"
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
			echo "    '$INDEX_FILE'"
			echo "-h: Prints this help message, then exit program."
			echo "-r: Print the most recent page entry, then exit program"
			echo "-s: Rescan index file before searching in fzf"
			echo "-v: Verbose mode. Program is quiet by default."
			echo ""
			echo "See https://github.com/hussein-esmail7/notebook-index"
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

if [ ! -f "$FILE_FZFNAMES" ] ; then
	# Notebook cache file does not exist, '-s' needs to be run
	CONFIG_SCAN=1
	echo "Warning: $FILE_FZFNAMES does not exist!"
	echo "         Automatically running with scan ('-s')"
	echo "         File located at '$(pwd)/$FILE_FZFNAMES'"
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
	files=$(find "$FOLDER_NOTEBOOKS" -name "N*-P*.jpg" -type f -execdir basename '{}' ';' | sort)
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
		pTitle=$(grep $pageNum $INDEX_FILE | cut -d] -f2- | xargs -0)
		if [ "${#pTitle}" -eq 0 ] ; then
			# If there is no entry for this page, set to $STR_EMPTY
			pTitle="$STR_EMPTY"
		fi
		final+=("$pageNum $STR_SEP $pTitle") # Add formatted line to array
	done
	printf "%s\n"  "${final[@]}" > "$FILE_FZFNAMES" # Write lines to file
	if [ $CONFIG_QUIET -eq 0 ] ; then
		echo "Done"
	fi
fi

if [ $PRINT_RECENT -eq 1 ] ; then
	# Print the most recent page entries, then exit program
	# At the moment, print the 5 most recent pages because the most recent page
	# may be page 200 (Index 3/3) but you may be missing pages 100-197
	cat "$FILE_FZFNAMES" | tail -5
	exit 0 # Exit the program
fi

if [ $CONFIG_QUIET -eq 0 ] ; then
	# Print the whole list of text that will be passed to fzf
	cat "$FILE_FZFNAMES"
fi


# Feed lines to fzf
if [ $RUN_FZF -eq 1 ] ; then
	if [ "${#args}" -eq 0 ] ; then
		# If the user did not provide an initial query
		PAGE_CHOICE=$(cat "$FILE_FZFNAMES" | fzf --tac --prompt="$FZF_PROMPT" | cut -d " " -f1)
	else
		if [[ "$args" =~ (n|N)[0-9]{2}(-| )(p|P)[0-9]{3}$ ]] ; then
			# If the user gave the notebook and page number they want
			# Match formatting if in case it is not exact
			PAGE_CHOICE=$(echo "${args// /-}" | tr '[:lower:]' '[:upper:]')
			# "// /-": Replace spaces with "-"
			# tr: Make all letters in variable uppercase
		else
			# If the user gave an uncertain initial query
			PAGE_CHOICE=$(cat "$FILE_FZFNAMES" | fzf --tac --prompt="$FZF_PROMPT" --query "$args" | cut -d " " -f1)
		fi
	fi
	# FZF argument explanations:
	# --tac		--> Reverse the order of the output: Best match is at bottom
	# --prompt	--> Change the prompt line while in fzf: Configurable by user

	if [ "${#PAGE_CHOICE}" -eq 0 ] ; then
		echo "$ERR_NOPAGE"
		exit 1
	fi

	FILE_LOCATION=$(find "$FOLDER_NOTEBOOKS" -name "$PAGE_CHOICE*")
	# Explanation for "$PAGE_CHOICE*" part:
	#   At first, I had "$PAGE_CHOICE.jpg", but this does not find the pages that
	#   may have " - rescan" in the file name. "$PAGE_CHOICE" does not return
	#   anything because it thinks that's the whole file name, so I need the
	#   wildcard

	if [ $CONFIG_QUIET -eq 0 ] ; then
		# Print the fill path of the chosen file
		echo "Location: $FILE_LOCATION"
	fi

	if [ -z "$FILE_LOCATION" ] ; then
		# If the file does not exist, exit the program and return an error
		echo "$PAGE_CHOICE does not exist!"
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
