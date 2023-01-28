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


.export wrapper_save


.segment "IO_WRAPPER"

    ; starts at $0347 - $03c9
    ; must not exceed 130 bytes


    wrapper_save:
        jsr wrapper_enter
        jsr EFS_save
        jmp wrapper_leave


    wrapper_enter:
        pha
        tya
        pha

        ; save memory config
        lda $01
        sta wrapper_memory_conf

        sei  ; cannot run with active interrupts

        ; save $0400, $0500, %0600 area
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
   
        ; init eapi
        lda #$04     ; load to $0400
        jsr EFS_init_eapi

        pla
        tay
        pla
        rts


    wrapper_leave:
        php
        pha
        tya
        pha

        ; set minieapi for loading
        jsr wrapper_bankin
        jsr EFS_init_minieapi

        jsr wrapper_bankout

        ; restore $400 area
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


    wrapper_memory_conf = * + 1
        lda #37
        sta $01

        cli

        pla
        tay
        pla
        plp
        rts



.segment "IO_BANKING"

    wrapper_bankin:
        lda #$37
        sta $01
        lda #$87     ; led, 16k mode
        sta $de02
        lda #$00     ; rom bank of efslib
        sta $de00
        rts


    wrapper_bankout:
        lda #$04
        sta $de02
        lda #$30  ; bank in memory under io
        sta $01
        rts
