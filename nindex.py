'''
nindex.py
Hussein Esmail
Created: 2025 02 13
Updated: 2025 02 13
Description: [DESCRIPTION]
'''

import os
import sys
import subprocess

# ========= VARIABLES ===========
dir_path = os.path.dirname(os.path.realpath(__file__))
path_input_processor = dir_path + "/nindex"
path_get_filepaths = dir_path + "/ni_get_index_both"
path_notebook_folder = "/Users/hussein/Documents/Notebooks"
path_notebook_index = "/Users/hussein/Documents/Notebooks/N-Indexes.tex"

# ========= COLOR CODES =========
color_end               = '\033[0m'
color_darkgrey          = '\033[90m'
color_red               = '\033[91m'
color_green             = '\033[92m'
color_yellow            = '\033[93m'
color_blue              = '\033[94m'
color_pink              = '\033[95m'
color_cyan              = '\033[96m'
color_white             = '\033[97m'
color_grey              = '\033[98m'

# ========= COLORED STRINGS =========
str_prefix_q            = f"[{color_pink}Q{color_end}]\t "
str_prefix_y_n          = f"[{color_pink}y/n{color_end}]"
str_prefix_err          = f"[{color_red}ERROR{color_end}]\t "
str_prefix_done         = f"[{color_green}DONE{color_end}]\t "
str_prefix_info         = f"[{color_cyan}INFO{color_end}]\t "
error_neither_y_n = f"{str_prefix_err} Please type 'yes' or 'no'"

def substring_in_list(string, listcheck):
    for i in listcheck:
        if string in i:
            return listcheck.index(i)
    return False

def yes_or_no(str_ask):
    while True:
        y_n = input(f"{str_prefix_q} {str_prefix_y_n} {str_ask}").lower()
        if y_n[0] == "y":
            return True
        elif y_n[0] == "n":
            return False
        if y_n[0] == "q":
            sys.exit()
        else:
            print(f"{str_prefix_err} {error_neither_y_n}")

def openImage(path):
    imageViewerFromCommandLine = {'linux':'xdg-open',
                                  'win32':'explorer',
                                  'darwin':'open'}[sys.platform]
    subprocess.Popen([imageViewerFromCommandLine, path])

def main():
    if "-e" in sys.argv:
        os.system("$EDITOR " + path_notebook_index)
        sys.exit()

    userinput = subprocess.check_output(f"{path_input_processor} " + ' '.join(sys.argv[1:]), shell=True)
    indexlist = subprocess.check_output(f"{path_get_filepaths} {path_notebook_folder} {path_notebook_index}", shell=True)
    userinput = userinput.decode("utf-8")[:-1].split('\n') # bytestring to list
    indexlist = indexlist.decode("utf-8")[:-1].split('\n') # bytestring to list
    paths_to_open = []

    if substring_in_list("ERROR", userinput):
        # If a program run returns an error, pass the error to the user and exit the program
        print('\n'.join(userinput))
        sys.exit()
    
    for i in userinput:
        file_index = substring_in_list(i, indexlist)
        if file_index != -1:
            # print(str_prefix_info + i + " file present.")
            # print(str_prefix_info + "Path: " + indexlist[file_index+1])
            paths_to_open.append("\"" + indexlist[file_index+1] + "\"")
            # Add quotation marks to the beginning and end in case the file path contains spaces
        else:
            # print(str_prefix_err + i + " file missing.")
            pass    
    
    if len(paths_to_open) > 0:
        # openImage(' '.join(paths_to_open)) # Error when given multiple images
        os.system("open " + ' '.join(paths_to_open))
    sys.exit()


if __name__ == "__main__":
    main()
