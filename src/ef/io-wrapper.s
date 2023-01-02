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


    backup_zeropage:
        ldx #$07
    :   lda $f8, x
        sta zeropage_backup, x
        dex
        bpl :-
        rts


    restore_zeropage:
        ldx #$07
    :   lda zeropage_backup, x
        sta $f8, x
        dex
        bpl :-
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
        sta load_mode
        stx load_address
        sty load_address + 1
        jsr backup_zeropage

        jsr restore_zeropage
        clc ; no error
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
        jsr backup_zeropage

        jsr restore_zeropage
        clc ; no error
        rts


.segment "IO_ROM"

    rom_load_file_entry:
        ; name must have been prepared

    

.segment "IO_DATA"

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

    work_bank:
        .byte $00
