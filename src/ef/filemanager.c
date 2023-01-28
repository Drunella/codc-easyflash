// ----------------------------------------------------------------------------
// Copyright 2023 Drunella
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ----------------------------------------------------------------------------


#include <stdbool.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "util.h"


#define DIRECTORY_MAXENTRIES 512
#define FILEMANAGER_SIZE 0x4000


char* work;
directory_entry_t* directory;


char* get_error_text(uint8_t error)
{
    switch(error) {
        case 0: return "ok";
        case 1: return "ok: scratched";
        case 2: return "error 2: file open";
        case 3: return "error 3: file not open";
        case 4: return "error 4: file not found";
        case 5: return "error 5: device not present";
        case 6: return "error 6: no input file";
        case 7: return "error 7: no output file";
        case 8: return "error 8: missing filename";
        case 25: return "error 25: write error";
        case 26: return "error 26: write protected";
        case 30: return "error 30: syntax error";
        case 31: return "error 31: syntax error";
        case 63: return "error 63: disk full";
        case 71: return "error 71: directory ";
        default: return "unknown error";
    }
}


void filemanager_init()
{
//    if (directory != NULL) free(directory);
    
//    directory = malloc(DIRECTORY_MAXENTRIES * 24);
//    if (directory == NULL)

    work = (char*)FILEMANAGER_MEMORY;
    directory = (directory_entry_t*)(FILEMANAGER_MEMORY + 0x3000);
    
    memset(work, 0, FILEMANAGER_SIZE);
}

directory_entry_t* filemanager_get_efs_directory()
{
    char* endaddress;
    uint8_t retval, status;
    
    EFS_setnam_wrapper("$", 1);
    EFS_setlfs_wrapper(0); // do not relocate
    retval = EFS_load_wrapper(work, 0);
    endaddress = EFS_get_endadress();
    status = EFS_readst_wrapper();
    
    

    gotoxy(0, 23);  // ### status
    cprintf("%s", get_error_text(retval));
}




void filemanager_test(void)
{
    filemanager_get_efs_directory();
}
