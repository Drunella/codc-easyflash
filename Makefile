# ----------------------------------------------------------------------------
# Copyright 2023 Drunella
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------

# Settings
TARGET=c64
LD65=cl65
CA65=ca65
CC65=cc65
DA65=da65
#LD65=ld65
LD65FLAGS=-t $(TARGET)
CA65FLAGS=-t $(TARGET) -I . -I build/ef --debug-info
CC65FLAGS=-t $(TARGET) -O
#LD65FLAGS=

.SUFFIXES: .prg .s .c
.PHONY: clean all easyflash mrproper

EF_LOADER_FILES=build/ef/loader.o
EF_MENU_FILES=build/ef/menu.o build/ef/util.o build/ef/startup.o

# all
all: easyflash

# easyflash
easyflash: build/codc-easyflash.crt


# assemble
build/%.o: src/%.s
	@mkdir -p ./build/ef
	$(CA65) $(CA65FLAGS) -g -o $@ $<

# compile
build/%.s: src/%.c
	@mkdir -p ./build/ef
	$(CC65) $(CC65FLAGS) -g -o $@ $<

# assemble2
build/%.o: build/%.s
	@mkdir -p ./build/ef
	$(CA65) $(CA65FLAGS) -g -o $@ $<

clean:
	rm -rf build/ef
	rm -rf build/files
	rm -f build/codc-easyflash.crt

mrproper:
	rm -rf build


# ------------------------------------------------------------------------
# easyflash

# cartridge binary
build/ef/codc-easyflash.bin: build/ef/init.bin src/ef/lib-efs.prg src/ef/eapi-am29f040.prg build/ef/loader.bin build/ef/config.bin build/ef/data.dir.prg build/ef/data.files.prg build/ef/io-original.prg
	cp ./src/ef/crt.map ./build/ef/crt.map
	cp ./src/ef/eapi-am29f040.prg ./build/ef/eapi-am29f040.prg
	cp ./src/ef/lib-efs.prg ./build/ef/lib-efs.prg
	tools/mkbin.py -v -b ./build/ef -m ./build/ef/crt.map -o ./build/ef/codc-easyflash.bin

# cartdridge crt
build/codc-easyflash.crt: build/ef/codc-easyflash.bin
	cartconv -b -t easy -o build/codc-easyflash.crt -i build/ef/codc-easyflash.bin -n "The Castles of Doctor Creep" -p


# get files list and files
build/ef/files.list: disks/castle.d64
	@mkdir -p ./build/files
	@mkdir -p ./build/ef
	tools/extract.sh 1 disks/castle.d64 build/files build/ef/files.list build/ef/files-rw.list

# easyflash init.bin
build/ef/init.bin: build/ef/init.o
	$(LD65) $(LD65FLAGS) -o $@ -C src/ef/init.cfg $^

# easyflash loader.bin
build/ef/loader.bin: $(EF_LOADER_FILES)
	$(LD65) $(LD65FLAGS) -vm -m ./build/ef/loader.map -Ln ./build/ef/loader.lst -o $@ -C src/ef/loader.cfg c64.lib $(EF_LOADER_FILES)

# easyflash config.bin
build/ef/config.bin: build/ef/config.o src/ef/config.cfg
	$(LD65) $(LD65FLAGS) -vm -m ./build/ef/config.map -Ln ./build/ef/config.lst -o $@ -C src/ef/config.cfg c64.lib build/ef/config.o

# menu.prg
build/ef/menu.prg: $(EF_MENU_FILES)
	$(LD65) $(LD65FLAGS) -vm -m ./build/ef/menu.map -Ln ./build/ef/menu.lst -o $@ -C src/ef/menu.cfg c64.lib $(EF_MENU_FILES)
	echo "./build/ef/menu.prg, MENU, 1, 1" >> ./build/ef/files.list


# ------------------------------------------------------------------------
# original game

# io wrapper
build/ef/io-original.prg: build/ef/io-original.o
	$(LD65) $(LD65FLAGS) -vm -m ./build/ef/io-original.map -Ln ./build/ef/io-original.lst -o $@ -C src/ef/io-original.cfg c64.lib build/ef/io-original.o
	#echo "./build/ef/io-original.prg, IO-ORIGINAL, 1, 0" >> ./build/ef/files.list

# disassemble of object
build/ef/object-da.s: build/ef/files.list src/ef/object-da.info src/ef/object-exp.inc src/ef/object-patch.sh
	$(DA65) -i ./src/ef/object-da.info -o build/ef/temp1.s
	src/ef/object-patch.sh src/ef/object-exp.inc build/ef/temp1.s > build/ef/object-da.s
	rm -f build/ef/temp1.s

