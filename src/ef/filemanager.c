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
#include <cbm.h>
#include <ctype.h>

#include "util.h"


#define EFS_POSITION 0
#define CBM_POSITION 12
#define FILES_HEIGHT 10
#define FILES_WIDTH 25



uint8_t busy_indicator_column;

void filemanager_busy_indicator_column(uint8_t c)
{
    busy_indicator_column = c;
}

void filemanager_busy_indicator()
{
    static char busy = 1;

    if (busy == 1) {
        busy = 0;
        cputsxy(FILES_WIDTH - 3, busy_indicator_column, "[*]");
    } else {
        busy = 1;
        cputsxy(FILES_WIDTH - 3, busy_indicator_column, "[+]");
    }
}

void filemanager_done_indicator()
{
    chlinexy(FILES_WIDTH - 3, busy_indicator_column, 3);
}

void filemanager_clear_indicator()
{
    cclearxy(FILES_WIDTH - 3, busy_indicator_column, 3);
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

uint8_t filemanager_identify_file(directory_entry_t* entry, uint8_t device)
{
    uint8_t retval;
    uint16_t address;
    bool protected;
    char* filename = entry->name;

    // $00: unknown file (no codc file)
    // $01: classic save game: *, $7800
    // $02: classic best times file: y, $b800
    // $03: classic castle: z*, $7800, protected, do not copy
    // $11: (none)
    // $12: remastered best times file: Y*, $6400
    // $13: remastered castle; Z*, $7800

    retval = filemanager_get_startaddress(filename, device, &address);
    if (retval != 0) return 0xff;

    protected = (entry->flags & 0x80) == 0x80;

    // remastered files
    if (filename[0] == 'z' && address == 0x7800 && !protected) return 0x13;
    if (filename[0] == 0xda && address == 0x7800) return 0x13;
    if (filename[0] == 0xd9 && address == 0x6400) return 0x12;
    if (filename[0] == 'y' && address == 0x6400) return 0x12;

    // classic files
    if (filename[0] == 'z' && address == 0x7800 && protected) return 0x03;
    if (filename[0] == 'y' && address == 0xb800) return 0x02;
    if (filename[0] != 0xda && filename[0] != 'z' && address == 0x7800 && !protected) return 0x01; // not further idenditficytions possible

    return 0;
}


uint16_t copy_file(uint8_t dstdevice, directory_entry_t* srcentry, uint8_t srcdevice)
{
    uint8_t n, srcretval, dstretval, value, status, type;
    char dstname[25];
    uint16_t counter;

    srcretval = 0;
    dstretval = 0;
    counter = 0;
    filemanager_busy_indicator_column(24);

    if (dstdevice == srcdevice) return 0xffff;
    if (dstdevice > 0 && srcdevice > 0) return 0xffff;

    if (dstdevice == 0) {
        n = sprintf(dstname, "@0:%s", srcentry->name);
        dstname[n] = 0;
    } else {
        n = sprintf(dstname, "@0:%s,p,w", srcentry->name);
        dstname[n] = 0;
    }

    // name conversion
    type = filemanager_identify_file(srcentry, srcdevice);
    if (dstdevice == 0 && (type == 0x12 || type == 0x13)) {
        dstname[3] = toupper(dstname[3]);
    }
    if (dstdevice > 0 && (type == 0x12 || type == 0x13)) {
        dstname[3] = tolower(dstname[3]);
        //gotoxy(1,24); cprintf("conv: %d, %s", dstname[3], dstname);
    }

    // open srcdevice
    if (srcdevice > 0) {
        // iec device
        cbm_k_setlfs(2, srcdevice, 2);
        cbm_k_setnam(srcentry->name);
        srcretval = cbm_k_open();
        if (srcretval != 0) goto finish;
        srcretval = cbm_k_chkin(2);
    } else {
        // efs
        EFS_setnam_wrapper(srcentry->name, strlen(srcentry->name));
        EFS_setlfs_wrapper(0); // do not relocate
        srcretval = EFS_open_wrapper(0);
    }
    if (srcretval != 0) goto finish;
    
    // open dstdevice
    if (dstdevice > 0) {
        // iec device
        cbm_k_setlfs(3, dstdevice, 3);
        cbm_k_setnam(dstname);
        dstretval = cbm_k_open();
        if (dstretval != 0) goto finish;
        dstretval = cbm_k_ckout(3);
    } else {
        // efs
        EFS_setnam_wrapper(dstname, strlen(dstname));
        EFS_setlfs_wrapper(0); // do not relocate
        dstretval = EFS_open_wrapper(1); // open for write
    }
    if (dstretval != 0) goto finish;

    if (srcdevice > 0 && dstdevice == 0) {
        // copy to efs
        while (true) {
            status = cbm_k_readst();
            value = cbm_k_getin();
            dstretval = EFS_chrout_wrapper(value);
            if (status == 0x40) break;
            if (dstretval != 0) break;
            counter++;
            if ((counter & 0x000f) == 0) filemanager_busy_indicator();
        }
    
    } else if (srcdevice == 0 && dstdevice > 0) {
        // copy to cbm
        while (true) {
            srcretval = EFS_chrin_wrapper(&value);
            status = EFS_readst_wrapper();
            cbm_k_bsout(value);
            if (status == 0x40) break;
            if (srcretval != 0) break;
            counter++;
            if ((counter & 0x000f) == 0) filemanager_busy_indicator();
        }
    
    } else {
        srcretval = 0xff;
        dstretval = 0xff;
    }

finish:
    cbm_k_close(2);
    cbm_k_close(3);
    EFS_close_wrapper();
    filemanager_clear_indicator();
    return ((uint16_t)dstretval)*256 + (uint16_t)dstretval;
}


char* get_error_text_efs(uint8_t error, uint8_t status)
{
    static char* unknown = "unknown error 000 ";
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
        case 71: return "error 71: directory error";
        case 254: return "directory not recognized";
        case 255: break;
        default: status = 0; break;
    }
    if (status == 0x40) {
        return "ok";
    } else {
        sprintf(&unknown[14], "%d", error);
        return unknown;
    }
    
}


