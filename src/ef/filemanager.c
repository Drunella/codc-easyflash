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
//#define FILEMANAGER_SIZE 0x4000


//char* work;
//directory_entry_t* directory;


char* get_error_text(uint8_t error, uint8_t status)
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
        case 255: break;
        default: status = 0; break;
    }
    if (status == 0x40) {
        return "ok";
    } else {
        return "unknown error";
    }
    
}


directory_entry_t* filemanager_init(directory_entry_t* directory)
{
    if (directory != NULL) free(directory);
    
    directory = calloc(DIRECTORY_MAXENTRIES, 24);
    return directory;
//    if (directory == NULL)

//    work = (char*)FILEMANAGER_MEMORY;
//    directory = (directory_entry_t*)(FILEMANAGER_MEMORY + 0x3000);
    
//    memset(work, 0, FILEMANAGER_SIZE);
}


uint8_t text_to_type(char* type)
{
    uint8_t len;
    uint8_t flags;
        
    len = strlen(type);
    if (len == 0) return 0;
    
    flags = 1;
    if (type[len-1] == '<') flags |= 0x80; // write protected

    // ### check for other types
    // SEQ, USR, REL, DEL, CBM, DIR
    // crt, ocn, xba
    // *, +, -
    return flags;
}


void filemanager_empty_directory(directory_entry_t* destination)
{
    destination[0].name[0] = 0;
    destination[0].flags = 0;
    destination[0].size = 1;
    destination[1].name[0] = 0;
    destination[1].flags = 0xff;
    destination[1].size = 0;
}

uint8_t filemanager_get_directory(directory_entry_t* destination, uint8_t device)
{
    uint8_t retval, status;
    uint8_t value, state;
    uint16_t counter, entry;
    uint8_t var1;
    uint16_t var2;
    char var3[8];
    
    if (device > 0) {
        // iec device
//        retval = cbm_device_ispresent(device);
//        if (retval != 0) goto finish;
        cbm_k_setlfs(1, device, 0);
        cbm_k_setnam("$");
        retval = cbm_k_open();
        if (retval != 0) goto finish;
        retval = cbm_k_chkin(1);
        if (retval != 0) goto finish;
    } else {
        // efs
        EFS_setnam_wrapper("$", 1);
        EFS_setlfs_wrapper(0); // do not relocate
        retval = EFS_open_wrapper(0);
    }
    if (retval != 0) goto finish;

    counter = 0;
    entry = 0;
    state = 1;
    while (true) {
        if (device > 0) {
            value = cbm_k_getin();
            status = cbm_k_readst();
        } else {
            retval = EFS_chrin_wrapper(&value);
            status = EFS_readst_wrapper();
        }
        if (status == 0x40) {
            // finished
            break;
        }
        counter++;
        
        switch (state) {
            case 0: 
                break;
            case 1: 
                state = 2; 
                break; // skip address low
            case 2: 
                state = 3; 
                break; // skip address high
            
            case 3: 
                if (value != 0x22) break;
                state = 4;
                destination[0].size = 0; // disk name
                destination[0].flags = 0; // disk name
                var1 = 0;
                break;
            case 4:
                if (value == 0x22) {
                    state = 5; // end of directory
                    destination[entry].name[var1] = 0;
                    break;
                }
                destination[entry].name[var1] = value;
                var1++;
                break;
            case 5:
                if (value != 0) break;
                entry++;
                state = 10; // file entries
                break;
            
            case 10: // line number field
                // ### error if (value != 1) break;
                state++;
                break;
            case 11: // line number field
                // ### error if (value == 1) break;
                state++;
                var1 = 0;
                break;
            case 12: // file size
                if (var1 == 0) {
                    var1++;
                    var2 = value;
                } else {
                    var2 += ((uint16_t)value) * 256;
                    destination[entry].size = var2;
                    state++;
                }
                break;
            case 13: // quotation mark or end of line
                if (value == 0) { // end of directory
                    destination[entry].name[0] = 0;
                    destination[entry].flags = 0xff;
                    destination[0].size = entry - 1;
                    state = 0; // end
                    break;
                }
                if (value == 0x22) {
                    state++;
                    var1 = 0;
                    break;
                } 
                break;
            case 14: // filename
                if (value == 0x22) {
                    destination[entry].name[var1] == 0;
                    state++;
                    var1 = 0;
                    break;
                }
                destination[entry].name[var1] = value;
                var1++;
                destination[entry].name[var1] = 0;
                break;
            case 15: // type and next line
                if (value == 0) {
                    // next line
                    destination[entry].flags = text_to_type(var3);
                    entry++;
                    state = 10;
                } else if (value == 0x20) {
                    // space, skip
                    break;
                } else {
                    var3[var1] = value;
                    var3[var1+1] = 0;
                    var1++;
                }
                break;
            
            default: 
                retval = 0xfe; 
                break; // error
        }
    }
    
finish:
    if (device > 0) {
        cbm_k_close(1);
    } else {
        EFS_close_wrapper();
    }
    return retval;
}


