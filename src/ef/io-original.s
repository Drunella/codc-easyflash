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


.export wrapper_setlfs
.export wrapper_setnam
.export wrapper_load
.export wrapper_save
.export wrapper_readst


.segment "IO_WRAPPER"

    ; starts at $1e8f
    ; should not exceed 128 bytes

    check_disk:
        rts

    wrapper_readst:
        ; @ &1e90
        jmp EFS_readst

    wrapper_setlfs:
        ; @ $1e93
        jmp EFS_setlfs

    wrapper_setnam:
        ; @ $1e96
        jmp EFS_setnam

    wrapper_load:
        ; @ $1e99
        jsr wrapper_enter
        jsr EFS_load
        jsr wrapper_leave

    wrapper_save:
        ; @ $1ea2
        jsr wrapper_enter
        jsr EFS_save
        jmp wrapper_leave


    wrapper_enter:
        pha
        tya
        pha

        ; disable vic
        lda $d011
        and #%11101111  ; disable 
        sta $d011

        ; save $0400 area
        ldy #$00
      @loop:
        lda $0400, y
        sta $b900, y
        iny
        bne @loop

        ; bank in
        lda $01
        sta wrapper_memory_conf
        lda #$37
        sta $01
        lda #$87     ; led, 16k mode
        sta $de02
        lda #$00     ; rom bank of efslib
        sta $de00
   
        ; init eapi
        lda #$02     ; load to $0200
        jsr EFS_init_eapi

        pla
        tax
        pla
        rts


    wrapper_leave:
        php
        pha
        tya
        pha

        lda wrapper_memory_conf
        sta $01

        ; restore $0400 area
      @loop:
        lda $b900, y
        sta $0400, y
        iny
        bne @loop

        ; enable vic
        lda $d011
        ora #%00010000  ; enable
        sta $d011

        pla
        tay
        pla
        plp
        rts


    wrapper_memory_conf:
        .byte $00



