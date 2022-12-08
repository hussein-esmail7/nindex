#!/bin/bash

# notebookpg.sh
# Hussein Esmail
# Created: 2022 10 26
# Description: This program will use fzf to open my notebook pages


FOLDER_NOTEBOOKS="$HOME/Documents/Notebooks/*"
FOLDER_NOTEBOOKS2="$HOME/Documents/Notebooks"
INDEX_FILE="$HOME/Documents/Notebooks/N-Indexes.tex"
files=("$FOLDER_NOTEBOOKS"*) # Get list of all notebooks in the folder
CONFIG_QUIET=1 # Quiet mode by default. Pass "-v" for verbose
CONFIG_SCAN=0 # Do not rescan files unless told
FILE_FZFNAMES="$HOME/git/notebook-index/notebookcache.txt"
FZF_PROMPT="Notebook Search: "

# Checking for command arguments
while getopts ":vsh:" opt; do
	case $opt in
		v)
			echo "ERROR: '-v' option not implemented yet!"
			# TODO
			shift
			;;
		s)
			CONFIG_SCAN=1 # Rescan files before showing the fzf menu
			shift
			;;
		h)  # Help message
			echo "usage: n-i"
			echo ""
			echo "This program quickly opens a specific notebook page"
			echo ""
			echo "Requirements: fzf"
			echo ""
			echo "See https://github.com/hussein-esmail7/notebook-index for more info"
			exit 1
			;;
		\?)
			echo "ERROR: '$opt' is an invalid option!"
			exit 1
			;;
	esac
done

if [ ! -f "$FILE_FZFNAMES" ] ; then
	# Notebook cache file does not exist, '-s' needs to be run
	CONFIG_SCAN=1
	echo "Warning: Running with scan option '-s'"
	echo "         since $FZF_FILENAMES does not exist"
fi

# TODO: Reduce the loops below to this line:
# find . -name "N*-P*.jpg" -type f | sort

if [ $CONFIG_SCAN -eq 1 ] ; then
	iFile=$(cat "$INDEX_FILE") # Read the LaTeX index file contents
	SAVEIFS=$IFS
	IFS=$(echo -en "\n\b")
	pageTitles=() # Initialize array where page titles will be stored
	nREGEX="N[0-9]{2}-P[0-9]{3}.*+$"
	for nFolder in $FOLDER_NOTEBOOKS ; do
		# For every notebook folder
		if [ $CONFIG_QUIET -eq 0 ] ; then
			echo "$nFolder" # Print the file/folder name
		fi
		if [ -d "$nFolder" ] ; then # If the file/folder is a folder
			cd "$nFolder" # Change directories to that folder
			for nPageFile in * ; do # For every file in that folder (n-page)
				nPage=${nPageFile%".jpg"} # Remove the .jpg suffix
				pTitle=$(grep $nPage $INDEX_FILE | xargs) # Find that .tex entry
				pTitle=${pTitle#"\\"}				# Remove LaTeX formatting 1
				pTitle=${pTitle#"item[$nPage] "}	# Remove LaTeX formatting 2
				pageAppend="$nPage | $pTitle"
				if [ $CONFIG_QUIET -eq 0 ] ; then
					echo "     $pageAppend"
				fi
				pageTitles+=("$pageAppend") # Add formatted line to final array
			done
		fi
	done
	IFS=$SAVEIFS
	# touch "$FILE_FZFNAMES"
	# echo "File should exist now"
	# for i in "${pageTitles[@]}" ; do
	# 	echo "$i" >> "$FILE_FZFNAMES"
	# done
	printf "%s\n"  "${pageTitles[@]}" > "$FILE_FZFNAMES" # Write lines to file
fi


if [ $CONFIG_QUIET -eq 0 ] ; then
	cat "$FILE_FZFNAMES"
fi

# cat "$FILE_FZFNAMES" | fzf --tac --prompt="$FZF_PROMPT" # Feed lines to fzf

# Feed lines to fzf
PAGE_CHOICE=$(cat "$FILE_FZFNAMES" | fzf --tac --prompt="$FZF_PROMPT" | cut -d " " -f1)
# --tac		--> Reverse the order of the output
# --prompt	--> Change the prompt line while in fzf

# echo "Page choice: $PAGE_CHOICE"

FILE_LOCATION=$(find "$FOLDER_NOTEBOOKS2" -name "$PAGE_CHOICE.jpg")
echo "$FILE_LOCATION"

if [[ $OSTYPE == "darwin"* ]] ; then
	echo "Using macOS"
	open "$FILE_LOCATION"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
	# NOTE: At the moment, Linux applications open the images into Okular
	okular "$FILE_LOCATION" & > /dev/null
fi

exit 0