directory_entry_t* filemanager_init(directory_entry_t* directory, uint16_t expected)
{
    if (directory != NULL) free(directory);
    
    directory = calloc(expected, 24);
    return directory;
}

directory_entry_t* filemanager_exit(directory_entry_t* directory)
{
    if (directory != NULL) free(directory);
    return NULL;
}


uint8_t text_to_type(char* type)
{
    // SEQ, USR, REL, DEL, CBM, DIR
    // crt, ocn, xba

    uint8_t len;
    uint8_t flags;
    char* typeonly;
        
    len = strlen(type);
    if (len == 0) return 0;
    
    flags = 1;
    if (type[len-1] == '<') flags |= 0x80; // write protected

    if (strlen(type) > 3) {
        typeonly = &type[1];
    } else {
        typeonly = type;
    }
    
    if (strncmp(typeonly, "prg", 3) == 0) {
        flags |= 0x01;
    } else if (strncmp(typeonly, "seq", 3) == 0) {
        flags |= 0x02;    
    } else if (strncmp(typeonly, "usr", 3) == 0) {
        flags |= 0x03;    
    } else if (strncmp(typeonly, "rel", 3) == 0) {
        flags |= 0x04;    
    } else if (strncmp(typeonly, "del", 3) == 0) {
        flags |= 0x20;    
    } else if (strncmp(typeonly, "cbm", 3) == 0) {
        flags |= 0x05;    
    } else if (strncmp(typeonly, "dir", 3) == 0) {
        flags |= 0x40;    
    } else if (strncmp(typeonly, "crt", 3) == 0) {
        flags |= 0x11;    
    } else if (strncmp(typeonly, "ocn", 3) == 0) {
        flags |= 0x12;    
    } else if (strncmp(typeonly, "xba", 3) == 0) {
        flags |= 0x13;    
    } 
    return flags;
}

char* type_to_text(uint8_t type)
{
    type = type & 0x7f;
    switch (type) {
        case 0x01:
            return "prg";
        case 0x02:
            return "seq";
        case 0x03:
            return "usr";
        case 0x04:
            return "rel";
        case 0x05:
            return "cbm";
        case 0x11:
            return "crt";
        case 0x12:
            return "ocn";
        case 0x13:   
            return "xba";
        case 0x20:
            return "del";
        case 0x40:
            return "dir";
        default:
            return "???";
    }
}


