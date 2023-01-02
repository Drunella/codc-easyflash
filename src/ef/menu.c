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


#define MENU_START_Y 12



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
          "\r\n\r\n"
          "     EasyFlash version by Drunella\r\n"
          "\r\n");
}

static void draw_version()
{
    char text[8];
    uint8_t n;
    
    n = sprintf(text, "v%d.%d", get_version_major(), get_version_minor());
    cputsxy(39-n, 24, text);
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
            menu_option('G', "Start game");
            cputs("\r\n");
            menu_option('M', "Savegame management");
            cputs("\r\n");
            menu_option('Q', "Quit to basic");
            draw_version();
        }
        
        repaint = false;
        
        switch (cgetc()) {
        case ' ':
        case 'g':
            menu_clear(MENU_START_Y,24);
            init_loader();
            startup_game(); // does not return
            break;

        case 'm':
            //savegame_main();
            //draw_startmenu();
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
