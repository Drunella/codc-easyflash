#!/bin/bash

# $1 type (1 or 3)
# $2 disk file
# $3 destination dir and name
# $4 files list

#function add_name_prefix() {
## $1 directory
## $2 prefix
#    for file in "$1"/*
#    do
#        b=$(basename "$file")
#        mv "$file" "$1/$2$b"
#    done
#}


if ! command -v "c1541" &> /dev/null
then
    echo "$0: c1541 command not found"
    exit 1
fi

if [ "$#" -ne 5 ] ; then
    echo "$0 syntax: extract.sh type disk filelist rw-fileslist"
    exit 1
fi

mode="$1"
disk=$(realpath "$2")
destination="$3"
fileslist="$4"
fileslistrw="$5"

if [ "$mode" -eq "1" ] ; then
    echo "default castle"
    rm -rf $destination
    mkdir -p "$destination"
    pushd "$destination"
    SDL_VIDEODRIVER=dummy c1541 -attach "$disk" -extract
    popd
    mv $destination/.pic* "$destination/titlepic"
#    find "$destination" -name 'titlepic' -printf "%p, TITLEPIC, 1, 0\n" >> "$fileslist"
#    find "$destination" -name 'z*' -printf "%p, %P, 1, 0\n" >> "$fileslist"
#    find "$destination" -name 'music*' -printf "%p, %P, 1, 0\n" >> "$fileslist"
    count=$(ls -1 | grep -v total | wc -l)
    echo "extracted $count files from $disk"

    for filename in $destination/* ; do
        basename=$(basename "$filename")
        destname="${basename^^}"
        if [ "${basename}" = "titlepic" ] ; then
            echo "$filename, ${destname}, 1, 0" >> "$fileslist"
        fi
        if [ "${basename:0:5}" = "music" ] ; then
            echo "$filename, ${destname}, 1, 0" >> "$fileslist"
        fi
        if [ "${basename:0:1}" = "z" ] ; then
            echo "$filename, ${destname}, 1, 0" >> "$fileslist"
        fi
        if [ "${basename:0:1}" = "y" ] ; then
            echo "$filename, ${destname}, 1, 0" >> "$fileslistrw"
        fi

    done
    
    exit 0

fi

if [ "$mode" -eq "3" ] ; then
    echo "remastered castle"
    rm -rf $destination
    mkdir -p "$destination"
    pushd "$destination"
    SDL_VIDEODRIVER=dummy c1541 -attach "$disk" -extract
    popd
    mv $destination/pic* "$destination/titlepic"
#    #add_name_prefix "$destination" 3
#    find "$destination" -name 'titlepic' -printf "%p, 3TITLEPIC 1, 0\n" >> "$fileslist"
#    find "$destination" -name 'z*' -printf "%p, %P, 1, 0\n" >> "$fileslist"
#    find "$destination" -name 'music*' -printf "%p, %P, 1, 0\n" >> "$fileslist"
    count=$(ls -1 | grep -v total | wc -l)
    echo "extracted $count files from $disk"
    
    for filename in $destination/* ; do
        basename=$(basename "$filename")
        destname="${basename^^}"
        if [ "${basename}" = "titlepic" ] ; then
            echo "$filename, 3${destname}, 1, 0" >> "$fileslist"
        fi
        if [ "${basename:0:5}" = "music" ] ; then
            echo "$filename, 3${destname:1}, 1, 0" >> "$fileslist"
        fi
        if [ "${basename:0:1}" = "z" ] ; then
            echo "$filename, ${destname,}, 1, 0" >> "$fileslist"
        fi
        if [ "${basename:0:1}" = "y" ] ; then
            echo "$filename, ${destname,}, 1, 0" >> "$fileslistrw"
        fi
        
    done
    
    exit 0

fi


echo "$0: unknown type $mode"
exit 1
