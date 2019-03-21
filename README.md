cetus
=====

lightning-fast file navigator

Tested with ruby 2.5

Latest changes:
2019-03-04 - q is quit key, not Q
           - show directories first, then files.
           - trying not to pollute main screen/terminal with listings (i.e. use alt screen)
           - C-s to select (toggle) current file

2018-03-12 - now using LEFT and RIGHT arrow keys to go down into a directory, or up to higher directory.
Also, pressing RIGHT ARROW on a file with open the file.
Previously RIGHT and LEFT arrows would move to next or previous columns, i have put this on left and right square bracket.

2018-03-13 - unable to push new gem 0.1.16 to rubygems.


## Selecting a file

There are two ways of selecting a file.

1. Pressing C-s on a file.
2. Use hotkey (on left of file) to select without having to navigate.

While using C-s marks a file as selected, pressing the hotkey will either open
the file using PAGER or EDITOR depending on current mode.

## Multiple Selection of files

1. Press C-s on multiple files.
2. Press `@` to enter multiple select mode.
Now press the hotkey (left of file) to select it.

To execute an action on multiple (or single) files, you may press `C-x` and choose
an action such as move or delete, etc.

You may also select all files with the same extension as current file. Invoke the
filter menu using Tilde-F. Now select `x` or `:extension`.

`Tilde-y` is the selection menu. M-a is select all, M-A is unselect all.

## Moving multiple files

First select multiple files by the above means.

Now there are two ways to move selected files to another directory.

1. Press `C-x m` and type the name of the directory at the prompt.

2. Navigate to the target directory, and then press `C-x m` and type "." at the prompt.

## Copying files to another directory.

Use the same procedure as for moving files but press `C-x c`

1. Press `C-x c` and then type the name of the target directory at the prompt.

2. Navigate to the target directory, and press `C-x c`, and type '.' at the prompt.


fork of lyra with a different hotkey idea. Use this for quickly navigating your file system using hotkeys
and bookmarks, and executing commands on single or multiple files easily.

See https://github.com/rkumar/lyra for detailed info of usage.

*lyra* uses keys from 1-9a-zA-Z for hotkeying file. This means that it leaves no keys
for other commands other than control keys, alt-keys, and punctuation keys. Also,
only 60 files can be shown at a time on a screen.

*cetus* tries another approach: it only uses lower case alphabets a-z (thus allowing us to use upper case, and numbers for other purposes).

It also maps z and Z which are at a convenient location. If there are more than 24 then za-zz are used. if the file exceed even that, then the range Za-ZZ is used. This means that larger screens will be filled with file names (upto ROWS * 3), and the user can even specify the number of columns. I've tried with 6. The remainder files gets an index of "&rt;" (right arrow) which means that if one presses right arrow then the indexing starts from the second column. RIGHT and LEFT arrow can be used to move indexing.

Experimentally added cursor movements which currently is only used if you get into a so-called visual mode, by pressing C-Space, moving up and down arrow and C-d and C-b will start adding to selection.
I did this since I was selecting quite a few files to delete in some old directory and would have liked some range delete. One can, of course, select files for a regex by pressing "/" giving a regex, and then using M-a to select all. Clear selection with M-A (Alt-Shift-a).

The cursor position shows up as a greater than sign, I hope not to implement all of zfm here. It's mainly used only to select multiple files that are contiguous.


Press C-x to execute actions on selected files. A menu of actions is displayed.
Or Press one of several commands after selecting files such as "D" for delete, or "M" to use your man-pager.
Or else press "D" and you will be prompted to enter a file shortcut to delete. The `rmtrash` command is called for delete.

You can bind other capital letters to any external command. If there are selected files, they will be passed to the command, else you will be prompted to select a file.

The rest is similar to lyra. Some key points are highlighted here.

* Create bookmarks for often used directories using Alt-m. Then access them using single-quote and upper character.
  You have to be inside the directory when saving a new bookmark. e.g. `'P`. This is a fast way of jumping directories. I've got "P" mapped to projects, and "Z" to zfm, and so forth.

