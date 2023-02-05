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
.localchar '@'

.include "easyflash.i"

.import popa 
.import popax
.importzp sreg
.importzp cvlinechar
.importzp chlinechar

.import _cputc

.export _EFS_init_eapi
.export _EFS_defragment_wrapper
.export _EFS_format_wrapper
.export _EFS_get_endadress
.export _EFS_readst_wrapper
.export _EFS_setnam_wrapper
.export _EFS_setlfs_wrapper
.export _EFS_load_wrapper
.export _EFS_open_wrapper
.export _EFS_close_wrapper
.export _EFS_chrin_wrapper
.export _EFS_chrout_wrapper
.export _EFS_save_wrapper

.export _cbm_device_clear_status
.export _cbm_device_last_status
.export _cbm_device_last_statuscode
.export _cbm_device_get_status
.export _cbm_device_ispresent

.export _GAME_startup_menu_wrapper
.export _C_cvlinechar
.export _C_chlinechar
.export _SYS_get_system
.export _TIMER_measure
.export _TIMER_reset

.export eapi_buffer


; ------------------------------------------------------------------------
; data

.segment "DATA"

    end_address:
        .word $0000


.segment "LOWER"

    ; buffer must not fall into bankable areas
    eapi_buffer:
        .align 256
        .res 768, $00

    name_buffer:
        .res 16, $00



; ------------------------------------------------------------------------
; caller

.segment "CODE"



.segment "CODE"

; ------------------------------------------------------------------------
; efs wrapper

    ; void __fastcall__ EFS_init_eapi(void);
    _EFS_init_eapi:
        ; bank easyflash in
        lda #$37
        sta $01
        lda #$87   ; led, 16k mode
        sta $de02
        lda #$00   ; EFSLIB_ROM_BANK
        sta $de00

        lda #>eapi_buffer
        jsr EFS_init_eapi

        lda #$36
        sta $01
        lda #$04   ; easyflash off
        sta $de02
        rts


    ; uint8_t __fastcall__ EFS_defragment_wrapper(void);
    _EFS_defragment_wrapper:
        ; bank easyflash in
        lda #$37
        sta $01
        lda #$87   ; led, 16k mode
        sta $de02
        lda #$00   ; EFSLIB_ROM_BANK
        sta $de00

;        sei
        jsr EFS_defragment
;        cli
        pha

        lda #$36
        sta $01
        lda #$04   ; easyflash off
        sta $de02
        pla
        ldx #$00
        rts
        

    ; uint8_t __fastcall__ EFS_format_wrapper(void);
    _EFS_format_wrapper:
        ; bank easyflash in
        lda #$37
        sta $01
        lda #$87   ; led, 16k mode
        sta $de02
        lda #$00   ; EFSLIB_ROM_BANK
        sta $de00

;        sei
        jsr EFS_format
;        cli
        pha

        lda #$36
        sta $01
        lda #$04   ; easyflash off
        sta $de02        
        pla
        ldx #$00
        rts
        

    ; char* __fastcall__ EFS_get_endadress(void);
    _EFS_get_endadress:
        lda end_address
        ldx end_address + 1
        rts


    ; uint8_t __fastcall__ EFS_readst_wrapper();
    _EFS_readst_wrapper:
        jsr EFS_readst
        ldx #$00
        rts


    ; uint8_t __fastcall__ EFS_setnam_wrapper(char* name, uint8_t length);
    _EFS_setnam_wrapper:
        pha        ; length in A
        jsr popax  ; name in A/X
        sta @copy + 1
        stx @copy + 2
;        pha
;        txa
;        tay
;        pla
;        tax
;        pla

        pla
        tay
        tax
        beq @done
        dex
      @copy:
        lda $1000, x
        sta name_buffer, x
        dex
        bpl @copy

      @done:
        tya
        ldx #<name_buffer
        ldy #>name_buffer
        ; parameter:
        ;    A: name length
        ;    X: name address low
        ;    Y: name address high
        ; return: none
        jsr EFS_setnam
        bcc :+
        lda #$ff
        ldx #$00
        rts
      : lda #$00
        ldx #$00
        rts


    ; uint8_t __fastcall__ EFS_setlfs_wrapper(uint8_t secondary);
    _EFS_setlfs_wrapper:
        ;pha
        ;jsr popa
        tay
        ;pla
        ;tay
        ;txa

        ; parameter:
        ;    Y: secondary address(0=load, ~0=verify)
        ; return: none
        jsr EFS_setlfs
        bcc :+
        lda #$ff
        ldx #$00
        rts
      : lda #$00
        ldx #$00
        rts


    ; uint8_t __fastcall__ EFS_open_wrapper(uint8_t mode);
    _EFS_open_wrapper:
