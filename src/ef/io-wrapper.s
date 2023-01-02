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


.export wrapper_setnam
.export wrapper_load


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


    wrapper_setnam_body:
        ; A: length; X/Y: name address (x low)
        sta filename_length
        stx filename_address
        sty filename_address + 1;
        rts


    wrapper_load_body:
        ; A: 0=load address in XY, 1=load address from file; X/Y: load address
        stx load_address
        sty load_address + 1

        rts


    wrapper_save_body:
        rts


.segment "IO_ROM"

    prepare_storage:
        rts

    

.segment "IO_DATA"

    filename_address:
        .addr $0000

    filename_length:
        .byte $00

    load_address:
        .addr $0000

