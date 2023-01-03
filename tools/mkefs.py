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


def efs_initialize():
    global data_directory, data_files, data_files_pointer, data_directory_pointer
    global entries_directory, entries_files
    data_directory = bytearray([0xff] * 0x1800)
    data_files = bytearray([0xff] * 1032192) # all 63 other banks, truncate later
    data_files_pointer = 0
    data_directory_pointer = 0
    entries_directory = dict()
    entries_files = dict()


def efs_makefileentry(data, maxsize):
    global data_directory, data_files, data_files_pointer, data_directory_pointer
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
    entry["bank"] = int(offset // 0x4000 + 1) # size of one bank
    entry["startoffset"] = int(offset % 0x4000)
    entry["filesize"] = size
    entries_files[hash] = entry
    return entry


def efs_makedirentry(dir, file):
    global data_directory, data_files, data_files_pointer, data_directory_pointer
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
    if len(text) > 15:
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
        print("directory written")
    with open(dataname, "wb") as f:
        f.write(b'\x00')  # write address of bank b:0:0000 = 0x8000
        f.write(b'\x80')
        f.write(data_files[0:data_files_pointer])
    if verbose:
        print("data written with " + str(data_files_pointer)  + " bytes")
    

def load_files_directory(filename):
    directory = dict()
    with open(filename) as f:
        result = [line.split() for line in f]
        for l in result:
            #pprint.pprint(l)
            directory[l[0]] = dict();
            directory[l[0]]["name"] = l[0]
            directory[l[0]]["type"] = l[1]
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
    p.add_argument("-u", dest="uppercase", action="store_true", required=False, help="uppercase name.", default=False)
    args = p.parse_args()

    verbose = args.verbose
    maxsize = int(args.maxsize, 0)
    uppercase = args.uppercase
    files_list = args.list
    files_path = args.files
    os.makedirs(files_path, exist_ok=True)
    destination_path = args.destination
    os.makedirs(destination_path, exist_ok=True)

    entries = load_files_directory(files_list)
    #pprint.pprint(entries)
    efs_initialize()
    
    # add prg files
    for key in entries:
        value = entries[key]
        #pprint.pprint(value)
        name = dict()
        n = os.path.splitext(os.path.basename(value["name"]))
        if (value["type"] == "prg"):
            # prg with startaddress
            name["name"] = n[0]
            name["type"] = 0x60|0x01  # normal prg file with start address
            
        elif (value["type"] == "bin"):
            # bin without startaddress
            name["name"] = n[0]
            name["type"] = 0x60|0x09  # normal file without startaddress
            
        else:
            raise Exception("unknown type " + value["type"] + " of file " + value["name"])

        if (uppercase):
            name["name"] = name["name"].upper()
        #pprint.pprint(name)        
        content = load_file(os.path.join(files_path, value["name"]))
        entry = efs_makefileentry(content, maxsize)
        efs_makedirentry(name, entry)
        if verbose:
            print("added file " + value["name"] + " (" + value["type"] + ") of " +(str(len(content)))+ " bytes")

    efs_terminatedir()
    dirs_path = os.path.join(destination_path, "directory.data.prg")
    data_path = os.path.join(destination_path, "files.data.prg")
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
