#!/bin/bash

# $1 disk file
# $2 filename
# $3 destination dir and name

if ! command -v "c1541" &> /dev/null
then
    echo "$0: c1541 command not found"
    exit 1
fi

if [ "$#" -eq 2 ] ; then
    echo "extracting $2 to current directory"
    SDL_VIDEODRIVER=dummy c1541 -attach "$1" -read "$2"
    exit 0
fi

if [ "$#" -eq 3 ] ; then
    echo "extracting $2 to $3"
    SDL_VIDEODRIVER=dummy c1541 -attach "$1" -read "$2" "$3"
    exit 0
fi

echo "$0: illegal number of parameters"
exit 2
