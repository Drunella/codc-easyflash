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
    SDL_VIDEODRIVER=dummy c1541 -attach "$disk" -list > ./dir.list
    SDL_VIDEODRIVER=dummy c1541 -attach "$disk" -extract
    popd
    mv $destination/.pic* "$destination/titlepic"
    index=0
    while IFS= read -r line; do
        ((index++))
        substr=$(echo $line | cut -d'"' -f 2)
        if [ "${substr:0:1}" = "z" ] ; then
            dest=$(printf "%02d%s" $index $substr)
            mv "$destination/$substr" "$destination/$dest"
        fi
        if [ "${substr:0:1}" = "m" ] ; then
            dest=$(printf "%02d%s" $index $substr)
            mv "$destination/$substr" "$destination/$dest"
        fi
    done < "$destination/dir.list"
    count=$(ls -1 $destination | grep -v total | wc -l)
    echo "extracted $count files from $disk"

    for filename in $destination/* ; do
        basename=$(basename "$filename")
        destname="${basename^^}"
        if [ "${basename}" = "titlepic" ] ; then
            echo "$filename, ${destname}, 1, 0" >> "$fileslist"
        fi
        if [ "${basename:2:5}" = "music" ] ; then
            echo "$filename, ${destname:2}, 1, 0" >> "$fileslist"
        fi
        if [ "${basename:2:1}" = "z" ] ; then
            echo "$filename, ${destname:2}, 1, 0" >> "$fileslist"
        fi
        #if [ "${basename:0:1}" = "y" ] ; then
        #    echo "$filename, ${destname}, 1, 0" >> "$fileslistrw"
        #fi
    done
    
    exit 0
fi


if [ "$mode" -eq "3" ] ; then
    echo "remastered castle"
    rm -rf $destination
    mkdir -p "$destination"
    pushd "$destination"
    SDL_VIDEODRIVER=dummy c1541 -attach "$disk" -list > ./dir.list
    SDL_VIDEODRIVER=dummy c1541 -attach "$disk" -extract
    popd
    mv $destination/pic* "$destination/titlepic"

    index=0
    while IFS= read -r line; do
        ((index++))
        substr=$(echo $line | cut -d'"' -f 2)
        if [ "${substr:0:1}" = "z" ] ; then
            dest=$(printf "%02d%s" "$index" "$substr")
            mv "$destination/$substr" "$destination/$dest"
        fi
        if [ "${substr:0:1}" = "m" ] ; then
            dest=$(printf "%02d%s" "$index" "$substr")
            mv "$destination/$substr" "$destination/$dest"
        fi
    done < "$destination/dir.list"

    count=$(ls -1 $destination | grep -v total | wc -l)
    echo "extracted $count files from $disk"
    
    for filename in $destination/* ; do
        basename=$(basename "$filename")
        destname="${basename^^}"
        if [ "${basename}" = "titlepic" ] ; then
            echo "$filename, 3${destname}, 1, 0" >> "$fileslist"
        fi
        if [ "${basename:2:5}" = "music" ] ; then
            echo "$filename, 3${destname:3}, 1, 0" >> "$fileslist"
        fi
        if [ "${basename:2:1}" = "z" ] ; then
            echo -e "$filename, \xc3\x9a${destname:3}, 1, 0" >> "$fileslist"
        fi
        if [ "${basename:0:1}" = "y" ] ; then
            echo -e "$filename, \xc3\x99${destname:1}, 1, 0" >> "$fileslistrw"
        fi
        
    done
    
    exit 0

fi


echo "$0: unknown type $mode"
exit 1
