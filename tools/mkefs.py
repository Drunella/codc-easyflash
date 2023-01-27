#!/usr/bin/env python3

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

import os
import sys
import glob
import subprocess
import argparse
import hashlib
import traceback
import pprint


def efs_initialize(startbank, offset, mode):
    global data_directory, data_files, data_files_pointer, data_directory_pointer
    global data_files_pointer_offset, data_files_startbank, data_files_bankingmode
    global entries_directory, entries_files
    data_directory = bytearray([0xff] * 0x1800)
    data_files = bytearray([0xff] * (1024*1024)) # all 64 other banks, truncate later
    data_files_pointer = 0
    data_files_pointer_offset = offset
    data_files_startbank = startbank
    data_files_bankingmode = mode
    data_directory_pointer = 0
    entries_directory = dict()
    entries_files = dict()


def efs_makefileentry(data, maxsize):
    global data_directory, data_files, data_files_pointer, data_directory_pointer
    global data_files_pointer_offset, data_files_startbank, data_files_bankingmode
    global entries_directory, entries_files
    hash = hashlib.sha256(data);
    if hash in entries_files:
        # if file already created, simple return
        return entries_files[hash]
    # create new entry
    size = len(data)
    if (data_files_pointer + size >= maxsize):
        raise Exception("files data (" + str(data_files_pointer + size) +") exceeds maximum size (" + str(maxsize) + ")")
    offset = data_files_pointer
    data_files_pointer += size
    data_files[offset:offset+size] = data
    entry = dict()
    if (data_files_bankingmode == 'lh'):
        divisor = 0x4000
        startaddr = 0x0000
    elif (data_files_bankingmode == 'll'):
        divisor = 0x2000
        startaddr = 0x0000
    elif (data_files_bankingmode == 'hh'):
        divisor = 0x2000
        startaddr = 0x2000
    else:
        raise Exception("illegal banking mode " + data_files_bankingmode)
    entry["bank"] = int(offset // divisor + data_files_startbank) # size of one bank
    entry["startoffset"] = startaddr + (offset + data_files_pointer_offset) % divisor
    entry["filesize"] = size
    entries_files[hash] = entry
    return entry


def efs_makedirentry(dir, file):
    global data_directory, data_files, data_files_pointer, data_directory_pointer, data_files_pointer_offset
    global data_files_pointer_offset, data_files_startbank, data_files_bankingmode
    global entries_directory, entries_files
    if dir["name"] in entries_directory:
        raise Exception("directory entry " + dir + " has already bin added")
    content = bytearray(24)
    efs_writepaddedstring(content, 0, dir["name"])
    efs_writebyte(content, 16, dir["type"])
    efs_writebyte(content, 17, file["bank"])
    efs_writebyte(content, 18, 0)  # bank high stays empty
    efs_writeword(content, 19, file["startoffset"])
    efs_writeextended(content, 21, file["filesize"])
    if data_directory_pointer >= 6144:
        raise Exception("too many files in directory")
    data_directory[data_directory_pointer:data_directory_pointer+24] = content
    data_directory_pointer += 24    
        

def efs_terminatedir():
    global data_directory, data_files, data_files_pointer, data_directory_pointer
    global entries_directory, entries_files
    content = bytearray([0xFF] * 24)
    content[16] = 0xFF # terminate directory
    if data_directory_pointer >= 6144:
        raise Exception("too many files in directory")
    data_directory[data_directory_pointer:data_directory_pointer+24] = content
    data_directory_pointer += 24


def efs_writebyte(data, position, value):
    data[position] = value


def efs_writeword(data, position, value):
    data[position] = (value & 0x00ff)
    data[position+1] = (value & 0xff00) >> 8

    
def efs_writeextended(data, position, value):
    data[position] = (value & 0x0000ff)
    data[position+1] = (value & 0x00ff00) >> 8
    data[position+2] = (value & 0xff0000) >> 16


def efs_writepaddedstring(data, position, value):
    text = value.encode('utf-8')
    if len(text) > 16:
        raise Exception("filename too long (" + value + ")")
    data[position:position+16] = bytes([0] * 16)
    data[position:position+len(text)] = text


def efs_write(dirname, dataname):
    global data_directory, data_files, data_files_pointer, data_directory_pointer
    global verbose
    with open(dirname, "wb") as f:
        f.write(b'\x00')  # write address of bank 0:1:0000 = 0xa000
        f.write(b'\xa0')
        f.write(data_directory) # always write full directory
    if verbose:
        print("directory written as " + dirname)
    with open(dataname, "wb") as f:
        f.write(b'\x00')  # write address of bank b:0:0000 = 0x8000
        f.write(b'\x80')
        f.write(data_files[0:data_files_pointer])
    if verbose:
        print("data written with " + str(data_files_pointer)  + " bytes as " + dataname)
    

def load_files_directory(filename):
    directory = dict()
    with open(filename) as f:
        result = [line.split(',') for line in f]
        for l in result:
            #pprint.pprint(l)
            directory[l[0]] = dict();
            directory[l[0]]["sourcename"] = l[0].strip()
            directory[l[0]]["destname"] = l[1].strip()
            directory[l[0]]["type"] = l[2].strip()
            if len(l) >= 4:
                directory[l[0]]["hidden"] = l[3].strip()
            else:
                directory[l[0]]["hidden"] = "0"
            #pprint.pprint(directory)
    return directory


def load_file(filename):
    with open(filename, "rb") as f:
        return f.read()


def join_ws(iterator, seperator):
    it = map(str, iterator)
    seperator = str(seperator)
    string = next(it, '')
    for s in it:
        string += seperator + s
    return string


def main(argv):
    global data_directory
    global data_files
    global data_files_pointer
    global verbose

    verbose = False
    maxsize = 1032192
    p = argparse.ArgumentParser()
    p.add_argument("-v", dest="verbose", action="store_true", help="Verbose output.")
    p.add_argument("-l", dest="list", action="store", required=True, help="files list file.")
    p.add_argument("-f", dest="files", action="store", required=True, help="files directory.")
    p.add_argument("-d", dest="destination", action="store", required=True, help="destination directory.")
    p.add_argument("-s", dest="maxsize", action="store", required=False, help="maximum data size.", default="1032192")
    #p.add_argument("-u", dest="uppercase", action="store_true", required=False, help="uppercase name.", default=False)
    p.add_argument("-o", dest="offset", action="store", required=False, help="file start offset.", default='0')
    p.add_argument("-m", dest="mode", action="store", required=False, help="bank switching mode.", default="lh")
    p.add_argument("-b", dest="bank", action="store", required=False, help="start bank for files", default='1')
    p.add_argument("-n", dest="nameprefix", action="store", required=False, help="name prefix", default='efs')
    args = p.parse_args()

    verbose = args.verbose
    maxsize = int(args.maxsize, 0)
    #uppercase = args.uppercase
    offset = int(args.offset, 0)
    mode = args.mode
    startbank = int(args.bank, 0)
    nameprefix = args.nameprefix
    files_list = args.list
    files_path = args.files
    os.makedirs(files_path, exist_ok=True)
    destination_path = args.destination
    os.makedirs(destination_path, exist_ok=True)

    entries = load_files_directory(files_list)
    #pprint.pprint(entries)
    efs_initialize(startbank, offset, mode)
    
    # add prg files
    for key in entries:
        value = entries[key]
        #pprint.pprint(value)
        name = dict()
#        n = os.path.splitext(os.path.basename(value["name"]))
        
        hidden = int(value["hidden"], 0)
        if hidden != 0:
            hidden = 0x80
        type = int(value["type"], 0)
        if type > 0x1e:
            raise Exception("invalid type " + value["type"] + " of file " + value["sourcename"])

        name["type"] = 0x60 | hidden | type
        name["name"] = value["destname"]

#        if (value["type"] == "1"):
#            # prg with startaddress
#            name["name"] = n[0]
#            name["type"] = 0x60|0x01  # normal prg file with start address            
#        elif (value["type"] == "3"):
#            # bin without startaddress
#            name["name"] = n[0]
#            name["type"] = 0x60|0x01  # normal prg file with start address           
#        else:
#            raise Exception("unknown type " + value["type"] + " of file " + value["name"])

#        if (uppercase):
#            name["name"] = name["name"].upper()
        #pprint.pprint(value)
        content = load_file(os.path.join(files_path, value["sourcename"]))
        entry = efs_makefileentry(content, maxsize)
        efs_makedirentry(name, entry)
        #pprint.pprint(entry)
        if verbose:
            print("added file " + value["sourcename"] + " as " + name["name"]  +" (" + str(name["type"]) + ") of " +(str(len(content)))+ " bytes")

    efs_terminatedir()
    dirs_path = os.path.join(destination_path, nameprefix + ".dir.prg")
    data_path = os.path.join(destination_path, nameprefix + ".files.prg")
    efs_write(dirs_path, data_path)
    
    return 0

        
if __name__ == '__main__':
    try:
        retval = main(sys.argv)
        sys.exit(retval)
    except Exception as e:
        print(e)
        traceback.print_exc()
        sys.exit(1)
