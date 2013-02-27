cetus
=====

fork of lyra with a different hotkey idea. Use this for quickly navigating your file system using hotkeys
and bookmarks, and executing commands on single or multiple files easily.

See https://github.com/rkumar/lyra for detailed info of usage.

*lyra* uses keys from 1-9a-zA-Z for hotkeying file. This means that it leaves no keys
for other commands other than control keys, alt-keys, and punctuation keys. Also,
only 60 files can be shown at a time.

*cetus* tries another approach: it only uses lower case alphabets a-z (thus allowing us to use upper case, and numbers for other purposes).

It also maps z and Z which are at a convenient location. If there are more than 24 then za-zz are used. if the file exceed even that, then the range Za-ZZ is used. This means that larger screens will be filled with file names (upto ROWS * 3), and the user can even specify the number of columns. I've tried with 6. The remainder files gets an index of "&rt;" (right arrow) which means that if one presses right arrow then the indexing starts from the second column. RIGHT and LEFT arrow can be used to move indexing.

## INSTALL ##

Copy cetus.rb to somewhere on your path, e.g. $HOME/bin

     cp cetus.rb ~/bin

     alias c=~/bin/cetus.rb

     $ c

Be sure to try lyra and zfm too.
See https://github.com/rkumar/zfm

## Credits ##

Cetus refers to the constellation and means a whale if memory serves me correctly.
