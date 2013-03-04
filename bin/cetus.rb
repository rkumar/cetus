#!/usr/bin/env ruby
# ----------------------------------------------------------------------------- #
#         File: cetus.rb
#  Description: Fast file navigation, a tiny version of zfm
#               but with a diffrent indexing mechanism
#       Author: rkumar http://github.com/rkumar/cetus/
#         Date: 2013-02-17 - 17:48
#      License: GPL
#  Last update: 2013-03-03 18:01
# ----------------------------------------------------------------------------- #
#  cetus.rb  Copyright (C) 2012-2013 rahul kumar
require 'readline'
require 'io/wait'
# http://www.ruby-doc.org/stdlib-1.9.3/libdoc/shellwords/rdoc/Shellwords.html
require 'shellwords'
require 'fileutils'
# -- requires 1.9.3 for io/wait
# -- cannot do with Highline since we need a timeout on wait, not sure if HL can do that

## INSTALLATION
# copy into PATH
# alias c=~/bin/cetus.rb
# c
VERSION="0.1.1-b"
O_CONFIG=true
CONFIG_FILE="~/.lyrainfo"

$bindings = {}
$bindings = {
  "`"   => "main_menu",
  "="   => "toggle_menu",
  "!"   => "command_mode",
  "@"   => "selection_mode_toggle",
  "M-a" => "select_all",
  "M-A" => "unselect_all",
  ","   => "goto_parent_dir",
  "+"   => "goto_dir",
  "."   => "pop_dir",
  ":"   => "subcommand",
  "'"   => "goto_bookmark",
  "/"   => "enter_regex",
  "M-p"   => "prev_page",
  "M-n"   => "next_page",
  "SPACE"   => "next_page",
  "M-f"   => "select_visited_files",
  "M-d"   => "select_used_dirs",
  "M-b"   => "select_bookmarks",
  "M-m"   => "create_bookmark",
  "M-M"   => "show_marks",
  "C-c"   => "escape",
  "ESCAPE"   => "escape",
  "TAB"   => "views",
  "C-i"   => "views",
  "?"   => "child_dirs",
  "ENTER"   => "select_current",
  "D"   => "delete_file",
  "M"   => "file_actions most",
  "Q"   => "quit_command",
  "RIGHT"   => "column_next",
  "LEFT"   => "column_next 1",
  "C-x"   => "file_actions",
  "M--"   => "columns_incdec -1",
  "M-+"   => "columns_incdec 1",
  "S"     =>  "command_file list y ls -lh",
  "L"     =>  "command_file Page n less",
  "C-d"   =>  "cursor_scroll_dn",
  "C-b"   =>  "cursor_scroll_up",
  "UP"   =>  "cursor_up",
  "DOWN"   =>  "cursor_dn",
  "C-SPACE" => "visual_mode_toggle",

  "M-?"   => "print_help",
  "F1"   => "print_help",
  "F2"   => "child_dirs"

}

## clean this up a bit, copied from shell program and macro'd 
$kh=Hash.new
$kh["OP"]="F1"
$kh["[A"]="UP"
$kh["[5~"]="PGUP"
$kh['']="ESCAPE"
KEY_PGDN="[6~"
KEY_PGUP="[5~"
## I needed to replace the O with a [ for this to work
#  in Vim Home comes as ^[OH whereas on the command line it is correct as ^[[H
KEY_HOME='[H'
KEY_END="[F"
KEY_F1="OP"
KEY_UP="[A"
KEY_DOWN="[B"

$kh[KEY_PGDN]="PgDn"
$kh[KEY_PGUP]="PgUp"
$kh[KEY_HOME]="Home"
$kh[KEY_END]="End"
$kh[KEY_F1]="F1"
$kh[KEY_UP]="UP"
$kh[KEY_DOWN]="DOWN"
KEY_LEFT='[D' 
KEY_RIGHT='[C' 
$kh["OQ"]="F2"
$kh["OR"]="F3"
$kh["OS"]="F4"
$kh[KEY_LEFT] = "LEFT"
$kh[KEY_RIGHT]= "RIGHT"
KEY_F5='[15~'
KEY_F6='[17~'
KEY_F7='[18~'
KEY_F8='[19~'
KEY_F9='[20~'
KEY_F10='[21~'
$kh[KEY_F5]="F5"
$kh[KEY_F6]="F6"
$kh[KEY_F7]="F7"
$kh[KEY_F8]="F8"
$kh[KEY_F9]="F9"
$kh[KEY_F10]="F10"

## get a character from user and return as a string
# Adapted from:
#http://stackoverflow.com/questions/174933/how-to-get-a-single-character-without-pressing-enter/8274275#8274275
# Need to take complex keys and matc against a hash.
def get_char
  begin
    system("stty raw -echo 2>/dev/null") # turn raw input on
    c = nil
    #if $stdin.ready?
      c = $stdin.getc
      cn=c.ord
      return "ENTER" if cn == 10 || cn == 13
      return "BACKSPACE" if cn == 127
      return "C-SPACE" if cn == 0
      return "SPACE" if cn == 32
      # next does not seem to work, you need to bind C-i
      return "TAB" if cn == 8
      if cn >= 0 && cn < 27
        x= cn + 96
        return "C-#{x.chr}"
      end
      if c == ''
        buff=c.chr
        while true
          k = nil
          if $stdin.ready?
            k = $stdin.getc
            #puts "got #{k}"
            buff += k.chr
          else
            x=$kh[buff]
            return x if x
            #puts "returning with  #{buff}"
            if buff.size == 2
              ## possibly a meta/alt char
              k = buff[-1]
              return "M-#{k.chr}"
            end
            return buff
          end
        end
      end
    #end
    return c.chr if c
  ensure
    #system "stty -raw echo" # turn raw input off
    system("stty -raw echo 2>/dev/null") # turn raw input on
  end
