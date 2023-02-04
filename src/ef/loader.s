; ----------------------------------------------------------------------------
; Copyright 2023 Drunella
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;     http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
; ----------------------------------------------------------------------------


.feature c_comments 

.include "easyflash.i"



.segment "LOADER_CALL"

    _init_loader:
        jmp init_loader_body



.segment "LOADER"

    init_loader_body:
        ; lower character mode
        lda #$17
        sta $d018

        lda $d011  ; enable output
        ora #$10
        sta $d011

        ; write loading...
        ldx #$00
      : lda loader_text, x
        sta $07e8 - loader_text_len, x  ; write text
        lda #$0c  ; COLOR_GRAY2
        sta $dbe8 - loader_text_len, x  ; write color
        inx
        cpx #loader_text_len
        bne :-

        lda #$37
        sta $01
        lda #$80 | $07  ; led, 16k mode
        sta $de02
        lda #$00        ; EFSLIB_ROM_BANK
        sta $de00
        jsr EFS_init

        ;lda #>eapi_buffer
        jsr EFS_init_minieapi

        lda #$36
        sta $01
        lda #$04   ; easyflash off
        sta $de02
        
        ; load menu
        ldy #$01  ; secondary address: load to destination
        jsr EFS_setlfs
        lda #menu_name_length
        ldx #<menu_name
        ldy #>menu_name
        jsr EFS_setnam
        ldx #$00
        ldy #$10
        lda #$00
        jsr EFS_load
;        stx startup + 1
;        sty startup + 2
        
    startup:
        jmp $1000


    loader_text:
        .byte $0c, $0f, $01, $04, $09, $0e, $07, $2e, $2e, $2e  ; "loading..."
    loader_text_end:
    loader_text_len = loader_text_end - loader_text


    menu_name:
        .byte $4d, $45, $4e, $55  ; "MENU"
    menu_name_end:
    menu_name_length = menu_name_end - menu_name

