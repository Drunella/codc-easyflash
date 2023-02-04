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

#ifndef UTIL_H
#define UTIL_H

#include <stdint.h>


uint8_t get_version_major(void);
uint8_t get_version_minor(void);
uint8_t get_version_patch(void);

void cart_kill(void);
void cart_bankin(void);
void cart_bankout(void);
void cart_reset(void);

void menu_clear(uint8_t start, uint8_t stop);
void menu_option(char key, char *desc);

void __fastcall__ init_loader(void);
void __fastcall__ startup_game_original(void);
void __fastcall__ startup_game_remastered(void);

uint8_t __fastcall__ EFS_format_wrapper(void);
uint8_t __fastcall__ EFS_defragment_wrapper(void);

void __fastcall__ EFS_init_eapi(void);
char* __fastcall__ EFS_get_endadress(void);
uint8_t __fastcall__ EFS_readst_wrapper(void);
uint8_t __fastcall__ EFS_setnam_wrapper(char* name, uint8_t length);
uint8_t __fastcall__ EFS_setlfs_wrapper(uint8_t secondary);
uint8_t __fastcall__ EFS_load_wrapper(char* address, uint8_t mode);
uint8_t __fastcall__ EFS_open_wrapper(uint8_t mode);
uint8_t __fastcall__ EFS_close_wrapper(void);
uint8_t __fastcall__ EFS_chrin_wrapper(uint8_t* data);
uint8_t __fastcall__ EFS_chrout_wrapper(uint8_t data);
uint8_t __fastcall__ EFS_save_wrapper(char* startaddress, char* endaddress);

void __fastcall__ cbm_device_clear_status(void);
char* __fastcall__ cbm_device_last_status(void);
uint8_t __fastcall__ cbm_device_last_statuscode(void);
void __fastcall__ cbm_device_get_status(uint8_t device);
uint8_t __fastcall__ cbm_device_ispresent(uint8_t device);

uint8_t __fastcall__ C_cvlinechar(void);
uint8_t __fastcall__ C_chlinechar(void);
uint8_t __fastcall__ SYS_get_system(void);
char* get_system_string(void);
void __fastcall__ TIMER_reset(void);
uint32_t __fastcall__ TIMER_measure(void);


#define FILEMANAGER_MEMORY 0x8000

typedef struct {
    char name[17];
    uint8_t flags;
    uint16_t size;  // in blocks
} directory_entry_t;


void savegame_menu(void);


#endif