end

## GLOBALS
#$IDX="123456789abcdefghijklmnoprstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
#$IDX="abcdefghijklmnopqrstuvwxy"
$IDX=('a'..'y').to_a
$IDX.concat ('za'..'zz').to_a
$IDX.concat ('Za'..'Zz').to_a
$IDX.concat ('ZA'..'ZZ').to_a

$selected_files = Array.new
$bookmarks = {}
$mode = nil
$glines=%x(tput lines).to_i
$gcols=%x(tput cols).to_i
$grows = $glines - 3
$pagesize = 60
$gviscols = 3
$pagesize = $grows * $gviscols
$stact = 0
$editor_mode = true
$visual_block_start = nil
$pager_command = {
  :text => 'most',
  :image => 'open',
  :zip => 'tar ztvf %% | most',
  :unknown => 'open'
}
$dir_position = {}
## CONSTANTS
GMARK='*'
CURMARK='>'
MSCROLL = 10
SPACE=" "
CLEAR      = "\e[0m"
BOLD       = "\e[1m"
BOLD_OFF       = "\e[22m"
RED        = "\e[31m"
ON_RED        = "\e[41m"
GREEN      = "\e[32m"
YELLOW     = "\e[33m"
BLUE       = "\e[34m"

ON_BLUE    = "\e[44m"
REVERSE    = "\e[7m"
CURSOR_COLOR = ON_BLUE
$patt=nil
$ignorecase = true
$quitting = false
$modified = $writing = false
$visited_files = []
## dir stack for popping
$visited_dirs = []
## dirs where some work has been done, for saving and restoring
$used_dirs = []
$sorto = nil
$viewctr = 0
$history = []
$sta = $cursor = 0
$visual_mode = false
#$help = "#{BOLD}1-9a-zA-Z#{BOLD_OFF} Select #{BOLD}/#{BOLD_OFF} Grep #{BOLD}'#{BOLD_OFF} First char  #{BOLD}M-n/p#{BOLD_OFF} Paging  #{BOLD}!#{BOLD_OFF} Command Mode  #{BOLD}@#{BOLD_OFF} Selection Mode  #{BOLD}q#{BOLD_OFF} Quit"

$help = "#{BOLD}M-?#{BOLD_OFF} Help   #{BOLD}`#{BOLD_OFF} Menu   #{BOLD}!#{BOLD_OFF} Command   #{BOLD}=#{BOLD_OFF} Toggle   #{BOLD}@#{BOLD_OFF} Selection Mode  #{BOLD}Q#{BOLD_OFF} Quit "

  ## main loop which calls all other programs