# object.prg
build/ef/object.prg build/ef/patches.done: build/ef/io-original.prg
	SDL_VIDEODRIVER=dummy c1541 -attach disks/castle.d64 -read object ./build/ef/object.prg
	tools/prgpatch.py -v -f build/ef -m build/ef/io-original.map src/ef/*.patch
	echo "./build/ef/object.prg, OBJECT, 1, 0" >> ./build/ef/files.list
	touch ./build/ef/patches.done

# build efs
build/ef/data.dir.prg build/ef/data.files.prg: build/ef/files.list ./build/ef/patches.done build/ef/menu.prg
	tools/mkefs.py -v -s 507904 -o 0 -m lh -b 1 -n data -l ./build/ef/files.list -f . -d ./build/ef


# ------------------------------------------------------------------------
# remastered game

# get files list and files
#build/ef/files.list: disks/castle.d64 disks/castle3.d64
#	@mkdir -p ./build/files
#	#@mkdir -p ./build/files3
#	@mkdir -p ./build/ef
#	tools/extract.sh 1 disks/castle.d64 build/files build/ef/files.list build/ef/files-rw.list
#	#tools/extract.sh 3 disks/castle3.d64 build/files3 build/ef/files.list build/ef/files-rw.list
#	#cp disks/object-ef.prg build/files3/3object-ef.prg
#	#cp disks/3object.prg build/files3/3object.prg
#	#cp disks/object.prg build/files/object.prg
#	#echo "./build/files3/3object-ef.prg, 3OBJECTEF, 1, 0" >> ./build/ef/files.list
#	#echo "./build/files3/3object.prg, 3OBJECT, 1, 0" >> ./build/ef/files.list
#	#echo "./build/files/object.prg, OBJECT, 1, 0" >> ./build/ef/files.list

# sector-rom.prg
#build/ef/sector-rom.bin: build/ef/io-sector.o
#	$(LD65) $(LD65FLAGS) -vm -m ./build/ef/sector-rom.map -Ln ./build/ef/sector-rom.lst -o $@ -C src/ef/sector-rom.cfg build/ef/io-sector.o

# startmenu.prg
#build/ef/startmenu.prg: $(STARTMENU_FILES)
#	$(LD65) $(LD65FLAGS) -vm -m ./build/ef/startmenu.map -Ln ./build/ef/startmenu.lst -o $@ -C src/ef/startmenu.cfg c64.lib $(STARTMENU_FILES)

## savegame.prg
#build/ef/savegame.prg: $(SAVEGAME_FILES)
#	$(LD65) $(LD65FLAGS) -vm -m ./build/ef/savegame.map -Ln ./build/ef/savegame.lst -o $@ -C src/ef/savegame.cfg c64.lib $(SAVEGAME_FILES)

# editor.prg
#build/ef/editor.prg: $(EDITOR_FILES)
#	$(LD65) $(LD65FLAGS) -vm -m ./build/ef/editor.map -Ln ./build/ef/editor.lst -o $@ -C src/ef/editor.cfg c64.lib $(EDITOR_FILES)

# import-util64.prg
#build/ef/import-util64.prg: $(IMPORT_UTIL64_FILES)
#	$(LD65) $(LD65FLAGS) -vm -m ./build/ef/import-util64.map -Ln ./build/ef/import-util64.lst -o $@ -C src/ef/import-util64.cfg c64.lib $(IMPORT_UTIL64_FILES)

# build image dir and data
#build/ef/files.dir.bin build/ef/files.data.bin: src/ef/files.csv build/ef/files.list build/ef/startmenu.prg build/ef/editor.prg build/ef/track18.bin build/ef/track09-sector14.bin build/ef/1541-fastloader-recomp.bin build/ef/track01-sector00.bin build/ef/track01-sector11.bin build/ef/import-util64.prg build/ef/savegame-orig.bin
#	cp src/ef/files.csv build/ef/files.csv
#	tools/mkfiles.py -v -l build/ef/files.csv -f build/ef/ -o build/ef/files.data.bin -d build/ef/files.dir.bin

# cartridge binary
#build/ef/bd3-easyflash.bin: build/ef/patched.done build/ef/init.prg build/ef/loader.prg src/ef/eapi-am29f040.prg build/ef/files.dir.bin build/ef/files.data.bin build/ef/character.bin build/ef/dungeona.bin build/ef/dungeonb.bin build/ef/sector-rom.bin
#	cp ./src/ef/crt.map ./build/ef/crt.map
#	cp ./src/ef/eapi-am29f040.prg ./build/ef/eapi-am29f040.prg
#	cp ./src/ef/ef-name.bin ./build/ef/ef-name.bin
#	tools/mkbin.py -v -b ./build/ef -m ./build/ef/crt.map -o ./build/ef/bd3-easyflash.bin

# cartdridge crt
#build/bt3-easyflash.crt: build/ef/bd3-easyflash.bin
#	cartconv -b -t easy -o build/bt3-easyflash.crt -i build/ef/bd3-easyflash.bin -n "Bard's Tale III" -p

# apply patches
#build/ef/patched.done: build/ef/character.bin
#	tools/bd3patch.py -f ./build/ef/ -v ./src/ef/*.patch
#	touch ./build/ef/patched.done
	
# sanitized disks
#build/ef/boot.prodos: disks/boot.d64
#	@mkdir -p ./build/ef
#	tools/sanitize.py -v -i 0 -s ./disks/boot.d64 -d ./build/ef/boot.prodos

#build/ef/character.bin: disks/character.d64
#	@mkdir -p ./build/ef
#	tools/sanitize.py -v -i 1 -s ./disks/character.d64 -d ./build/ef/character.bin

#build/ef/dungeona.bin: disks/dungeona.d64
#	@mkdir -p ./build/ef
#	tools/sanitize.py -v -i 2 -s ./disks/dungeona.d64 -d ./build/ef/dungeona.bin

#build/ef/dungeonb.bin: disks/dungeonb.d64
#	@mkdir -p ./build/ef
#	tools/sanitize.py -v -i 3 -s ./disks/dungeonb.d64 -d ./build/ef/dungeonb.bin
	
# application files
#build/ef/files.list: build/ef/boot.prodos build/prodos/prodos
#	build/prodos/prodos -i ./build/ef/boot.prodos ls > build/ef/files.list
#	tools/extract.sh build/ef/files.list build/ef

# copy track 18 of character disk
#build/ef/track18.bin: disks/character.d64
#	@mkdir -p ./build/ef
#	dd if=disks/character.d64 of=build/ef/track18.bin bs=256 skip=357 count=19

# copy prodos sector 87.1 at track 9 sector 14, summed 168 + 14
# to track09-sector14.bin
#build/ef/track09-sector14.bin: disks/character.d64
#	@mkdir -p ./build/ef
#	dd if=disks/character.d64 of=build/ef/track09-sector14.bin bs=256 count=1 skip=182

#build/ef/track01-sector00.bin: disks/character.d64
#	@mkdir -p ./build/ef
#	dd if=disks/character.d64 of=build/ef/track01-sector00.bin bs=256 count=1 skip=0

#build/ef/track01-sector11.bin: disks/character.d64
#	@mkdir -p ./build/ef
#	dd if=disks/character.d64 of=build/ef/track01-sector11.bin bs=256 count=1 skip=11

#build/ef/savegame-orig.bin: build/ef/character.bin
#	@mkdir -p ./build/ef
#	dd if=build/ef/character.bin of=build/ef/savegame-orig.bin bs=512 count=13 skip=267


# get 2.0.prg
#build/ef/2.0.prg: disks/boot.d64
#	SDL_VIDEODRIVER=dummy c1541 -attach disks/boot.d64 -read 2.0 ./build/ef/2.0.prg

# disassemble of prodos 2.0
#build/ef/io-sectortable-da.s: build/ef/files.list src/ef/io-sectortable-da.info src/ef/io-sectortable-exp.inc build/ef/2.0.prg src/ef/io-sectortable-patch.sh
#	$(DA65) -i ./src/ef/io-sectortable-da.info -o build/ef/temp1.s
#	#cat src/ef/io-sectortable-exp.inc build/ef/temp1.s > build/ef/io-sectortable-da.s
#	src/ef/io-sectortable-patch.sh src/ef/io-sectortable-exp.inc build/ef/temp1.s > build/ef/io-sectortable-da.s
#	rm -f build/ef/temp1.s


# disassemble of util64
#build/ef/util64-da.s: build/ef/global.i src/ef/util64-da.info build/ef/2.0.prg src/ef/util64-patch.sh src/ef/util64-exp.inc
#	$(DA65) -i ./src/ef/util64-da.info -o build/ef/temp2.s
#	src/ef/util64-patch.sh src/ef/util64-exp.inc build/ef/temp2.s > build/ef/util64-da.s
#	rm -f build/ef/temp2.s

# global addresses
#build/ef/global.i: build/ef/loader.map
#	tools/mkglobal.py -v -m ./build/ef/loader.map -o ./build/ef/global.i loadsave_sector_body
#

# fastloader 1541 part, track 18 sector 14-17 (371 sectors in)
#build/ef/1541-fastloader.bin: disks/boot.d64
#	@mkdir -p ./build/ef
#	dd if=disks/boot.d64 of=build/ef/1541-fastloader.bin bs=256 count=4 skip=371

# disassemble of 1541 fastloader
#build/ef/1541-fastloader-da.s: src/ef/1541-fastloader-da.info build/ef/1541-fastloader.bin src/ef/1541-fastloader-patch.sh
#	$(DA65) -i ./src/ef/1541-fastloader-da.info -o build/ef/temp3.s
#	src/ef/1541-fastloader-patch.sh build/ef/temp3.s > build/ef/1541-fastloader-da.s
#	rm -f build/ef/temp3.s

# recompiled fastloader
#build/ef/1541-fastloader-recomp.bin: build/ef/1541-fastloader-da.s
#	$(LD65) $(LD65FLAGS) -vm -m ./build/ef/1541-fastloader-recomp.map -Ln ./build/ef/1541-fastloader-recomp.lst -o $@ -C src/ef/1541-fastloader.cfg c64.lib $^