* Single-quote and small letter jumps to the first file starting with given letter. e.g. `'s`

* Space-bar pages, also Alt n and p. Ctrl-d and Ctrl-b goes down 10 rows.

* Backtick is the main menu, which has options for sorting, filtering, seeing often used dirs and files, choosing from dirs in the `z` database, choosing used files from the `.viminfo` file, etc.

Other than using bookmarks, you can jump quickly to other directories or open files using BACKTICK and the releant option which should become part of muscle memory very fast.

* Use Alt-d and Alt-f to see used directories and used files. Used directories are those dirs in which you have opened a file, not all dirs you've traversed. Certain directories are added to this list to make it more useful such as GEM_HOME, RUBYPATH, GEM_PATH, RUBYLIB, PYTHONPATH and PYTHONHOME.

* By default selecting a file invokes $EDITOR, the default command can be changed from the menu. While on a file, pressing C-e opens in EDITOR, and C-p opens in PAGER.

* Switch between editor mode and page mode. OFten you wish to quickly view files (maybe for deleting or moving). You don't want these files to get listed in .viminfo. Switching to pager mode, invokes your $MANPAGER on selected files which makes navigation faster. Set `most` to your MANPAGER.

* use Alt+ and Alt- to increase or decrease the number of columns shown on screen. By default 3 are shown.

* Use '=' to toggle hidden files, long listing, ignore case , pager/editor mode, etc.

* Use slash "/" to run a regex on the dir listing.

* Use question "?" to view help (was directory tree earlier)

* Use ESCAPE or C-c to clear any filter, regex, sort order, sub-listing etc

* TAB switches between various views such as order by modified time, order by access time, dirs only, oldest files etc.

* Comma goes to parent directory, period (dot) pops directory stack.

* Plus sign allows user to enter directory to go to. If it does not exist, home dir is checked, else ENV var by that names is checked, else if its a file that is opened.

* Use BACKTICK "a" for using `ack` in the current dir. Then you can select from listed files and edit or do whatever. Similarly, BACKTICK "l" for running `locate`, and BACKTICK "/" for running `find`.

* For small projects with more directories and few files, traversal can be a pain. Now, `dirtree` gives directory tree, and tree gives the entire tree of files and dirs to get to a file deep within instantly. Dirtree is mapped to BACKTICK-t and F3. Tree is mapped to BACKTICK-4 and F4.
Thus, F2 gives only child dirs in current dir, F3 gives recursive directories and F4 gives the entire tree.

* Note that I use readline for most entries, so you can press UP arrow to get previous entries.

* A new enhanced list mode (Which can be toggled off), which tries to add more files to the list if there are very few shown:
   - it detects a rubygem dir and shows a few recent files from bin and lib
   - if there's only one file in the dir and it is a dir, it expands it
   - if there are less than 15 files in list, it gets the recently modified and recently accessed
     dir/s and shows the most recent file from each.

## Requirements ##

Requires ruby 1.9.3 or higher, and uses zsh for globbing.
Uses $EDITOR and $MANPAGER or $PAGER.

Optionally uses ack, locate, find for options with that name. You may replace ack with ag or other.
Optionally has interface to `z` and `viminfo` -- can be replaced with what you use.

## INSTALL ##

(I have renamed cetus.rb to cetus and created a gem, so its in the bin folder)

Copy cetus to somewhere on your path, e.g. $HOME/bin

     cp cetus ~/bin

     alias c=~/bin/cetus

     $ c

Or :

     gem install cetus
     alias c=cetus

To quit, press "Q" or :q or :wq or :x. If you have created bookmarks, they will be saved with :x and :wq. :q will warn if you quitting with unsaved bookmarks. Used files and dirs are also saved when saving happens. However, if you have not saved bookmarks then you will not be prompted to save used dirs and files.

Be sure to try zfm, too. zfm requires only zsh and contains a VIM mode too if that interests you.
See https://github.com/rkumar/zfm

## Credits ##

Cetus refers to the constellation and means a whale if memory serves me correctly.
