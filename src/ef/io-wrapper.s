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


.export _wrapper_setnam
.export _wrapper_load
.export _wrapper_save


.segment "IO_WRAPPER"

    _wrapper_setnam:
        ; @ $0200
        jmp wrapper_setnam_body

    _wrapper_load:
        ; @ $0203
        jmp wrapper_load_body

    _wrapper_save:
        ; @ $0206
        jmp wrapper_save_body


    prepare_io:
        ldx #$07  ; backup zp
    :   lda $f8, x
        sta zeropage_backup, x
        dex
        bpl :-

        lda $01  ; save memory config
        sta store_memory

        lda #$37  ; bank to rom area
        sta $01
        lda #EASYFLASH_LED | EASYFLASH_16K
        sta EASYFLASH_CONTROL
        lda #EF_ROM_BANK
        sta EASYFLASH_BANK

        rts


    restore_io:
        ldx #$07
    :   lda zeropage_backup, x
        sta $f8, x
        dex
        bpl :-

        lda store_memory  ; restore memory config
        sta $01

        lda #EASYFLASH_KILL  ; bank out
        sta EASYFLASH_CONTROL

        rts


    wrapper_setnam_body:
        ; A: length; X/Y: name address (x low)
        sta filename_length
        stx filename_address
        sty filename_address + 1;
        clc  ; no error
        rts


    wrapper_load_body:
        ; A: 0=load to address, 1=load to X/Y; X/Y: address
        ; return X/Y: address
        sta load_mode
        stx load_address
        sty load_address + 1
        jsr prepare_io

        jsr rom_wrapper_load
        php  ; save carry

        jsr restore_io

        ldx load_address
        ldy load_address + 1

        plp
        rts


    wrapper_save_body:
        ; A: address of zero page with startaddress; X/Y: end address + 1
        stx save_end_address
        sty save_end_address + 1
        tax
        lda $00, x
        sta save_start_address
        lda $01, x
        sta save_start_address + 1
        jsr prepare_io

        jsr rom_wrapper_save
        php  ; save carry

        jsr restore_io

        plp
        rts


    set_start_bank:
        ; safest way to set eapi shadow bank
        ; A: bank
        jsr EAPISetBank
        lda #EF_ROM_BANK
        sta EASYFLASH_BANK
        rts

    get_byte:
        ; load byte in A
        jsr EAPIReadFlashInc
        pha
        lda #EASYFLASH_LED | EASYFLASH_16K
        sta EASYFLASH_CONTROL
        lda #EF_ROM_BANK
        sta EASYFLASH_BANK
        pla
        rts


    directory_copy_next_entry:
        ; easyflash is banked in but on another bank
        ; EAPIReadFlashInc has been prepared (EAPISetPtr, EAPISetLen)
        ; carry set if no new entry
        ldy #$00

    :   jsr EAPIReadFlashInc
        bcs :+
        sta directory_entry, y
        iny
        cpy #$18
        bne :-
        clc

    :   lda #EF_ROM_BANK
        sta EASYFLASH_BANK
        rts



.segment "IO_ROM"

    rom_wrapper_load:
        jsr rom_directory_find
        bcc :+
        rts  ; not found

    :   jsr rom_fileload_begin

        jsr get_byte  ; load address
        sta $f8
        jsr get_byte
        sta $f9
        lda load_mode  ; 0=load to address, 1=load to X/Y
        bne :+
        lda load_address  ; load to given address
        sta $f8
        lda load_address + 1
        sta $f9

    :   lda $f8
        sta load_address
        lda $f9
        sta load_address + 1
        ldy #$00
      loop:
        jsr get_byte
        sta ($f8), y
        bcs :+

        inc $f8
        bne loop
        inc $f9
        jmp loop

    :   clc
        rts
        

    rom_wrapper_save:
        rts


    rom_fileload_begin:
        ; directory entry in fe/ff
        ldx directory_entry + efs_directory::offset_low
        lda directory_entry + efs_directory::offset_high
        clc
        adc #$80
        tay
        lda #$d0  ; eapi bank mode
        jsr EAPISetPtr

        ldx directory_entry + efs_directory::size_low
        ldy directory_entry + efs_directory::size_high
        lda directory_entry + efs_directory::size_upper
        jsr EAPISetLen

        lda directory_entry + efs_directory::bank
        jsr set_start_bank

        rts


    rom_directory_begin_search:
        ; set pointer and length of directory
        lda #$d0
        ldx #<EFS_FILES_DIR_START
        ldy #>EFS_FILES_DIR_START
        jsr EAPISetPtr
        ldx #$00
        ldy #$18
        lda #$00
        jsr EAPISetLen
        lda #EFS_FILES_DIR_BANK
        jsr set_start_bank
        rts


    rom_directory_is_terminator:
        ; returns C set if current entry is empty (terminator)
        ; returns C clear if there are more entries
        ; uses A, Y, status
        ; must not use X
        ldy #efs_directory::flags
        lda directory_entry, y
        and #$1f
        cmp #$1f
        beq :+
        clc  ; in use or deleted
        rts
    :   sec  ; empty
        rts


    rom_directory_find:
        lda filename_address
        sta $fe
        lda filename_address + 1
        sta $ff
        jsr rom_directory_begin_search

      nextname:
        ; next directory
        jsr directory_copy_next_entry

        ; test if more entries
        jsr rom_directory_is_terminator
        bcc morefiles  ; if not terminator entry (C clear) inspect entry
        sec
        rts

      morefiles:
        ; check if deleted
        ; check if hidden or other wrong type ###
        ; we only allow prg ($01, $02, $03) ###
        ldy #efs_directory::flags
        lda directory_entry, y
        beq nextname    ; if deleted go directly to next name

        ; compare filename
        ldy #$00
      nameloop:
        lda #$2a   ; '*'
        cmp ($fe), y  ; character in name is '*', we have a match
        beq namematch
        lda ($fe), y  ; compare character with character in entry
        cmp directory_entry, y     ; if not equal nextname
        bne nextname
        iny
        cpy filename_length        ; name length check
        bne nameloop               ; more characters
        cpy #$16                   ; full name length reached
        beq namematch              ;   -> match
        lda directory_entry, y     ; character after length is zero
        beq namematch              ;   -> match
        jmp nextname               ; length check failed

      namematch:
        clc
        rts



.segment "IO_DATA"

    directory_entry:
        .byte $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00

    zeropage_backup:
        .byte $00, $00, $00, $00, $00, $00, $00, $00

    filename_address:
        .word $0000

    filename_length:
        .byte $00

    load_mode:
        .byte $00

    load_address:
        .word $0000

    save_start_address:
        .word $0000

    save_end_address:
        .word $0000

    start_bank:
        .byte $00

    store_memory:
        .byte $00
