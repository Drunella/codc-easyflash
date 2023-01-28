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

.import popa 
.import popax
.import sreg

.import _cputc

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

.export _SYS_get_system
.export _TIMER_measure
.export _TIMER_reset


.segment "DATA"

    end_address:
        .word $0000


.segment "CODE"

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
        pha
        txa
        tay
        pla
        tax
        pla

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
        sta <sreg
        stx <sreg+1

;        sei
        jsr EFS_chrin
;        cli

        bcs :+
        ldy #$00
        sta (<sreg), y
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