;        sei
        jsr EFS_open
;        cli

        bcc :+
        cmp #$00
        bne :+
        lda #$ff
    :   ldx #$00
        rts


    ; uint8_t __fastcall__ EFS_close_wrapper();
    _EFS_close_wrapper:
;        sei
        jsr EFS_close
;        cli

        bcc :+
        cmp #$00
        bne :+
        lda #$ff
    :   ldx #$00
        rts


    ; uint8_t __fastcall__ EFS_chrin_wrapper(uint8_t* data);
    _EFS_chrin_wrapper:
        sta sreg
        stx sreg+1

;        sei
        jsr EFS_chrin
;        cli

        bcs :+
        ldy #$00
        sta (sreg), y
        tya
        tax
        rts
    :   cmp #$00
        bne :+
        lda #$ff
    :   ldx #$00
        rts

    ; uint8_t __fastcall__ EFS_chrout_wrapper(uint8_t data);
    _EFS_chrout_wrapper:
;        sei
        jsr EFS_chrout
;        cli
        bcc :+
        cmp #$00
        bne :+
        lda #$ff  ; no error value?
    :   ldx #$00
        rts


    ; uint8_t __fastcall__ EFS_load_wrapper(char* address, uint8_t mode);
    _EFS_load_wrapper:
        pha        ; mode in A
        jsr popax  ; addr in A/X
        pha
        txa
        tay
        pla
        tax
        pla

        ; parameter:
        ;    A: 0=load, 1-255=verify
        ;    X: load address low
        ;    Y: load address high
        ; return:
        ;    A: error code ($04: file not found, $05: device not present; $08: missing filename;
        ;    X: end address low
        ;    Y: end address high
        ;    .C: 1 if error
;        sei
        jsr EFS_load
;        cli

        stx end_address
        sty end_address + 1

        bcc :+
        cmp #$00
        bne :+
        lda #$ff
    :   ldx #$00
        rts


    ; uint8_t __fastcall__ EFS_save_wrapper(char* startaddress, char* endaddress);
    _EFS_save_wrapper:
        pha        ; endaddress in A/X; high
        txa
        pha        ; low

        jsr popax  ; startaddress in A/X -> $40/41
        sta $40    
        stx $41

        pla
        tay
        pla
        tax

        lda #$40
;        sei
        jsr EFS_save
;        cli

        bcc :+
        cmp #$00
        bne :+
        lda #$ff
    :   ldx #$00
        rts


; ------------------------------------------------------------------------
; 1541 functions

.segment "DATA"

    cbm_device_drivenumber:
        .byte $08

    cbm_device_status:
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
        .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    cbm_device_status_cursor:
        .byte $00
    cbm_device_status_code:
        .byte $00


.segment "CODE"

    _cbm_device_clear_status:
        ; void __fastcall__ cbm_device_clear_status();
        ; parameter: none
        ; return: none
        lda #$00
        sta cbm_device_status_cursor
        sta cbm_device_status
        rts


    _cbm_device_last_status:
        ; char* __fastcall__ _device_last_status();
        ; parameter: none
        ; return: A/X (low/high) pointer to status text
        lda #<cbm_device_status
        ldx #>cbm_device_status
        rts


    cbm_device_write_status:
        ldx cbm_device_status_cursor
        sta cbm_device_status, x
        inx
        lda #$00
        sta cbm_device_status, x
        stx cbm_device_status_cursor
        rts


    _cbm_device_last_statuscode:
        ; uint8_t __fastcall__ _device_last_statuscode();
        ; parameter: none
        ; return: A:status code
        lda cbm_device_status
        bne :+  ; return 0 if string is empty
        sta cbm_device_status_code
        rts

      : lda cbm_device_status
        sec
        sbc #$30
        tax
        lda #$00
      : clc
        adc #$0a
        dex
        bne :-
        sta cbm_device_status_code

        lda cbm_device_status + 1
        sec
        sbc #$30
        clc
        adc cbm_device_status_code
        sta cbm_device_status_code
        rts


    _cbm_device_get_status:
        ; void __fastcall_ cbm_device_get_status(uint8_t device)
        ; parameter: A:device number
        pha
        jsr _cbm_device_clear_status

        lda #$00      ; no filename
        ldx #$00
        ldy #$00
        jsr $ffbd     ; call SETNAM

        pla
        tax           ; device number
        lda #$0f      ; file number 15
        ldy #$0f      ; secondary address 15 (error channel)
        jsr $ffba     ; call SETLFS

        jsr $ffc0     ; call OPEN
        bcs :+++      ; if carry set, the file could not be opened

        ldx #$0f      ; filenumber 15
        jsr $ffc6     ; call CHKIN (file 15 now used as input)

      : jsr $ffb7     ; call READST
        bne :+
        jsr $ffcf     ; call CHRIN
        jsr cbm_device_write_status
        jmp :-
      : jsr _cbm_device_last_statuscode

      : lda #$0f      ; filenumber 15
        jsr $ffc3     ; call CLOSE
        jsr $ffcc     ; call CLRCHN
        rts


    _cbm_device_ispresent:
        ; uint8_t __fastcall__ cbm_device_ispresent(uint8_t device);
        ; parameter: A:device number
        ; return: A:0=device present, 1=device not present
        tax
        lda $ba
        pha
        txa
        sta $ba

        jsr _cbm_device_clear_status
        lda #$00
        sta $90       ; clear STATUS flags

        lda $ba       ; device number
        txa
        jsr $ffb1     ; call LISTEN
        lda #$6f      ; secondary address 15 (command channel)
        jsr $ff93     ; call SECLSN (SECOND)
        jsr $ffae     ; call UNLSN
        lda $90       ; get STATUS flags
        bne @np       ; device not present

        lda $ba       ; device number
        jsr $ffb4     ; call TALK
        lda #$6f      ; secondary address 15 (error channel)
        jsr $ff96     ; call SECTLK (TKSA)

      : lda $90       ; get STATUS flags
        bne :+        ; either EOF or error
        jsr $ffa5     ; call IECIN (get byte from IEC bus)
        jsr cbm_device_write_status
        jmp :-        ; next byte
      : jsr $ffab     ; call UNTLK
        pla
        sta $ba
        lda #$00
        ldx #$00
        rts

      @np:
        pla
        sta $ba
        lda #$01
        ldx #$00
        rts



; ------------------------------------------------------------------------
; sys helper

    ; void __fastcall SYS_start_menu:
    _GAME_startup_menu_wrapper:
        jmp GAME_startup_menu


    ; uint8_t __fastcall__ C_cvlinechar()
    _C_cvlinechar:
        lda #cvlinechar + $20
        ldx #$00
        rts


    ; uint8_t __fastcall__ C_chlinechar()
    _C_chlinechar:
        lda #chlinechar + $20
        ldx #$00
        rts


    ; uint8_t __fastcall__ _SYS_get_system()
    _SYS_get_system:
        sei
        ldy #$04
    ld_DEY:
        ldx #$88     ; DEY = $88
    waitline:
        cpy $d012
        bne waitline
        dex
        bmi ld_DEY + 1
    cycle_wait_loop:
        lda $d012 - $7f,x
        dey
        bne cycle_wait_loop
        and #$03
        ldx #$00
        cli
        rts


    ; void __fastcall__ TIMER_reset()
    _TIMER_reset:
        lda #$7f        ; disable all interrupts on CIA#2
        sta $dd0d
        lda #$0
        sta $dd0e       ; stop timer A
        sta $dd0f       ; stop timer B
        lda #$ff
        sta $dd04
        sta $dd05
        sta $dd06
        sta $dd07

        lda #%01000001
        sta $dd0f
        lda #%00000001
        sta $dd0e
        rts


    ; uint32_t __fastcall__ TIMER_measure()
    _TIMER_measure:
        lda #$0
        sta $dd0e       ; stop timer A
        sta $dd0f       ; stop timer B

        lda $dd07
        sta sreg+1
        lda $dd06
        sta sreg
        ldx $dd05
        lda $dd04

        rts


