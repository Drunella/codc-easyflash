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


.import __GAMESTART_CALL_LOAD__
.import __GAMESTART_CALL_RUN__
.import __GAMESTART_CALL_SIZE__

.import __GAMESTART_BODY_LOAD__
.import __GAMESTART_BODY_RUN__
.import __GAMESTART_BODY_SIZE__

.import __IO_WRAPPER_LOAD__
.import __IO_WRAPPER_RUN__
.import __IO_WRAPPER_SIZE__

.import __IO_BANKING_LOAD__
.import __IO_BANKING_RUN__
.import __IO_BANKING_SIZE__

.import __LOWER_START__

.import startup_remastered_execute
.import startup_original_execute

.export _init_loader
.export _startup_menu
.export _startup_manager
.export _startup_game_remastered
.export _startup_game_original
.export WrapperStart


.segment "CODE"

    _init_loader:
        ; void __fastcall__ init_loader(void);

        ; load segment GAMESTART_CALL
        lda #<__GAMESTART_CALL_LOAD__
        sta source_address_low
        lda #>__GAMESTART_CALL_LOAD__
        sta source_address_high
        lda #<__GAMESTART_CALL_RUN__
        sta destination_address_low
        lda #>__GAMESTART_CALL_RUN__
        sta destination_address_high
        lda #<__GAMESTART_CALL_SIZE__
        sta bytes_to_copy_low
        lda #>__GAMESTART_CALL_SIZE__
        sta bytes_to_copy_high
        jsr copy_segment

        ; load segment GAMESTART_BODY
        lda #<__GAMESTART_BODY_LOAD__
        sta source_address_low
        lda #>__GAMESTART_BODY_LOAD__
        sta source_address_high
        lda #<__GAMESTART_BODY_RUN__
        sta destination_address_low
        lda #>__GAMESTART_BODY_RUN__
        sta destination_address_high
        lda #<__GAMESTART_BODY_SIZE__
        sta bytes_to_copy_low
        lda #>__GAMESTART_BODY_SIZE__
        sta bytes_to_copy_high
        jsr copy_segment

        jsr wrapper_prepare

        rts


    bytes_to_copy_low:
         .byte $ff
    bytes_to_copy_high:
         .byte $ff

    copy_segment:
        lda bytes_to_copy_low
        beq copy_segment_loop
        inc bytes_to_copy_high
    copy_segment_loop:
    source_address_low = source_address + 1
    source_address_high = source_address + 2
    source_address:
        lda $ffff
    destination_address_low = destination_address + 1
    destination_address_high = destination_address + 2
    destination_address:
        sta $ffff
        ; increase source
        inc source_address_low
        bne :+
        inc source_address_high
    :   ; increase destination
        inc destination_address_low
        bne :+
        inc destination_address_high
    :   ; decrease size
        dec bytes_to_copy_low
        bne copy_segment_loop
        dec bytes_to_copy_high
        bne copy_segment_loop
        rts



.segment "GAMESTART_CALL"

    _startup_menu:
        jmp startup_menu_body


    _startup_manager:
        ; void __fastcall__ startup_manager(void);
        jmp startup_manager_body


    _startup_game_original:
        ; void __fastcall__ startup_game_original(void);
        jmp startup_original_body


    _startup_game_remastered:
        ; void __fastcall__ startup_game_remastered(void);
        jmp startup_remastered_body



.segment "GAMESTART_BODY"

    loader_text:
        .byte $0c, $0f, $01, $04, $09, $0e, $07, $2e, $2e, $2e  ; "loading..."
    loader_text_len = * - loader_text


    menu_name:
        .byte $4d, $45, $4e, $55  ; "MENU"
    menu_name_end:
    menu_name_length = menu_name_end - menu_name


    manager_name:
        .byte $4d, $41, $4e, $41, $47, $45, $52  ; "MANAGER"
    manager_name_length = * - manager_name


    startup_menu_body:
        jsr startup_clearscreen
        jsr startup_loading_text
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
        jmp $1000


    startup_manager_body:
        jsr startup_clearscreen
        jsr startup_loading_text
        ldy #$01  ; secondary address: load to destination
        jsr EFS_setlfs
        lda #manager_name_length
        ldx #<manager_name
        ldy #>manager_name
        jsr EFS_setnam
        ldx #$00
        ldy #$10
        lda #$00
        jsr EFS_load
        jmp $1000


    startup_clearscreen:
        ldx #$00
        lda #$20
      : sta $0400, x
        sta $0500, x
        sta $0600, x
        sta $0700, x
        inx
        bne :-
        rts


    startup_loading_text:
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
        rts


    startup_original_body:
        jsr restore_minieapi
        jmp startup_original_execute


    startup_remastered_body:
        jsr restore_minieapi
        jmp startup_remastered_execute
        

    restore_minieapi:
        lda #$37
        sta $01
        lda #$80 | $07  ; led, 16k mode
        sta $de02
        lda #$00        ; EFSLIB_ROM_BANK
        sta $de00
        jsr EFS_init

        jsr EFS_init_minieapi

        lda #$36
        sta $01
        lda #$04   ; easyflash off
        sta $de02

        rts
        

; ------------------------------------------------------------------------
; startup remastered game


    wrapper_prepare:
        ldy #$00
      @loop1:
        lda __IO_WRAPPER_LOAD__, y
        sta storage_wrapper_io, y
        iny
        cpy #<__IO_WRAPPER_SIZE__
        bne @loop1
        
        ldy #$00
      @loop2:
        lda __IO_BANKING_LOAD__, y
        sta storage_banking_io, y
        iny
        cpy #<__IO_BANKING_SIZE__
        bne @loop2

        rts


    WrapperStart:
        ldy #$00
      @loop1:
        lda storage_wrapper_io, y
        sta __IO_WRAPPER_RUN__, y
        iny
        cpy #<__IO_WRAPPER_SIZE__
        bne @loop1
        
        ldy #$00
      @loop2:
        lda storage_banking_io, y
        sta __IO_BANKING_RUN__, y
        iny
        cpy #<__IO_BANKING_SIZE__
        bne @loop2

        rts


    storage_wrapper_io = __GAMESTART_BODY_RUN__ + __GAMESTART_BODY_SIZE__

    storage_banking_io = storage_wrapper_io + __IO_WRAPPER_SIZE__