def run()
  home=ENV['HOME']
  ctr=0
  config_read
  $files = `zsh -c 'print -rl -- *(#{$hidden}M)'`.split("\n")
  fl=$files.size

  selectedix = nil
  $patt=""
  $sta=0
  while true
    i = 0
    if $patt
      if $ignorecase
        $view = $files.grep(/#{$patt}/i)
      else
        $view = $files.grep(/#{$patt}/)
      end
    else 
      $view = $files
    end
    fl=$view.size
    $sta = 0 if $sta >= fl || $sta < 0
    $viewport = $view[$sta, $pagesize]
    fin = $sta + $viewport.size
    $title ||= Dir.pwd.sub(home, "~")
    system("clear")
    # title
    print "#{GREEN}#{$help}  #{BLUE}cetus #{VERSION}#{CLEAR}\n"
    t = "#{$title}  #{$sta + 1} to #{fin} of #{fl}  #{$sorto} F:#{$filterstr}"
    t = t[t.size-$gcols..-1] if t.size >= $gcols
    print "#{BOLD}#{t}#{CLEAR}\n"
    ## nilling the title means a superimposed one gets cleared.
    #$title = nil
    # split into 2 procedures so columnate can e clean and reused.
    buff = format $viewport
    buff = columnate buff, $grows
    # needed the next line to see how much extra we were going in padding
    #buff.each {|line| print "#{REVERSE}#{line}#{CLEAR}\n" }
    buff.each {|line| print line, "\n"  }
    print
    # prompt
    #print "#{$files.size}, #{view.size} sta=#{sta} (#{patt}): "
    _mm = ""
    _mm = "[#{$mode}] " if $mode
    print "\r#{_mm}#{$patt} >"
    ch = get_char
    #puts
    #break if ch == "q"
    #elsif  ch =~ /^[1-9a-zA-Z]$/
    if  ch =~ /^[a-zZ]$/
      # hint mode
      select_hint $viewport, ch
      ctr = 0
    elsif ch == "BACKSPACE"
      $patt = $patt[0..-2]
      ctr = 0
    else
      #binding = $bindings[ch]
      x = $bindings[ch]
      x = x.split if x
      if x
        binding = x.shift
        args = x
        send(binding, *args) if binding
      else
        #perror "No binding for #{ch}"
      end
      #p ch
    end
    break if $quitting
  end
  puts "bye"
  config_write if $writing
end

## code related to long listing of files
GIGA_SIZE = 1073741824.0
MEGA_SIZE = 1048576.0
KILO_SIZE = 1024.0

# Return the file size with a readable style.
def readable_file_size(size, precision)
  case
    #when size == 1 : "1 B"
  when size < KILO_SIZE then "%d B" % size
  when size < MEGA_SIZE then "%.#{precision}f K" % (size / KILO_SIZE)
  when size < GIGA_SIZE then "%.#{precision}f M" % (size / MEGA_SIZE)
  else "%.#{precision}f G" % (size / GIGA_SIZE)
  end
end
## format date for file given stat
def date_format t
  t.strftime "%Y/%m/%d"
end
## 
#
# print in columns
# ary - array of data
# sz  - lines in one column
#
def columnate ary, sz
  buff=Array.new
  return buff if ary.nil? || ary.size == 0
  
  # determine width based on number of files to show
  # if less than sz then 1 col and full width
  #
  wid = 30
  ars = ary.size
  ars = [$pagesize, ary.size].min
  d = 0
  if ars <= sz
    wid = $gcols - d
  else
    tmp = (ars * 1.000/ sz).ceil
    wid = $gcols / tmp - d
  end
  #elsif ars < sz * 2
    #wid = $gcols/2 - d
  #elsif ars < sz * 3
    #wid = $gcols/3 - d
  #else
    #wid = $gcols/$gviscols - d
  #end

  # ix refers to the index in the complete file list, wherease we only show 60 at a time
  ix=0
  while true
    ## ctr refers to the index in the column
    ctr=0
    while ctr < sz

      f = ary[ix]
      fsz = f.size
      if fsz > wid
        f = f[0, wid-2]+"$ "
        ## we do the coloring after trunc so ANSI escpe seq does not get get
        if ix + $sta == $cursor
          f = "#{CURSOR_COLOR}#{f}#{CLEAR}"
        end
      else
        ## we do the coloring before padding so the entire line does not get padded, only file name
        if ix + $sta == $cursor
          f = "#{CURSOR_COLOR}#{f}#{CLEAR}"
        end
        #f = f.ljust(wid)
        f << " " * (wid-fsz)
      end

      if buff[ctr]
        buff[ctr] += f
      else
        buff[ctr] = f
      end

      ctr+=1
      ix+=1
      break if ix >= ary.size
    end
    break if ix >= ary.size
  end
  return buff
end
## formats the data with number, mark and details 
def format ary
  #buff = Array.new
  buff = Array.new(ary.size)
  return buff if ary.nil? || ary.size == 0

  # determine width based on number of files to show
  # if less than sz then 1 col and full width
  #
  # ix refers to the index in the complete file list, wherease we only show 60 at a time
  ix=0
  ctr=0
  ary.each do |f|
    ## ctr refers to the index in the column
    ind = get_shortcut(ix)
    mark=SPACE
    cur=SPACE
    cur = CURMARK if ix + $sta == $cursor
    mark=GMARK if $selected_files.index(ary[ix])

    if $long_listing
      begin
        unless File.exist? f
          last = f[-1]
          if last == " " || last == "@" || last == '*'
            stat = File.stat(f.chop)
          end
        else
          stat = File.stat(f)
        end
        f = "%10s  %s  %s" % [readable_file_size(stat.size,1), date_format(stat.mtime), f]
      rescue Exception => e
        f = "%10s  %s  %s" % ["?", "??????????", f]
      end
    end

    s = "#{ind}#{mark}#{cur}#{f}"
    # I cannot color the current line since format does the chopping
    # so not only does the next lines alignment get skeweed, but also if the line is truncated
    # then the color overflows.
    #if ix + $sta == $cursor
      #s = "#{RED}#{s}#{CLEAR}"
    #end

    buff[ctr] = s

    ctr+=1
    ix+=1
  end
  return buff
end
## select file based on key pressed
def select_hint view, ch
  # a to y is direct
  # if x or z take a key IF there are those many
  #
  ix = get_index(ch, view.size)
  if ix
    f = view[ix]
    return unless f
    $cursor = $sta + ix

    if $mode == 'SEL'
      toggle_select f
    elsif $mode == 'COM'
      run_command f
    else
      open_file f
    end
    #selectedix=ix
  end
end
## toggle selection state of file
def toggle_select f
  if $selected_files.index f
    $selected_files.delete f
  else
    $selected_files.push f
  end
end
## open file or directory
def open_file f
  return unless f
  if f[0] == "~"
    f = File.expand_path(f)
  end
  unless File.exist? f
    # this happens if we use (T) in place of (M) 
    # it places a space after normal files and @ and * which borks commands
    last = f[-1]
    if last == " " || last == "@" || last == '*'
      f = f.chop
    end
  end
  nextpos = nil

  # could be a bookmark with position attached to it
  if f.index(":")
    f, nextpos = f.split(":")
  end
  if File.directory? f
    save_dir_pos
    change_dir f, nextpos
  elsif File.readable? f
    $default_command ||= "$EDITOR"
    if !$editor_mode
      ft = filetype f
      if ft
        comm = $pager_command[ft]
      else
        comm = $pager_command[File.extname(f)]
        comm = $pager_command["unknown"] unless comm
      end
    else
      comm = $default_command
    end
    comm ||= $default_command
    if comm.index("%%")
      comm = comm.gsub("%%", Shellwords.escape(f))
    else
      comm = comm + " #{Shellwords.escape(f)}"
    end
    system("#{comm}")
    f = Dir.pwd + "/" + f if f[0] != '/'
    $visited_files.insert(0, f)
    push_used_dirs Dir.pwd
  else
    perror "open_file: (#{f}) not found"
      # could check home dir or CDPATH env variable DO
  end
end

## run command on given file/s
#   Accepts command from user
#   After putting readline in place of gets, pressing a C-c has a delayed effect. It goes intot
#   exception bloack after executing other commands and still does not do the return !
def run_command f
  files=nil
  case f
  when Array
    # escape the contents and create a string
    files = Shellwords.join(f)
  when String
    files = Shellwords.escape(f)
  end
  print "Run a command on #{files}: "
  begin
    #Readline::HISTORY.push(*values) 
    command = Readline::readline('>', true)
    #command = gets().chomp
    return if command.size == 0
    print "Second part of command: "
    #command2 = gets().chomp
    command2 = Readline::readline('>', true)
    puts "#{command} #{files} #{command2}"
    system "#{command} #{files} #{command2}"
  rescue Exception => ex
    perror "Canceled command, press a key"
    return
  end
  begin
  rescue Exception => ex
  end

  refresh
  puts "Press a key ..."
  push_used_dirs Dir.pwd
  get_char
end

## cd to a dir
def change_dir f, pos=nil
  $visited_dirs.insert(0, Dir.pwd)
  f = File.expand_path(f)
  Dir.chdir f
  $filterstr ||= "M"
  $files = `zsh -c 'print -rl -- *(#{$sorto}#{$hidden}#{$filterstr})'`.split("\n")
  post_cd
  if pos
    # convert curpos to sta also
    #$cursor = pos.to_i
    goto_line pos.to_i
  end
end

## clear sort order and refresh listing, used typically if you are in some view
#  such as visited dirs or files
def escape
  $sorto = nil
  $viewctr = 0
  $title = nil
  $filterstr = "M"
  visual_block_clear
  refresh
end

## refresh listing after some change like option change, or toggle
def refresh
    $filterstr ||= "M"
    $files = `zsh -c 'print -rl -- *(#{$sorto}#{$hidden}#{$filterstr})'`.split("\n")
    $patt=nil
    $title = nil
end
#
## unselect all files
def unselect_all
  $selected_files = []
end

## select all files
def select_all
  $selected_files = $view.dup
end

## accept dir to goto and change to that ( can be a file too)
def goto_dir
  print "Enter path: "
  begin
    path = gets.chomp
    #rescue => ex
  rescue Exception => ex
    perror "Cancelled cd, press a key"
    return
  end
  f = File.expand_path(path)
  unless File.directory? f
    ## check for env variable
    tmp = ENV[path]
    if tmp.nil? || !File.directory?( tmp )
      ## check for dir in home 
      tmp = File.expand_path("~/#{path}")
      if File.directory? tmp
        f = tmp
      end
    else
      f = tmp
    end
  end

  open_file f
end

## toggle mode to selection or not
#  In selection, pressed hotkey selects a file without opening, one can keep selecting
#  (or deselecting).
#
def selection_mode_toggle
  if $mode == 'SEL'
    # we seem to be coming out of select mode with some files
    if $selected_files.size > 0
      run_command $selected_files
    end
    $mode = nil
  else
    #$selection_mode = !$selection_mode
    $mode = 'SEL'
  end
end
## toggle command mode
def command_mode
  if $mode == 'COM'
    $mode = nil
    return
  end
  $mode = 'COM'
end
def goto_parent_dir
  change_dir ".."
end
## This actually filters, in zfm it goes to that entry since we have a cursor there
#
def goto_entry_starting_with fc=nil
  unless fc
    print "Entries starting with: "
    fc = get_char
  end
  return if fc.size != 1
  ## this is wrong and duplicates the functionality of /
  #  It shoud go to cursor of item starting with fc
  $patt = "^#{fc}"
end
def goto_bookmark ch=nil
  unless ch
    print "Enter bookmark char: "
    ch = get_char
  end
  if ch =~ /^[A-Z]$/
    d = $bookmarks[ch]
    # this is if we use zfm's bookmarks which have a position
    # this way we leave the position as is, so it gets written back
    nextpos = nil
    if d
      if d.index(":")
        ix = d.index(":")
        nextpos = d[ix+1..-1]
        d = d[0,ix]
      end
      change_dir d, nextpos
    else
      perror "#{ch} not a bookmark"
    end
  else
    #goto_entry_starting_with ch
    file_starting_with ch
  end
end


## take regex from user, to run on files on screen, user can filter file names
def enter_regex
  print "Enter (regex) pattern: "
  $patt = gets().chomp
  ctr = 0
end
def next_page
  $sta += $pagesize
end
def prev_page
  $sta -= $pagesize
end
def print_help
  system("clear")
  puts "HELP"
  puts
  puts "To open a file or dir press 1-9 a-z A-Z "
  puts "Command Mode: Will prompt for a command to run on a file, after selecting using hotkey"
  puts "Selection Mode: Each selection adds to selection list (toggles)"
  puts "                Upon exiting mode, user is prompted for a command to run on selected files"
  puts
  ary = []
  $bindings.each_pair { |k, v| ary.push "#{k.ljust(7)}  =>  #{v}" }
  ary = columnate ary, $grows - 7
  ary.each {|line| print line, "\n"  }
  get_char

end
def show_marks
  puts
  puts "Bookmarks: "
  $bookmarks.each_pair { |k, v| puts "#{k.ljust(7)}  =>  #{v}" }
  puts
  print "Enter bookmark to goto: "
  ch = get_char
  goto_bookmark(ch) if ch =~ /^[A-Z]$/
end
# MENU MAIN -- keep consistent with zfm
def main_menu
  h = { 
    :a => :ack,
    "/" => :ffind,
    :l => :locate,
    :v => :viminfo,
    :z => :z_interface,
    :d => :child_dirs,
    :s => :sort_menu, 
    :F => :filter_menu,
    :c => :command_menu ,
    :B => :bindkey_ext_command,
    :x => :extras
  }
  menu "Main Menu", h
end
def toggle_menu
  h = { :h => :toggle_hidden, :c => :toggle_case, :l => :toggle_long_list , "1" => :toggle_columns}
  menu "Toggle Menu", h
end
def menu title, h
  return unless h

  pbold "#{title}"
  h.each_pair { |k, v| puts " #{k}: #{v}" }
  ch = get_char
  binding = h[ch]
  binding = h[ch.to_sym] unless binding
  if binding
    if respond_to?(binding, true)
      send(binding)
    end
  end
  return ch, binding
end
def toggle_menu
  h = { :h => :toggle_hidden, :c => :toggle_case, :l => :toggle_long_list , "1" => :toggle_columns}
  ch, menu_text = menu "Toggle Menu", h
  case menu_text
  when :toggle_hidden
    $hidden = $hidden ? nil : "D"
    refresh
  when :toggle_case
    #$ignorecase = $ignorecase ? "" : "i"
    $ignorecase = !$ignorecase
    refresh
  when :toggle_columns
    $gviscols = 3 if $gviscols == 1
    #$long_listing = false if $gviscols > 1 
    x = $grows * $gviscols
    $pagesize = $pagesize==x ? $grows : x
  when :toggle_long_list
    $long_listing = !$long_listing
    if $long_listing
      $gviscols = 1
      $pagesize = $grows
    else
      x = $grows * $gviscols
      $pagesize = $pagesize==x ? $grows : x
    end
    refresh
  end
end

def sort_menu
  lo = nil
  h = { :n => :newest, :a => :accessed, :o => :oldest, 
    :l => :largest, :s => :smallest , :m => :name , :r => :rname, :d => :dirs, :c => :clear }
  ch, menu_text = menu "Sort Menu", h
  case menu_text
  when :newest
    lo="om"
  when :accessed
    lo="oa"
  when :oldest
    lo="Om"
  when :largest
    lo="OL"
  when :smallest
    lo="oL"
  when :name
    lo="on"
  when :rname
    lo="On"
  when :dirs
    lo="/"
  when :clear
    lo=""
  end
  ## This needs to persist and be a part of all listings, put in change_dir.
  $sorto = lo
  $files = `zsh -c 'print -rl -- *(#{lo}#{$hidden}M)'`.split("\n") if lo
  $title = nil
  #$files =$(eval "print -rl -- ${pattern}(${MFM_LISTORDER}$filterstr)")
end

def command_menu
  ## 
  #  since these involve full paths, we need more space, like only one column
  #
  ## in these cases, getting back to the earlier dir, back to earlier listing
  # since we've basically overlaid the old listing
  #
  # should be able to sort THIS listing and not rerun command. But for that I'd need to use
  # xargs ls -t etc rather than the zsh sort order. But we can run a filter using |.
  #
  h = { :t => :today, :D => :default_command }
  if $editor_mode 
    h[:e] = :pager_mode
  else
    h[:e] = :editor_mode
  end
  ch, menu_text = menu "Command Menu", h
  case menu_text
  when :pager_mode
    $editor_mode = false
    $default_command = ENV['MANPAGER'] || ENV['PAGER']
  when :editor_mode
    $editor_mode = true
    $default_command = nil
  when :ffind
    ffind
  when :locate
    locate
  when :today
    $files = `zsh -c 'print -rl -- *(#{$hidden}Mm0)'`.split("\n")
    $title = "Today's files"
  when :default_command
    print "Selecting a file usually invokes $EDITOR, what command do you want to use repeatedly on selected files: "
    $default_command = gets().chomp
    if $default_command != ""
      print "Second part of command (maybe blank): "
      $default_command2 = gets().chomp
    else
      print "Cleared default command, will default to $EDITOR"
      $default_command2 = nil
      $default_command = nil
    end
  end
end
def extras
  h = { "1" => :one_column, "2" => :multi_column, :c => :columns, :r => :config_read , :w => :config_write}
  ch, menu_text = menu "Extras Menu", h
  case menu_text
  when :one_column
    $pagesize = $grows
  when :multi_column
    #$pagesize = 60
    $pagesize = $grows * $gviscols
  when :columns
    print "How many columns to show: 1-6 [current #{$gviscols}]? "
    ch = get_char
    ch = ch.to_i
    if ch > 0 && ch < 7
      $gviscols = ch.to_i
      $pagesize = $grows * $gviscols
    end
  end
end
def filter_menu
  h = { :d => :dirs, :f => :files, :e => :emptydirs , "0" => :emptyfiles}
  ch, menu_text = menu "Filter Menu", h
  files = nil
  case menu_text
  when :dirs
    $filterstr = "/M"
    files = `zsh -c 'print -rl -- *(#{$sorto}/M)'`.split("\n")
    $title = "Filter: directories only"
  when :files
    $filterstr = "."
    files = `zsh -c 'print -rl -- *(#{$sorto}#{$hidden}.)'`.split("\n")
    $title = "Filter: files only"
  when :emptydirs
    $filterstr = "/D^F"
    files = `zsh -c 'print -rl -- *(#{$sorto}/D^F)'`.split("\n")
    $title = "Filter: empty directories"
  when :emptyfiles
    $filterstr = ".L0"
    files = `zsh -c 'print -rl -- *(#{$sorto}#{$hidden}.L0)'`.split("\n")
    $title = "Filter: empty files"
  end
  if files
    $files = files
    $stact = 0
  end
end
def select_used_dirs
  $title = "Used Directories"
  $files = $used_dirs.uniq
end
def select_visited_files
  # not yet a unique list, needs to be unique and have latest pushed to top
  $title = "Visited Files"
  $files = $visited_files.uniq
end
def select_bookmarks
  $title = "Bookmarks"
  $files = $bookmarks.values
end

## part copied and changed from change_dir since we don't dir going back on top
#  or we'll be stuck in a cycle
def pop_dir
  # the first time we pop, we need to put the current on stack
  if !$visited_dirs.index(Dir.pwd)
    $visited_dirs.push Dir.pwd
  end
  ## XXX make sure thre is something to pop
  d = $visited_dirs.delete_at 0
  ## XXX make sure the dir exists, cuold have been deleted. can be an error or crash otherwise
  $visited_dirs.push d
  Dir.chdir d
  $filterstr ||= "M"
  $files = `zsh -c 'print -rl -- *(#{$sorto}#{$hidden}#{$filterstr})'`.split("\n")
  post_cd
end
def post_cd
  $patt=nil
  $sta = $cursor = 0
  $title = nil
  if $selected_files.size > 0
    $selected_files = []
  end
  $visual_block_start = nil
  $stact = 0
  screen_settings
  revert_dir_pos
end
#
## read dirs and files and bookmarks from file
def config_read
  #f =  File.expand_path("~/.zfminfo")
  f =  File.expand_path(CONFIG_FILE)
  if File.readable? f
    load f
    # maybe we should check for these existing else crash will happen.
    $used_dirs.push(*(DIRS.split ":"))
    $visited_files.push(*(FILES.split ":"))
    #$bookmarks.push(*bookmarks) if bookmarks
    chars = ('A'..'Z')
    chars.each do |ch|
      if Kernel.const_defined? "BM_#{ch}"
        $bookmarks[ch] = Kernel.const_get "BM_#{ch}"
      end
    end
  end
end

## save dirs and files and bookmarks to a file
def config_write
  # Putting it in a format that zfm can also read and write
  #f1 =  File.expand_path("~/.zfminfo")
  f1 =  File.expand_path(CONFIG_FILE)
  d = $used_dirs.join ":"
  f = $visited_files.join ":"
  File.open(f1, 'w+') do |f2|  
    # use "\n" for two lines of text  
    f2.puts "DIRS=\"#{d}\""
    f2.puts "FILES=\"#{f}\""
    $bookmarks.each_pair { |k, val| 
      f2.puts "BM_#{k}=\"#{val}\""
      #f2.puts "BOOKMARKS[\"#{k}\"]=\"#{val}\""
    }
  end
  $writing = $modified = false
end

## accept a character to save this dir as a bookmark
def create_bookmark
  print "Enter (upper case) char for bookmark: "
  ch = get_char
  if ch =~ /^[A-Z]$/
    $bookmarks[ch] = "#{Dir.pwd}:#{$cursor}"
    $modified = true
  else
    perror "Bookmark must be upper-case character"
  end
end
def subcommand
  print "Enter command: "
  begin
    command = gets().chomp
  rescue Exception => ex
    return
  end
  if command == "q"
    if $modified
      print "Do you want to save bookmarks? (y/n): "
      ch = get_char
      if ch == "y"
        $writing = true
        $quitting = true
      elsif ch == "n"
        $quitting = true
        print "Quitting without saving bookmarks"
      else
        perror "No action taken."
      end
    else
      $quitting = true
    end
  elsif command == "wq"
    $quitting = true
    $writing = true
  elsif command == "x"
    $quitting = true
    $writing = true if $modified
  elsif command == "p"
    system "echo $PWD | pbcopy"
    puts "Stored PWD in clipboard (using pbcopy)"
  end
end
def quit_command
  if $modified
    puts "Press w to save bookmarks before quitting " if $modified
    print "Press another q to quit "
    ch = get_char
  else
    $quitting = true
  end
  $quitting = true if ch == "q"
  $quitting = $writing = true if ch == "w"
end

def views
  views=%w[/ om oa Om OL oL On on]
  viewlabels=%w[Dirs Newest Accessed Oldest Largest Smallest Reverse Name]
  $sorto = views[$viewctr]
  $viewctr += 1
  $viewctr = 0 if $viewctr > views.size

  $files = `zsh -c 'print -rl -- *(#{$sorto}#{$hidden}M)'`.split("\n")
  $title = viewlabels[$viewctr]

end
def child_dirs
  $title = "Child directories"
  $files = `zsh -c 'print -rl -- *(/#{$sorto}#{$hidden}M)'`.split("\n")
end
def select_current
  ## vp is local there, so i can do $vp[0]
  #open_file $view[$sta] if $view[$sta]
  open_file $view[$cursor] if $view[$cursor]
end

## create a list of dirs in which some action has happened, for saving
def push_used_dirs d=Dir.pwd
  $used_dirs.index(d) || $used_dirs.push(d)
end
def pbold text
  puts "#{BOLD}#{text}#{BOLD_OFF}"
end
def perror text
  puts "#{RED}#{text}#{CLEAR}"
  get_char
end
def pause text=" Press a key ..."
  print text
  get_char
end
## return shortcut for an index (offset in file array)
# use 2 more arrays to make this faster
#  if z or Z take another key if there are those many in view
#  Also, display ROWS * COLS so now we are not limited to 60.
def get_shortcut ix
  return "<" if ix < $stact
  ix -= $stact
  i = $IDX[ix]
  return i if i
  return "->"
end
## returns the integer offset in view (file array based on a-y za-zz and Za - Zz
# Called when user types a key
#  should we even ask for a second key if there are not enough rows
#  What if we want to also trap z with numbers for other purposes
def get_index key, vsz=999
  i = $IDX.index(key)
  return i+$stact if i
  #sz = $IDX.size
  zch = nil
  if vsz > 25
    if key == "z" || key == "Z"
      print key
      zch = get_char
      print zch
      i = $IDX.index("#{key}#{zch}")
      return i+$stact if i
    end
  end
  return nil
end

def delete_file
  file_actions :delete
end

## generic external command program
#  prompt is the user friendly text of command such as list for ls, or extract for dtrx, page for less
#  pauseyn is whether to pause after command as in file or ls
#
def command_file prompt, *command
  pauseyn = command.shift
  command = command.join " "
    print "[#{prompt}] Choose a file [#{$view[$cursor]}]: "
    file = ask_hint $view[$cursor]
  #print "#{prompt} :: Enter file shortcut: "
  #file = ask_hint
  perror "Command Cancelled" unless file
  return unless file
  file = File.expand_path(file)
  if File.exists? file
    file = Shellwords.escape(file)
    pbold "#{command} #{file} (#{pauseyn})"
    system "#{command} #{file}"
    pause if pauseyn == "y"
    refresh
  else
    perror "File #{file} not found"
  end
end

## prompt user for file shortcut and return file or nil
#
def ask_hint deflt=nil
  f = nil
  ch = get_char
  if ch == "ENTER" 
    return deflt
  end
  ix = get_index(ch, $viewport.size)
  f = $viewport[ix] if ix
  return f
end

## check screen size and accordingly adjust some variables
#
def screen_settings
  $glines=%x(tput lines).to_i
  $gcols=%x(tput cols).to_i
  $grows = $glines - 3
  $pagesize = 60
  #$gviscols = 3
  $pagesize = $grows * $gviscols
end
## moves column offset so we can reach unindexed columns or entries
# 0 forward and any other back/prev
def column_next dir=0
  if dir == 0
    $stact += $grows
    $stact = 0 if $stact >= $viewport.size
  else
    $stact -= $grows
    $stact = 0 if $stact < 0
  end
end
# currently i am only passing the action in from the list there as a key
# I should be able to pass in new actions that are external commands
def file_actions action=nil
  h = { :d => :delete, :m => :move, :r => :rename, :v => ENV["EDITOR"] || :vim,
    :l => :less, :s => :most , :f => :file , :o => :open, :x => :dtrx, :z => :zip }
  #acttext = h[action.to_sym] || action
  acttext = action || ""
  file = nil

  sct = $selected_files.size
  if sct > 0
    text = "#{sct} files"
    file = $selected_files
  else
    print "[#{acttext}] Choose a file [#{$view[$cursor]}]: "
    file = ask_hint $view[$cursor]
    return unless file
    text = file
  end

  case file
  when Array
    # escape the contents and create a string
    files = Shellwords.join(file)
  when String
    files = Shellwords.escape(file)
  end


  ch = nil
  if action
      menu_text = action
  else
    ch, menu_text = menu "File Menu for #{text}", h
    menu_text = :quit if ch == "q"
  end
  case menu_text.to_sym
  when :quit
  when :delete
    print "rmtrash #{files} ?[yn]: "
    ch = get_char
    return if ch != "y"
    system "rmtrash #{files}"
    refresh
  when :move
    print "move #{text} to : "
    target = gets().chomp
    if target.size > 2
      if File.directory? target
        FileUtils.mv text, target
        refresh
      else
        perror "Target not a dir"
      end
    else
      perror "Cancelled move"
    end
  when :zip
    print "Archive name: "
    target = gets().chomp
    # don't want a blank space or something screwing up
    if target && target.size > 3
      if File.exists? target
        perror "Target (#{target}) exists"
      else
        system "tar zcvf #{target} #{files}"
        refresh
      end
    end
  when :rename
  when :most, :less, :vim
    system "#{menu_text} #{files}"
  else
    return unless menu_text
    print "#{menu_text} #{files}"
    pause
    print
    system "#{menu_text} #{files}"
    refresh
    pause
  end
  # remove non-existent files from select list due to move or delete or rename or whatever
  if sct > 0
    $selected_files.reject! {|x| x = File.expand_path(x); !File.exists?(x) }
  end
end

def columns_incdec howmany
  $gviscols += howmany.to_i
  $gviscols = 1 if $gviscols < 1
  $gviscols = 6 if $gviscols > 6
  $pagesize = $grows * $gviscols
end

# bind a key to an external command wich can be then be used for files
def bindkey_ext_command
  print 
  pbold "Bind a capital letter to an external command"
  print "Enter a capital letter to bind: "
  ch = get_char
  return if ch == "Q"
  if ch =~ /^[A-Z]$/
    print "Enter an external command to bind to #{ch}: "
    com = gets().chomp
    if com != ""
      print "Enter prompt for command (blank if same as command): "
      pro = gets().chomp
      pro = com if pro == ""
    end
    print "Pause after output [y/n]: "
    yn = get_char
    $bindings[ch] = "command_file #{pro} #{yn} #{com}"
  end
end
def ack
  print "Enter a pattern to search (ack): "
  #pattern = gets.chomp
  pattern = Readline::readline('>', true)
  return if pattern == ""
  $title = "Files found using 'ack' #{pattern}"
  system("ack #{pattern}")
  pause
  files = `ack -l #{pattern}`.split("\n")
  if files.size == 0
    perror "No files found."
  else
    $files = files
  end
end
def ffind
  print "Enter a file name pattern to find: "
  pattern = Readline::readline('>', true)
  return if pattern == ""
  $title = "Files found using 'find' #{pattern}"
  files = `find . -name '#{pattern}'`.split("\n")
  if files.size == 0
    perror "No files found."
  else
    $files = files
  end
end
def locate
  print "Enter a file name pattern to locate: "
  pattern = Readline::readline('>', true)
  return if pattern == ""
  $title = "Files found using 'locate' #{pattern}"
  files = `locate #{pattern}`.split("\n")
  if files.size == 0
    perror "No files found."
  else
    $files = files
  end
end

## Displays files from .viminfo file, if you use some other editor which tracks files opened
#  then you can modify this accordingly.
#
def viminfo
  file = File.expand_path("~/.viminfo")
  if File.exists? file
    $title = "Files from ~/.viminfo"
    #$files = `grep '^>' ~/.viminfo | cut -d ' ' -f 2- | sed "s#~#$HOME#g"`.split("\n")
    $files = `grep '^>' ~/.viminfo | cut -d ' ' -f 2- `.split("\n")
    $files.reject! {|x| x = File.expand_path(x); !File.exists?(x) }
  end
end

##  takes directories from the z program, if you use autojump you can
#   modify this accordingly
#
def z_interface
  file = File.expand_path("~/.z")
  if File.exists? file
    $title = "Directories from ~/.z"
    $files = `sort -rn -k2 -t '|' ~/.z | cut -f1 -d '|'`.split("\n")
  end
end

## there is no one consisten way i am getting.
#  i need to do a shell join if I am to pipe ffiles to say: xargs ls -t
#  but if i want to pipe names to grep xxx then i need to join with newlines
def pipe
  #print "Enter pipe to filter existing files through: "
  #pipe = gets().chomp
  #if pipe != ""
  #end
end
def cursor_scroll_dn
  moveto(pos() + MSCROLL)
end
def cursor_scroll_up
  moveto(pos() - MSCROLL)
end
def cursor_dn
  moveto(pos() + 1)
end
def cursor_up
  moveto(pos() - 1)
end
def pos
  $cursor
end

def moveto pos
  orig = $cursor
  $cursor = pos
  $cursor = [$cursor, $view.size - 1].min
  $cursor = [$cursor, 0].max
  star = [orig, $cursor].min
  fin = [orig, $cursor].max
  if $visual_mode
    # PWD has to be there in selction
    if $selected_files.index $view[$cursor]
      # this depends on the direction 
      $selected_files = $selected_files - $view[star..fin]
      ## current row remains in selection always.
      $selected_files.push $view[$cursor]
    else
      $selected_files.concat $view[star..fin]
    end
  end
end
def visual_mode_toggle
  $visual_mode = !$visual_mode
  if $visual_mode
    $visual_block_start = $cursor
    $selected_files.push $view[$cursor]
  end
end
def visual_block_clear
  if $visual_block_start
    star = [$visual_block_start, $cursor].min
    fin = [$visual_block_start, $cursor].max
    $selected_files = $selected_files - $view[star..fin]
  end
  $visual_block_start = nil
  $visual_mode = nil
end
def file_starting_with fc
  ix = return_next_match(method(:file_matching?), "^#{fc}")
  if ix
    goto_line ix
  end
end
def file_matching? file, patt
  file =~ /#{patt}/
end
def return_next_match binding, *args
  first = nil
  ix = 0
  $view.each_with_index do |elem,ii|
    if binding.call(elem, *args)
      first ||= ii
      if ii > $cursor 
        ix = ii
        break
      end
    end
  end
  return first if ix == 0
  return ix
end
##
# position cursor on a specific line which could be on a nother page
# therefore calculate the correct start offset of the display also.
def goto_line pos
  pages = ((pos * 1.00)/$pagesize).ceil
  pages -= 1
  $sta = pages * $pagesize + 1
  $cursor = pos
end
def filetype f
  return nil unless f
  f = Shellwords.escape(f)
  s = `file #{f}`
  if s.index "text"
    return :text
  elsif s.index(/[Zz]ip/)
    return :zip
  elsif s.index("archive")
    return :zip
  elsif s.index "image"
    return :image
  elsif s.index "data"
    return :text
  end
  nil
end

def save_dir_pos 
  return if $sta == 0 && $cursor == 0
  $dir_position[Dir.pwd] = [$sta, $cursor]
end
def revert_dir_pos
  $sta = 0
  $cursor = 0
  a = $dir_position[Dir.pwd]
  if a
    $sta = a.first
    $cursor = a[1]
    raise "sta is nil for #{Dir.pwd} : #{$dir_position[Dir.pwd]}" unless $sta
    raise "cursor is nil" unless $cursor
  end
end
run if __FILE__ == $PROGRAM_NAME