void filemanager_empty_directory(directory_entry_t* destination)
{
    destination[0].name[0] = 0;
    destination[0].flags = 0;
    destination[0].size = 0;  // zero elements
    destination[1].name[0] = 0;
    destination[1].flags = 0xff;
    destination[1].size = 0;
}


// ### opendir, readdir, closedir 
/*uint8_t filemanager_get_directory_cbm(directory_entry_t* directory, uint8_t device)
{
    struct cbm_dirent l_dirent;
    uint8_t retval;    
    
    filemanager_empty_directory(directory);
    
    filemanager_busy_indicator();
    
    retval = cbm_opendir(device, device);
    if (retval != 0) {
        cbm_closedir(device);
        filemanager_done_indicator();
        return retval;    
    }
    
    while (true) {
        
    
    
        filemanager_busy_indicator();
    }
    
    filemanager_done_indicator();
    return 0;
}*/


uint8_t filemanager_get_directory(directory_entry_t* directory, uint8_t device)
{
    uint8_t retval, status;
    uint8_t value, state;
    uint16_t counter, entry, emergency;
    uint8_t var1;
    uint16_t var2;
    char var3[8];
    
    filemanager_empty_directory(directory);
    
    if (device > 0) {
        // iec device
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

    emergency = 0;
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
            goto finish;
        }
        counter++;
        emergency++;
        if (emergency > 17000) {
            // escape potential deadlocks
            retval = 0xfe;
            filemanager_empty_directory(directory);
            goto finish;
        }
        
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
                directory[0].size = 0; // disk name
                directory[0].flags = 0; // disk name
                var1 = 0;
                break;
            case 4:
                if (value == 0x22) {
                    state = 5; // end of directory header
                    directory[entry].name[var1] = 0;
                    break;
                }
                directory[entry].name[var1] = value;
                var1++;
                break;
            case 5:
                if (value != 0) break;
                entry++;
                state = 10; // file entries
                break;
            
            case 10: // line number field
                if (value != 1) goto error;
                state++;
                break;
            case 11: // line number field
                if (value != 1) goto error;
                state++;
                var1 = 0;
                break;
            case 12: // file size
                if (var1 == 0) {
                    var1++;
                    var2 = value;
                } else {
                    var2 += ((uint16_t)value) * 256;
                    directory[entry].size = var2;
                    state++;
                }
                break;
            case 13: // quotation mark or end of dir
                if (value == 0) { // end of directory
                    directory[entry].name[0] = 0;
                    directory[entry].flags = 0xff;
                    directory[0].size = entry - 1;
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
                    directory[entry].name[var1] == 0;
                    state++;
                    var1 = 0;
                    break;
                }
                directory[entry].name[var1] = value;
                var1++;
                directory[entry].name[var1] = 0;
                break;
            case 15: // type and next line
                if (value == 0) {
                    // next line
                    directory[entry].flags = text_to_type(var3);
                    entry++;
                    state = 10;
                    filemanager_busy_indicator();
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
error:
    retval = 0xfe;
    
finish:
    if (device > 0) {
        cbm_k_close(1);
    } else {
        EFS_close_wrapper();
    }
    filemanager_done_indicator();
    return retval;
}


char* identity_to_text(uint8_t ident)
{
    switch (ident) {
        case 0x01:
             return "classic save game";
        case 0x02:
             return "classic best times";
        case 0x03:
             return "classic castle";
        case 0x12:
             return "remastered best times";
         case 0x13:
             return "remastered castle";
        default:
             return "other file";
    }
}


directory_entry_t* get_index_entry(directory_entry_t* directory, uint16_t index)
{
    if (index > directory[0].size) return NULL;
    return &directory[index];
}

uint8_t get_index_max(directory_entry_t* directory)
{
    
    return directory[0].size;
}


uint8_t next_item(directory_entry_t* directory, uint16_t index, uint16_t step)
{
    if (index+step >= get_index_max(directory)) return get_index_max(directory);
    index += step;
    return index;
}

uint8_t previous_item(uint16_t index, uint16_t step)
{
    if (step >= index) return 1;
    index -= step;
    return index;
}

char* get_headline(directory_entry_t* directory)
{
    return directory[0].name;
}



// -----------------------------------------------------------------------

void draw_help()
{
    //                  01234567890123456789
    cputsxy(FILES_WIDTH+2, 1, "F1:focus efs");
    cputsxy(FILES_WIDTH+2, 2, "F3:focus cbm");
    cputsxy(FILES_WIDTH+2, 3, "F5:next drive");
    cputsxy(FILES_WIDTH+2, 4, "F7:load dir");
    
    cputsxy(FILES_WIDTH+2, 6, "C: copy file");
    cputsxy(FILES_WIDTH+2, 7, "   to ");
    
    cputsxy(FILES_WIDTH+2, 9, "D: del file");
    cputsxy(FILES_WIDTH+2,10, "   from  ");

    cputsxy(FILES_WIDTH+2,12, "I: identify");
    cputsxy(FILES_WIDTH+2,13, "   on  ");

    cputsxy(FILES_WIDTH+2,15, "A: copy all");
    cputsxy(FILES_WIDTH+2,16, "   r/w files");
    cputsxy(FILES_WIDTH+2,17, "   to  ");

    cputsxy(FILES_WIDTH+2,19, "F: format efs");
    cputsxy(FILES_WIDTH+2,20, "V: defragment");    
    cputsxy(FILES_WIDTH+2,21, " : back"); cputcxy(FILES_WIDTH+2,21, 0x5f);

}

void update_help(uint8_t focus)
{
    if (focus == 1) {
        //                  01234567890123456789
        cputsxy(FILES_WIDTH+2, 7, "   to drive");
        cputsxy(FILES_WIDTH+2,10, "   from efs  ");
        cputsxy(FILES_WIDTH+2,13, "   on efs  ");
        cputsxy(FILES_WIDTH+2,16, "   r/w files");
        cputsxy(FILES_WIDTH+2,17, "   to drive ");

    } else if (focus == 2) {
        //                  01234567890123456789
        cputsxy(FILES_WIDTH+2, 7, "   to efs  ");
        cputsxy(FILES_WIDTH+2,10, "   from drive");
        cputsxy(FILES_WIDTH+2,13, "   on drive ");
        cputsxy(FILES_WIDTH+2,16, "   files    ");
        cputsxy(FILES_WIDTH+2,17, "   to efs  ");

    }
}

bool draw_confirmation(char* content)
{
    char c;
    uint8_t n;

    cclearxy(0,24,40);
    textcolor(COLOR_GRAY2);
    n = strlen(content);
    cputsxy(1,24, content);
    cputsxy(2+n, 24, "Are you sure? ");
    cursor(1);
    c = cgetc();
    cursor(0);
    cclearxy(0,24,40);
    return (c == 'y');
}

void draw_listdisplay_header(uint8_t y, char* line, bool focus)
{
    if (focus) textcolor(COLOR_WHITE);
    else textcolor(COLOR_GRAY2);
    chlinexy(1, y, FILES_WIDTH);
    textcolor(COLOR_GRAY2);
    if (line != NULL) {
        gotoxy(2,y+0);
        cprintf("[%s]", line);
    }
}

void draw_listdisplay_footer(uint8_t y, uint8_t height, char* line,  bool focus)
{
    if (focus) textcolor(COLOR_WHITE);
    else textcolor(COLOR_GRAY2);
    chlinexy(1, y+height+1, FILES_WIDTH);
    textcolor(COLOR_GRAY2);
    if (line != NULL) {
        gotoxy(2,y+height+1);
        cprintf("[%s]", line);
    }

}

void draw_listdisplay(uint8_t y, uint8_t height, char* headline, char* footerline, bool focus)
{
    if (focus) textcolor(COLOR_WHITE);
    else textcolor(COLOR_GRAY2);

    chlinexy(1, y+0, FILES_WIDTH); // top
    chlinexy(1, y+height+1, FILES_WIDTH);  // bottom

    draw_listdisplay_header(y, headline, focus);
    draw_listdisplay_footer(y, height, footerline, focus);

    if (focus) textcolor(COLOR_WHITE);
    else textcolor(COLOR_GRAY2);

    cvlinexy(0, y+1, height);
    cvlinexy(FILES_WIDTH+1, y+1, height);
    cputcxy(0, y+0, 0xf0);  // upper left
    cputcxy(FILES_WIDTH+1, y+0, 0xee);  // upper right
    cputcxy(0, y+height+1, 0xed);  // lower left
    cputcxy(FILES_WIDTH+1, y+height+1, 0xfd);  // lower right
    
    textcolor(COLOR_GRAY2);  
}

void draw_listfocus(uint8_t y, uint8_t height, bool focus)
{
    uint8_t i;
    char c;
    char lc;
    
    if (focus) textcolor(COLOR_WHITE);
    else textcolor(COLOR_GRAY2);

    lc = C_chlinechar();
    for (i=1; i<=FILES_WIDTH; i++) {
        gotoxy(i, y+0);
        c = cpeekc();
        if (c == lc) cputc(lc);
    }
    for (i=1; i<=FILES_WIDTH; i++) {
        gotoxy(i, y+height+1);
        c = cpeekc();
        if (c == lc) cputc(lc);
    }
    
    cvlinexy(0, y+1, height);
    cvlinexy(FILES_WIDTH+1, y+1, height);
    cputcxy(0, y+0, 0xf0);  // upper left
    cputcxy(FILES_WIDTH+1, y+0, 0xee);  // upper right
    cputcxy(0, y+height+1, 0xed);  // lower left
    cputcxy(FILES_WIDTH+1, y+height+1, 0xfd);  // lower right
    textcolor(COLOR_GRAY2);
}


void draw_status(uint8_t y, uint8_t height, directory_entry_t* directory, uint8_t device, uint8_t error, bool focus)
{
    char line[30];
    char* text;
    uint8_t status, index;

    if (device > 0) {
        if (error == 0) {
            cbm_device_get_status(device);
            text = cbm_device_last_status();
            status = cbm_k_readst();
            error = cbm_device_last_statuscode();
        } else {
            error = 0xff;
            text = "device not present";
        }
    } else {
        status = EFS_readst_wrapper();
        text = get_error_text_efs(error, status);
        if (status = 0x40 && error == 0xff) error = 0;
    }

    index = directory[0].size + 1;
    if (error == 0) {
        snprintf(line, FILES_WIDTH-2, "%d blocks free", directory[index].size);
    } else {
        snprintf(line, FILES_WIDTH-2, "%s", text);
    }

    draw_listdisplay_footer(y, height, line, focus);
}


void clear_result()
{
    cclearxy(0, 24, 40);
}


void draw_result1(uint8_t device, uint8_t result)
{
    uint8_t retval;
    uint8_t status;
    char* text;

    if (device > 0) {
        cbm_device_get_status(device);
        text = cbm_device_last_status();
        status = cbm_k_readst();
        retval = cbm_device_last_statuscode();
    } else {
        status = EFS_readst_wrapper();
        text = get_error_text_efs(result, status);
        if (status = 0x40 && retval == 0xff) retval = 0;
    }

    if (retval > 0) {
        gotoxy(1,24);
        cprintf("%s", text);
        cclearxy(wherex(), 24, 40-wherex());
    } else {
        cclearxy(0, 24, 40);
    }
}

void draw_result2(uint8_t dstdevice, uint8_t srcdevice, uint16_t combined)
{
    uint8_t srcretval, dstretval;
    uint8_t status;
    char* text;

    dstretval = (combined >> 8);
    srcretval = combined & 0xff;
    
    if (srcdevice > 0) {
        cbm_device_get_status(srcdevice);
        text = cbm_device_last_status();
        status = cbm_k_readst();
        srcretval = cbm_device_last_statuscode();
    } else {
        status = EFS_readst_wrapper();
        text = get_error_text_efs(srcretval, status);
        if (status = 0x40 && srcretval == 0xff) srcretval = 0;
    }

    if (srcretval > 0) {
        gotoxy(1,24);
        cprintf("source: %s", text);
        // clear rest of line
        cclearxy(wherex(), 24, 40-wherex());
        return;
    }
    
    if (dstdevice > 0) {
        cbm_device_get_status(dstdevice);
        text = cbm_device_last_status();
        status = cbm_k_readst();
        dstretval = cbm_device_last_statuscode();
    } else {
        status = EFS_readst_wrapper();
        text = get_error_text_efs(dstretval, status);
        if (status = 0x40 && dstretval == 0xff) dstretval = 0;
    }

    if (dstretval > 0) {
        gotoxy(1,24);
        cprintf("dest: %s", text);
        // clear rest of line
        cclearxy(wherex(), 24, 40-wherex());
        return;
    }
    
    cclearxy(0, 24, 40);
    
}

void draw_process(char* filename, char* process)
{
    gotoxy(1,24);
    cprintf("%s %s", process, filename);
}


void clear_listcontent(uint8_t y, uint8_t height)
{
    uint16_t i;

    for (i=0; i<height; i++) {
        cclearxy(1, y+1+i, FILES_WIDTH);
    }
}

void draw_listcontent_line(uint8_t y, directory_entry_t* entry, bool highlight)
{
    if (highlight) revers(1);
    if (entry != NULL) {
        cclearxy(1, y, FILES_WIDTH);
        gotoxy(1, y); cprintf("%1d", entry->size);
        cputsxy(6, y, entry->name);
        if (entry->flags & 0x80) cputcxy(22, y, '>'); //else cputcxy(22, y, ' ');
        cputsxy(23, y, type_to_text(entry->flags));
    } else {
        cclearxy(1, y, FILES_WIDTH);
    }
    revers(0);
}

void draw_listcontent(uint8_t y, uint8_t height, directory_entry_t* directory, uint16_t index, uint16_t* page, bool focus)
{
    uint16_t index_offset = *page;
    uint16_t i, pos;
    uint16_t max = get_index_max(directory);
    //uint16_t skip = 1;

    // start offset
    if (index+1 >= index_offset+height) {
        index_offset += index - (index_offset + height) + 1;
        if (index_offset+height >= max) index_offset = max - height + 1;
    }
    if (index < index_offset) {
        if (index_offset <= height) index_offset = 1;
        else index_offset -= index_offset - index; 
    }
    for (i=0; i<height; i++) {
        if (i+index_offset <= max) {
            pos = i+index_offset;
            draw_listcontent_line(y+i+1, &directory[pos], (index == pos && focus));
        } else {
            draw_listcontent_line(y+i+1, NULL, false);
        }
    }
    
    *page = index_offset;

//    if (index_offset > 0) cputcxy(FILES_WIDTH+1, y+2, 0xf1); else cputcxy(FILES_WIDTH+1, y+2, 0xdd);
//    if (index_offset+height < max) cputcxy(FILES_WIDTH+1, y+1+height-2, 0xf2); else cputcxy(FILES_WIDTH+1, y+1+height-2, 0xdd);
}


uint8_t check_for_device(directory_entry_t* directory, uint8_t device, bool focus)
{
    uint8_t retval;
    char text[10];

    sprintf(text, "cbm #%d", device);
    draw_listdisplay_header(CBM_POSITION, text, focus);
    clear_listcontent(CBM_POSITION, FILES_HEIGHT);

    retval = cbm_device_ispresent(device);
    if (retval == 1) {
        draw_status(CBM_POSITION, FILES_HEIGHT, directory, device, retval, focus);
        return 0;
    }

    filemanager_busy_indicator_column(CBM_POSITION);
    retval = filemanager_get_directory(directory, device);
    if (retval == 0) draw_listdisplay_header(CBM_POSITION, get_headline(directory), focus);
    draw_status(CBM_POSITION, FILES_HEIGHT, directory, device, 0, focus);

    return 2;
}


void identify_single_file(directory_entry_t* directory, uint16_t index, uint8_t device)
{
    directory_entry_t* entry;
    uint8_t type;
    char* text;
    
    entry = get_index_entry(directory, index);
    type = filemanager_identify_file(entry, device);
    
    text = identity_to_text(type);

    gotoxy(1,24);
    cprintf("%s: %s", entry->name, text);

    // $00: unknown file (no codc file)
    // $01: classic save game: *, $7800
    // $02: classic best times file: y, $
    // $03: classic castle: z*, $7800
    // $11: (none)
    // $12: remastered best times file: Y*, $6400
    // $13: remastered castle; Z*, $7800    
}

uint8_t copy_single_file(uint8_t dstdevice, directory_entry_t* directory, uint16_t index, uint8_t srcdevice)
{
    directory_entry_t* entry;
    uint8_t combined;
        
    entry = get_index_entry(directory, index);
    if (entry == 0) return 0xff;

    draw_process(entry->name, "copy");
    combined = copy_file(dstdevice, entry, srcdevice);
    draw_result2(dstdevice, srcdevice, combined);
    return 0;
}

uint8_t copy_all_files(uint8_t dstdevice, directory_entry_t* directory, uint8_t srcdevice)
{
    directory_entry_t* entry;
    uint8_t combined;
    uint16_t index = 0;
    uint16_t count;
    
    count = get_index_max(directory);
    for (index=1; index<=count; index++) {
        entry = get_index_entry(directory, index);
        if (entry->flags & 0x80) continue;
        
        draw_process(entry->name, "copy");
        combined = copy_file(dstdevice, entry, srcdevice);
        draw_result2(dstdevice, srcdevice, combined);
    }

    return 0;
}


uint8_t delete_single_file(directory_entry_t* directory, uint16_t index, uint8_t device)
{
    uint8_t retval;
    directory_entry_t* entry;
    uint16_t n;
    char textline[25];

    entry = get_index_entry(directory, index);
    n = sprintf(textline, "s0:%s", entry->name);
    textline[n] = 0;

    if (device > 0) {
        // iec device
        cbm_k_setlfs(15, device, 15);
        cbm_k_setnam(textline);
        retval = cbm_k_open();
        cbm_k_close(15);
    } else {
        // efs
        EFS_setnam_wrapper(textline, strlen(textline));
        EFS_setlfs_wrapper(0);
        retval = EFS_open_wrapper(0);
        EFS_close_wrapper();
    }

    draw_result1(device, retval);
    return 0;
}

uint8_t format_efs()
{
    bool ok;
    
    // are you sure
    ok = draw_confirmation("Formatting. ");
    if (!ok) return 0;

    EFS_format_wrapper();
    clear_result();
    
    return 0x11;
}

uint8_t defragment_efs()
{

    gotoxy(1,24);
    cprintf("Defragmenting ... may take a while");
        
    EFS_defragment_wrapper();
    clear_result();

    return 0;
}

void main(void)
{
    directory_entry_t* directory_efs;
    directory_entry_t* directory_cbm;
    uint8_t device, repaint;
    uint16_t index_efs, index_cbm;
    uint16_t page_efs, page_cbm;
    uint8_t retval, focus;
    uint16_t position;

    // init
    clrscr();
    textcolor(COLOR_GRAY2);
    repaint = 1;
    position = 1;
    index_efs = 1; page_efs = 1;
    index_cbm = 1; page_cbm = 1;
    device = 0;
    focus = 1;
    
    draw_help();
    update_help(focus);

    draw_listdisplay(EFS_POSITION, FILES_HEIGHT, "efs", NULL, true);
    draw_listdisplay(CBM_POSITION, FILES_HEIGHT, "cbm", NULL, false);

    directory_efs = NULL;
    directory_cbm = NULL;
    
    directory_efs = filemanager_init(directory_efs, 256);
    filemanager_empty_directory(directory_efs);
    directory_cbm = filemanager_init(directory_cbm, 256);
    filemanager_empty_directory(directory_cbm);
    
    repaint = 0b00010001;
    
    while (kbhit()) cgetc();

    for (;;) {
        if (repaint > 0) {
            if (repaint & 0x10) {
                clear_listcontent(EFS_POSITION, FILES_HEIGHT);
                filemanager_busy_indicator_column(EFS_POSITION);
                retval = filemanager_get_directory(directory_efs, 0);
                draw_listdisplay_header(EFS_POSITION, get_headline(directory_efs), (focus==1));
                draw_status(EFS_POSITION, FILES_HEIGHT, directory_efs, 0, retval, (focus==1));
            }
            if (repaint & 0x20) {
                clear_listcontent(CBM_POSITION, FILES_HEIGHT);
                filemanager_busy_indicator_column(CBM_POSITION);
                retval = filemanager_get_directory(directory_cbm, device);
                draw_listdisplay_header(CBM_POSITION, get_headline(directory_efs), (focus==2));
                draw_status(CBM_POSITION, FILES_HEIGHT, directory_cbm, device, retval, (focus==2));
            }
        
            if (repaint & 0x01) {
                draw_listcontent(EFS_POSITION, FILES_HEIGHT, directory_efs, index_efs, &page_efs, (focus==1));
            }
            if (repaint & 0x02) {
                draw_listcontent(CBM_POSITION, FILES_HEIGHT, directory_cbm, index_cbm, &page_cbm, (focus==2));
            }
            repaint = 0;
        }
        
        //gotoxy(1,24); cprintf("i=%d p=%d", index_efs, page_efs);

        retval = cgetc();
        
        clear_result();
        
        switch (retval) {
            case 0x5f: // back arrow
                GAME_startup_menu_wrapper();
                break;

            case 0x11: // down
                if (focus == 1) {
                    index_efs = next_item(directory_efs, index_efs, 1);
                    repaint = 0x01;
                } else { // focus == 2
                    index_cbm = next_item(directory_cbm, index_cbm, 1);
                    repaint = 0x02;
                }
                break;
            case 0x1d: // right
                if (focus == 1) {
                    index_efs = next_item(directory_efs, index_efs, FILES_HEIGHT);
                    repaint = 0x01;
                } else { // focus == 2
                    index_cbm = next_item(directory_cbm, index_cbm, FILES_HEIGHT);
                    repaint = 0x02;
                }
                break;
            case 0x91: // up
                if (focus == 1) {
                    index_efs = previous_item(index_efs, 1);
                    repaint = 0x01;
                } else { // focus == 2
                    index_cbm = previous_item(index_cbm, 1);
                    repaint = 0x02;
                }
                break;
            case 0x9d: // left
                if (focus == 1) {
                    index_efs = previous_item(index_efs, FILES_HEIGHT);
                    repaint = 0x01;
                } else { // focus == 2
                    index_cbm = previous_item(index_cbm, FILES_HEIGHT);
                    repaint = 0x02;
                }
                repaint = 1;
                break;

            case 0x85: // F1 focus on efs
                draw_listfocus(EFS_POSITION, FILES_HEIGHT, true);
                draw_listfocus(CBM_POSITION, FILES_HEIGHT, false);
                focus = 1;
                repaint = 3;
                update_help(focus);
                break;
            case 0x86: // F3 focus on cbm
                draw_listfocus(EFS_POSITION, FILES_HEIGHT, false);
                draw_listfocus(CBM_POSITION, FILES_HEIGHT, true);
                focus = 2;
                repaint = 3;
                update_help(focus);
                break;
            case 0x87: // F5 change drive
                if (device == 0) device = 8;
                else device++;
                if (device == 12) device = 8;
                repaint = check_for_device(directory_cbm, device, (focus==2));
                break;
            case 0x88: // F7 reload dir
                if (device == 0) device = 8;
                repaint = check_for_device(directory_cbm, device, (focus==2));
                break;

            case 'f': // format
                repaint = format_efs();
                if (repaint > 0) index_efs = 1;
                break;

            case 'v': // defragment
                defragment_efs();
                break;

            case 'i': // identify
                if (focus == 1) {
                    identify_single_file(directory_efs, index_efs, 0);
                } else {
                    if (device == 0) break;
                    identify_single_file(directory_cbm, index_cbm, device);
                }
                break;

            case 'd': // delete
                if (focus == 1) {
                    delete_single_file(directory_efs, index_efs, 0);
                    if (index_efs > 1) index_efs--;
                    repaint = 0x11;
                } else {
                    if (device == 0) break;
                    delete_single_file(directory_cbm, index_cbm, device);
                    if (index_cbm > 1) index_cbm--;
                    repaint = 0x22;
                }
                break;

            case 'c': // copy single file
                if (device == 0) break;
                if (focus == 1) {
                    // copy to drv
                    copy_single_file(device, directory_efs, index_efs, 0);
                    repaint = 0x22;
                } else {
                    // copy to efs
                    copy_single_file(0, directory_cbm, index_cbm, device);
                    repaint = 0x11;
                }
                break;

            case 'a': // copy all files
                if (device == 0) break;
                if (focus == 1) {
                    // copy to drv
                    copy_all_files(device, directory_efs, 0);
                    repaint = 0x22;
                } else {
                    // copy to efs
                    copy_all_files(0, directory_cbm, device);
                    repaint = 0x11;
                }
                break;
                
            default: 
                break;
        }
    }
}

