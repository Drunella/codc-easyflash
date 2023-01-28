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

#include "util.h"


#define MENU_START_Y 14



static void draw_startmenu(void) {
    clrscr();
    textcolor(COLOR_GRAY2);
    //     01234567890123456789001234567890123456789
    cputs("       The Castles of Doctor Creep\r\n"
          "\r\n"
          "               Designed by\r\n"
          "                 Ed Hobb\r\n"
          "\r\n"
          " Copyright (c) 1984 Broderbund Software\r\n"
          "\r\n"
          "          remastered by DrHonz\n\r"
          "\r\n\r\n"
          "     EasyFlash version by Drunella\r\n"
          "\r\n");
}

static void draw_version_and_system()
{
    char text[8];
    uint8_t n;
    char* system;
    
    system = get_system_string();
    cputsxy(0, 24, system);
    cputs(" C64");

    n = sprintf(text, "v%d.%d.%d", get_version_major(), get_version_minor(), get_version_patch());
    cputsxy(39-n, 24, text);
}


void savegame_menu(void)
{
    filemanager_init();
    
    filemanager_test();

}


void main(void)
{
    static bool repaint;
    
    repaint = true;
    bgcolor(COLOR_BLACK);
    bordercolor(COLOR_BLACK);
    draw_startmenu();
    
    while (kbhit()) {
        cgetc();
    }
    
    for (;;) {
        
        if (repaint) {
            menu_clear(MENU_START_Y, 24);
            menu_option('G', "Start original");
            cputs("\r\n");
            menu_option('R', "Start remastered");
            cputs("\r\n");
            menu_option('M', "Savegame management");
            cputs("\r\n");
            menu_option('Q', "Quit to basic");
            draw_version_and_system();
        }
        
        repaint = false;
        
        switch (cgetc()) {
        case 'g':
            menu_clear(MENU_START_Y,24);
            init_loader();
            startup_game_original(); // does not return
            break;

        case 'r':
            menu_clear(MENU_START_Y,24);
            init_loader();
            startup_game_remastered(); // does not return
            break;

        case 'm':
            savegame_menu();
            repaint = true;
            break;

        case 'q':
            cart_kill();
            __asm__("lda #$37");
            __asm__("sta $01");
            __asm__("ldx #$ff");
            __asm__("txs");
            __asm__("jmp $fcfb");
            break;
        }
    }
}
