# The Castles of Doctor Creep EasyFlash
This is the source to build an EasyFlash version from original 
and remastered The Castles of Doctor Creep on the C64.

## Features
* Save your games and best times on EasyFlash
* Import and export of save games

## Required Tools
To build you need the following:
* cc65
* cartconv from VICE
* c1541 from VICE
* Python 3.6 or greater
* GNU Make
* C compiler

## Building
To build The Castles of Doctor Creep create the folder `disks/` 
and place the original disk as d64 or g64 in it. Rename it to
`castle.d64` resp. `castle.g64`.

Download the remastered disk (Castles of Dr Creep 3 ReM V2) 
from the source of your choice, place it in the folder `disks/`
and rename it to `castle3.d64`.

The disks I used have the following sha1 checksums:

    d0b910f266ed150ce8f9f5ef8aa4383eda181537  disks/castle.g64
    359f2d1bcaace89012bf3f99e08766ef6ce9e1d9  disks/castle.d64
    18349f63c0b8e2268e2334dbdca71f3ec2aa5b46  disks/castle3.d64

Then build with

```
make
```

Find the crt image in the build sub-directory:
`build/codc-easyflash.crt`.


# Bugs

I did not test the game much. A lot of functionality is
unknown to me and therefore I do not know if I missed important
parts of code to convert. Especially saving files on EasyFlash
has not been tested thoroughly.


# License and Copyright

The code is © 2023 Drunella, available under an Apache 2.0 license.

The original The Castles of Doctor Creep is © 1984 br0derbund software.

The remastered version has been re-engineered by DrHonz.

No copy of the original or remastered game is included in this repository.