uint8_t filemanager_get_startaddress(char* filename, uint8_t device, uint16_t* address)
{
    uint8_t retval, value;

    if (device > 0) {
        // iec device
        cbm_k_setlfs(1, device, 0);
        cbm_k_setnam(filename);
        retval = cbm_k_open();
        if (retval != 0) goto finish;
        retval = cbm_k_chkin(1);
        
        *address = cbm_k_getin();
        *address += ((uint16_t)cbm_k_getin()) * 256;
    
    } else {
        EFS_setnam_wrapper(filename, strlen(filename));
        EFS_setlfs_wrapper(0);  // do not relocate
        retval = EFS_open_wrapper(0);  // open for read
        if (retval != 0) goto finish;

        retval = EFS_chrin_wrapper(&value);
        *address = (uint16_t)value;
        retval = EFS_chrin_wrapper(&value);
        *address += ((uint16_t)value) * 256;
    }

finish:
    if (device > 0) {
        cbm_k_close(1);
    } else {
        EFS_close_wrapper();
    }
    return retval;
}



char* get_index_text(directory_entry_t* directory, uint16_t index)
{
    static char itemline[40];
    
    itemline[0] = 0;
    if (index > directory[0].size - 1) return itemline;
    
    sprintf(itemline, "%s (%u, %x)", directory[index+1].name, directory[index+1].size, directory[index+1].flags);
    // ###

    return itemline;
}


char* get_index_filenametext(directory_entry_t* directory, uint16_t index)
{
    if (index > directory[0].size - 1) return NULL;
    return directory[index+1].name;
}

uint8_t get_index_max(directory_entry_t* destination)
{
//    uint16_t count;
    
    return destination[0].size - 1;
}


uint8_t next_item(directory_entry_t* directory, uint16_t index, uint16_t step)
{
    if (index+step >= get_index_max(directory) - 1) return get_index_max(directory) - 1;
    index += step;
    return index;
}

uint8_t previous_item(uint16_t index, uint16_t step)
{
    if (step >= index) return 0;
    index -= step;
    return index;
}

char* get_headline(directory_entry_t* directory)
{
    return directory[0].name;
}



#define LIST_HEIGHT 18

void draw_status(uint8_t retval, uint8_t device)
{
    uint8_t status;
    char* text;
    
    if (device > 0) {
        cbm_device_get_status(device);
        text = cbm_device_last_status();
        status = cbm_k_readst();
    } else {
        text = get_error_text(retval, status);
        status = EFS_readst_wrapper();
    }
    
    gotoxy(0, 23);
    cprintf("%s", get_error_text(retval, status));
        
}


void draw_editor_listdisplay(char* headline)
{
    uint8_t n;

    textcolor(COLOR_GRAY2);
    chlinexy(1, 0, 38); // top
    chlinexy(1, LIST_HEIGHT+1, 38);  // bottom

    if (headline != NULL) {
        cputcxy(2, 0, '[');
        gotoxy(3,0);
        n = cprintf("%s", headline);
        cputcxy(3+n, 0, ']');
    }

    cvlinexy(0, 1, LIST_HEIGHT);
    cvlinexy(39, 1, LIST_HEIGHT);
    cputcxy(0, 0, 0xf0);  // upper left
    cputcxy(39, 0, 0xee);  // upper right
    cputcxy(0, LIST_HEIGHT+1, 0xed);  // lower left
    cputcxy(39, LIST_HEIGHT+1, 0xfd);  // lower right
}

void draw_listcontent(directory_entry_t* directory, uint16_t startindex)
{
//    static uint16_t index_offset = 0;
    uint16_t i;
//    uint16_t max = get_index_max(directory);
    char* content;

    // start offset
//    if (index >= index_offset+LIST_HEIGHT) index_offset += index - (index_offset+LIST_HEIGHT) + 1;
//    if (index < index_offset) {
//        if (index_offset - index >= index_offset) index_offset = 0;
//        else index_offset -= index_offset - index;
//    }
    for (i=0; i<LIST_HEIGHT; i++) {
        content = get_index_text(directory, startindex + i);
        cputsxy(1, 1+i, content);  // ### start x, start y
        cclearxy(wherex(), wherey(), 37 - wherex());
    }
}

//void highlight_index(uint16_t previous, uint16_t next)
//{
//    
//}


