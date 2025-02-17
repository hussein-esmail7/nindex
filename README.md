# nindex
A program to quickly find a scanned page from a given index and open it if it exists.

## Table of Contents
- [What is this?](#what-is-this)
- [Requirements](#requirements)
- [Installation](#installation)
    - [Installing Through Git](#installing-through-git)
- [Configuration File](#configuration-file)
- [Running the Program](#running-the-program)
- [Arguments](#arguments)
- [Donate](#donate)

## What is this?
This program is used to quickly open a scanned notebook page quickly via
Terminal.

## Requirements
- fzf
- Some default values in your configuration file. See [Configuration File](#configuration-file).

## Installation
At the moment, you can only `git clone` this repository, but I am hoping to put
it on Homebrew/AUR soon.

## Installing Through Git
```
git clone https://github.com/hussein-esmail7/nindex
cd nindex
```
If you want to run this program in Terminal just by typing the program name,
you would have to add an alias in your `.bashrc` file. For example, if you want it to run when you type just `n`, you would put this line in your `.bashrc`:
```
alias n='path/to/folder/nindex/nindex.sh
```

## Configuration File
The configuration path this file should be at is `$HOME/.config/nindex/config`.

There are some required values to operate this program. The configuration file
is treated as a bash program, so variables would have to be defined like in
bash (i.e.: no spaces between the "=", etc.).

Required variables:
```
NOTEBOOK_FOLDER: Path to the notebook folder
NOTEBOOK_INDEX: Path to the .tex index file
```

Optional variables:
```
FILE_LIST: Path to where you want to store the cache file. Default: $HOME/.config/nindex/cache.txt
FZF_PROMPT: Prompt for fzf. Default: "Notebook Search: "
STR_EMPTY: What to display if a page has no title in the index. Default: "=== NO ENTRY ==="
```

## Running the program
To use this program, you have to make sure you are in the correct directory,
and that the file has executable permission.
```
cd nindex
chmod +x nindex.sh
```

Personally, I assigned the file `nindex.sh` as an alias in my `.bashrc`
so whichever directory I'm in, I can just type `n <args>` and it will run the program in whatever directory I'm in.

## Arguments
> **Note**
> For this section, I'm assuming you have read [How I Format My Notebooks](#how-i-format-my-notebooks).
When running this program, you can type in the notebook number

## How I Format My Notebooks
See https://husseinesmail.xyz/notebooks

## Donate
[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/husseinesmail)
