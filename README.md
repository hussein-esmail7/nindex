# notebook-index
A program to quickly find a scanned page from a given index and open it if it exists.

## Table of Contents
- [What is this?](#what-is-this)
- [Requirements](#requirements)
- [Installation](#installation)
    - [Installing Through Git](#installing-through-git)
- [Running the Program](#running-the-program)
- [Arguments](#arguments)
- [Donate](#donate)

## What is this?

## Requirements
- fzf

## Installation
At the moment, you can only `git clone` this repository, but I am hoping to put
it on Homebrew/AUR soon.

## Installing Through Git
```
git clone https://github.com/hussein-esmail7/notebook-index
cd notebook-index
```
If you want to run this program in Terminal just by typing the program name,
you would have to add an alias in your `.bashrc` file. For example, if you want it to run when you type just `n`, you would put this line in your `.bashrc`:
```
alias n='path/to/folder/notebook-index/notebook-index.sh
```

## Running the program
To use this program, you have to make sure you are in the correct directory,
and that the file has executable permission.
```
cd notebook-index
chmod +x notebook-index.sh
```

Personally, I assigned the file `notebook-index.sh` as an alias in my `.bashrc`
so whichever directory I'm in, I can just type `n <args>` and it will run the program in whatever directory I'm in.

## Arguments
> **Note**
> For this section, I'm assuming you have read [How I Format My Notebooks](#how-i-format-my-notebooks).
When running this program, you can type in the notebook number


## Donate
[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/husseinesmail)