/*void draw_editor_listcontent(directory_entry_t* directory, uint16_t index)
{
    static uint16_t index_offset = 0;
    uint16_t i, pos, n;
    uint16_t max = get_index_max(directory);
    char* content;

    // start offset
    if (index >= index_offset+LIST_HEIGHT) index_offset += index - (index_offset+LIST_HEIGHT) + 1;
    if (index < index_offset) {
        if (index_offset - index >= index_offset) index_offset = 0;
        else index_offset -= index_offset - index;
    }
    for (i=0; i<LIST_HEIGHT; i++) {
        if (i+index_offset < max) {
            pos = i+index_offset;
            content = get_index_text(directory, pos);
            if (index == pos) revers(1); else revers(0);
            textcolor(COLOR_WHITE);
            gotoxy(1,1+i);
            n = cprintf("%s", content);
        } else {
            n = 0;
        }
        cclearxy(1+n, 1+i, 38-n);
        textcolor(COLOR_GRAY2);
        revers(0);
    }

    if (index_offset > 0) cputcxy(39, 2, 0xf1); else cputcxy(39, 2, 0xdd);
    if (index_offset+LIST_HEIGHT < max) cputcxy(39, 1+LIST_HEIGHT-2, 0xf2); else cputcxy(39, 1+LIST_HEIGHT-2, 0xdd);

}*/


void show_info(directory_entry_t* directory, uint8_t device, uint16_t index)
{
    uint16_t address;
    uint8_t retval;
    char name[17];
    
    strcpy(name, get_index_filenametext(directory, index));
    retval = filemanager_get_startaddress(name, device, &address);
    
    gotoxy(1, LIST_HEIGHT+2);
    cprintf("\"%s\" result %d, address %04x  ", name, retval, address);
    
//    draw_status(retval);
}


void savegame_menu(void)
{
    directory_entry_t* directory;
    uint8_t device, repaint;
    uint16_t index;
    bool changed;
    uint8_t retval;
    uint16_t position;

    // we assume eapi already installed at $c000
    // we assume the sector load/save functions are installed at $cxxx
    // we assume the wrappers are installed at $b7xx

    // init
//    backup_screen();
    clrscr();
    textcolor(COLOR_GRAY2);
    repaint = 1;
    position = 1;
    changed = false;
    index = 0;
    device = 0;

//    directory = (directory_entry_t*)FILEMANAGER_MEMORY;
    directory = NULL;
    directory = filemanager_init(directory);
    filemanager_empty_directory(directory);
    retval = filemanager_get_directory(directory, device);
    draw_status(retval, device);

//    get_empty_directory(directory, device);

    // prepare
    draw_editor_listdisplay(get_headline(directory));

    while (kbhit()) cgetc();

    for (;;) {
        if (repaint > 0) {
            //draw_editor_listcontent(directory, index);
            draw_listcontent(directory, index);
            //draw_status_listdisplay(type);
            repaint = 0;
        }

        retval = cgetc();
 //       if (type == 0xff && retval >= 'a' && retval <= 'z') {
//            index = get_alphabetical_index(retval);
//            repaint = 1;
//        } else 
        switch (retval) {
            case 0x5f: // back arrow
                return;
/*                if (type == 0xff) {
                    restore_screen();
                    return false;
                } else {
                    restore_screen();
                    return changed;
                }*/

            case 0x11: // down
                index = next_item(directory, index, 1);
                repaint = 1;
                break;
            case 0x1d: // right
                index = next_item(directory, index, 10);
                repaint = 1;
                break;
            case 0x91: // up
                index = previous_item(index, 1);
                repaint = 1;
                break;
            case 0x9d: // left
                index = previous_item(index, 10);
                repaint = 1;
                break;
                
            case 'x':
                show_info(directory, device, index);
                repaint = 1;
                break;
                
            default: 
                break;
        }
    }
}



/*
    uint8_t repaint;

    repaint = 2;
    bgcolor(COLOR_BLACK);
    bordercolor(COLOR_BLACK);
    while (kbhit()) cgetc();

    for (;;) {

        if (repaint > 0) {
            if (repaint > 1) draw_startmenu();
            menu_clear(MENU_START_Y, 24);
            menu_option('1', "Scann directory");
            cputs("\r\n");
            menu_option(0x5f, "Return to main");
        }
        repaint = 0;

        switch (cgetc()) {
        case '1':
            menu_clear(MENU_START_Y,24);
            filemanager_test();
            break;


        case 0x5f:
            return;
        }
    }

//    filemanager_init();
    
//    filemanager_test();
*/


/*void filemanager_test(void)
{
    filemanager_init();
    filemanager_get_efs_directory((directory_entry_t*)FILEMANAGER_MEMORY);
}*/
