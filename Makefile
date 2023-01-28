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

# original disks
CASTLEDISK=./disks/castle.g64
CASTLE3DISK=./disks/castle3.d64

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
	rm -rf build/files3
	rm -f build/codc-easyflash.crt

mrproper:
	rm -rf build


# ------------------------------------------------------------------------
# easyflash

EF_LOADER_FILES=build/ef/loader.o
EF_MENU_FILES=build/ef/menu.o build/ef/util.o build/ef/startup.o build/ef/startup-remastered.o build/ef/io-remastered.o build/ef/startup-original.o

# cartridge binary
build/ef/codc-easyflash.bin: build/ef/init.bin src/ef/lib-efs.prg src/ef/eapi-am29f040.prg build/ef/loader.bin build/ef/config.bin build/ef/data.dir.prg build/ef/data.files.prg build/ef/data-rw.dir.prg build/ef/data-rw.files.prg
	cp ./src/ef/crt.map ./build/ef/crt.map
	cp ./src/ef/eapi-am29f040.prg ./build/ef/eapi-am29f040.prg
	cp ./src/ef/lib-efs.prg ./build/ef/lib-efs.prg
	tools/mkbin.py -v -b ./build/ef -m ./build/ef/crt.map -o ./build/ef/codc-easyflash.bin

# cartdridge crt
build/codc-easyflash.crt: build/ef/codc-easyflash.bin
	cartconv -b -t easy -o build/codc-easyflash.crt -i build/ef/codc-easyflash.bin -n "The Castles of Doctor Creep" -p


# get files list and files
build/ef/files.list build/ef/files-rw.list: $(CASTLEDISK)
	@mkdir -p ./build/files
	@mkdir -p ./build/files3
	@mkdir -p ./build/ef
	tools/extract.sh 1 $(CASTLEDISK) build/files build/ef/files.list build/ef/files-rw.list
	tools/extract.sh 3 $(CASTLE3DISK) build/files3 build/ef/files.list build/ef/files-rw.list

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

# build efs
build/ef/data.dir.prg build/ef/data.files.prg: build/ef/files.list ./build/ef/patches.done build/ef/patches3.done build/ef/menu.prg
	tools/mkefs.py -v -s 507904 -o 0 -m lh -b 1 -n data -l ./build/ef/files.list -f . -d ./build/ef

# build rw efs
build/ef/data-rw.dir.prg build/ef/data-rw.files.prg: build/ef/files-rw.list
	tools/mkefs.py -v -s 262144 -o 6144 -m lh -b 32 -n data-rw -l ./build/ef/files-rw.list -f . -d ./build/ef

# disassemble of creepload
build/ef/creepload-da.s: src/ef/creepload-da.info
	SDL_VIDEODRIVER=dummy c1541 -attach $(CASTLEDISK) -read creepload ./build/files/creepload.prg
	$(DA65) -i ./src/ef/creepload-da.info -o build/ef/creepload-da.s


# ------------------------------------------------------------------------
# original game

# io wrapper
build/ef/io-original.prg: build/ef/io-original.o
	$(LD65) $(LD65FLAGS) -vm -m ./build/ef/io-original.map -Ln ./build/ef/io-original.lst -o $@ -C src/ef/io-original.cfg c64.lib build/ef/io-original.o
	#echo "./build/ef/io-original.prg, IO-ORIGINAL, 1, 0" >> ./build/ef/files.list

# disassemble of object
build/ef/object-da.s: build/ef/files.list src/ef/object-da.info src/ef/object-exp.inc src/ef/object-patch.sh
	$(DA65) -i ./src/ef/object-da.info -o build/ef/object-da.s

# object.prg
build/ef/object.prg build/ef/patches.done: build/ef/io-original.prg
	SDL_VIDEODRIVER=dummy c1541 -attach $(CASTLEDISK) -read object ./build/ef/object.prg
	tools/prgpatch.py -v -f build/ef -m build/ef/io-original.map src/ef/*.patch
	echo "./build/ef/object.prg, OBJECT, 1, 0" >> ./build/ef/files.list
	touch ./build/ef/patches.done


# ------------------------------------------------------------------------
# remastered game

# io wrapper
#build/ef/io-remastered.prg: build/ef/io-remastered.o
#	$(LD65) $(LD65FLAGS) -vm -m ./build/ef/io-remastered.map -Ln ./build/ef/io-remastered.lst -o $@ -C src/ef/io-remastered.cfg c64.lib build/ef/io-remastered.o
        #echo "./build/ef/io-original.prg, IO-ORIGINAL, 1, 0" >> ./build/ef/files.list

# object.prg
build/ef/3object.prg build/ef/patches3.done: build/ef/menu.prg
	@mkdir -p ./build/ef
	SDL_VIDEODRIVER=dummy c1541 -attach $(CASTLE3DISK) -read object ./build/ef/3object.prg
	tools/prgpatch.py -v -f build/ef -m build/ef/menu.map src/patch3/*.patch
#	cp ./disks/object-ef.prg build/ef/3object.prg
	echo "./build/ef/3object.prg, 3OBJECT, 1, 0" >> ./build/ef/files.list
	touch ./build/ef/patches3.done
