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

void cart_kill(void);
void cart_bankin(void);
void cart_bankout(void);
void cart_reset(void);

void menu_clear(uint8_t start, uint8_t stop);
void menu_option(char key, char *desc);

void __fastcall__ init_loader(void);
void __fastcall__ startup_game_original(void);
void __fastcall__ startup_game_remastered(void);

//void __fastcall__ load_eapi(uint8_t highaddress);
 

#endif
