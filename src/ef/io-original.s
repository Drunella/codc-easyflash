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

    ; starts at $2c10
    ; should not exceed 199 bytes

    wrapper_readst:
        ; @ 
        jmp EFS_readst

    wrapper_setlfs:
        ; @ 
        jmp EFS_setlfs

    wrapper_setnam:
        ; @ 
        jmp EFS_setnam

    wrapper_load:
        ; @ 
        jmp EFS_load

    wrapper_save:
        ; @ 
        jsr wrapper_enter
        jsr EFS_save
        jmp wrapper_leave


    wrapper_enter:
        pha
        tya
        pha
        txa
        pha

        ; save memory config
        lda $01
        sta wrapper_memory_conf

        ; disable vic
        lda $d020
        sta wrapper_color_backup
        lda #$00
        sta $d020
        lda $d011
        and #%11101111  ; disable 
        sta $d011

        ; save $0400, $0500, %0600 area
        sei  ; no interrupts while io
        lda #$30  ; bank in memory under io
        sta $01
        
        ldy #$00
      @loop:
        lda $0400, y
        sta $d400, y
        lda $0500, y
        sta $d500, y
        lda $0600, y
        sta $d600, y
        iny
        bne @loop

        ; bank in
        lda #$37
        sta $01
        lda #$87     ; led, 16k mode
        sta $de02
        lda #$00     ; rom bank of efslib
        sta $de00
        cli
   
        ; init eapi
        lda #$04     ; load to $0400
        jsr EFS_init_eapi

        ; restore config
        lda wrapper_memory_conf
        sta $01
        lda #$04     ; bankout
        sta $de02

        pla
        tax
        pla
        tay
        pla
        rts


    wrapper_leave:
        php
        pha
        tya
        pha

        lda #$37     ; bankin
        sta $01
        lda #$87     ; led, 16k mode
        sta $de02
        lda #$00     ; rom bank of efslib
        sta $de00
        ; set minieapi for loading
        jsr EFS_init_minieapi

        lda #$04     ; bankout
        sta $de02

        ; restore $0400 area
        sei
        lda #$30     ; bank in memory under io
        sta $01

        ldy #$00
      @loop:
        lda $d400, y
        sta $0400, y
        lda $d500, y
        sta $0500, y
        lda $d600, y
        sta $0600, y
        iny
        bne @loop

        lda wrapper_memory_conf
        sta $01

        ; enable vic
        lda wrapper_color_backup
        sta $d020
        lda $d011
        ora #%00010000  ; enable
        sta $d011

        pla
        tay
        pla
        plp  ; removes sei
        rts


    wrapper_memory_conf:
        .byte $00

    wrapper_color_backup:
        .byte $00
