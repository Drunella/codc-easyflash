; ----------------------------------------------------------------------------
; The Castles of Dr Creep - CREEPLOAD.PRG: Loader Code from $c000 to $c22e
; adapted for EasyFlash by Drunella
; ----------------------------------------------------------------------------


.include "easyflash.i"

.export startup_original_execute
;.import WrapperStart


.segment "GAMESTART_BODY"

; ----------------------------------------------------------------------------
L0800           := $0800
; ----------------------------------------------------------------------------

startup_original_execute:
        lda     #$00                            ; C000 A9 00                    ..
        sta     $14                             ; C002 85 14                    ..
        lda     #$04                            ; C004 A9 04                    ..
        sta     $15                             ; C006 85 15                    ..
        lda     #$00                            ; C008 A9 00                    ..
        sta     $16                             ; C00A 85 16                    ..
        lda     #$D8                            ; C00C A9 D8                    ..
        sta     $17                             ; C00E 85 17                    ..
        ldy     #$00                            ; C010 A0 00                    ..
LC012:  lda     #$20                            ; C012 A9 20                    . 
LC014:  sta     ($14),y                         ; C014 91 14                    ..
        sta     ($16),y                         ; C016 91 16                    ..
        iny                                     ; C018 C8                       .
        bne     LC014                           ; C019 D0 F9                    ..
        inc     $15                             ; C01B E6 15                    ..
        inc     $17                             ; C01D E6 17                    ..
        lda     $15                             ; C01F A5 15                    ..
        cmp     #$08                            ; C021 C9 08                    ..
        bne     LC012                           ; C023 D0 ED                    ..
textstart_low   := * + 1
        lda     #<textstart
        sta     $14                             ; C027 85 14                    ..
textstart_high  := * + 1
        lda     #>textstart
        sta     $15                             ; C02B 85 15                    ..
LC02D:  ldy     #$00                            ; C02D A0 00                    ..
        lda     ($14),y                         ; C02F B1 14                    ..
        bmi     LC07E                           ; C031 30 4B                    0K
        ldy     #$01                            ; C033 A0 01                    ..
        lda     ($14),y                         ; C035 B1 14                    ..
        asl     a                               ; C037 0A                       .
        tax                                     ; C038 AA                       .
        lda     linesstart,x                    ; C039 BD 6B C1                 .k.
        sta     $16                             ; C03C 85 16                    ..
        lda     linesstart+1,x                  ; C03E BD 6C C1                 .l.
        sta     $17                             ; C041 85 17                    ..
        dey                                     ; C043 88                       .
        clc                                     ; C044 18                       .
        lda     $16                             ; C045 A5 16                    ..
        adc     ($14),y                         ; C047 71 14                    q.
        sta     $16                             ; C049 85 16                    ..
        lda     $17                             ; C04B A5 17                    ..
        adc     #$00                            ; C04D 69 00                    i.
        sta     $17                             ; C04F 85 17                    ..
        clc                                     ; C051 18                       .
        lda     $14                             ; C052 A5 14                    ..
        adc     #$02                            ; C054 69 02                    i.
        sta     $14                             ; C056 85 14                    ..
        lda     $15                             ; C058 A5 15                    ..
        adc     #$00                            ; C05A 69 00                    i.
        sta     $15                             ; C05C 85 15                    ..
        ldy     #$00                            ; C05E A0 00                    ..
LC060:  lda     ($14),y                         ; C060 B1 14                    ..
        bmi     LC06A                           ; C062 30 06                    0.
        sta     ($16),y                         ; C064 91 16                    ..
        iny                                     ; C066 C8                       .
        jmp     LC060                           ; C067 4C 60 C0                 L`.

; ----------------------------------------------------------------------------
LC06A:  and     #$7F                            ; C06A 29 7F                    ).
        sta     ($16),y                         ; C06C 91 16                    ..
        iny                                     ; C06E C8                       .
        tya                                     ; C06F 98                       .
        clc                                     ; C070 18                       .
        adc     $14                             ; C071 65 14                    e.
        sta     $14                             ; C073 85 14                    ..
        lda     $15                             ; C075 A5 15                    ..
        adc     #$00                            ; C077 69 00                    i.
        sta     $15                             ; C079 85 15                    ..
        jmp     LC02D                           ; C07B 4C 2D C0                 L-.

; ----------------------------------------------------------------------------
LC07E:  lda     #$07                            ; C07E A9 07                    ..
        sta     $D020                           ; C080 8D 20 D0                 . .
        sta     $D021                           ; C083 8D 21 D0                 .!.
        lda     #$16                            ; C086 A9 16                    ..
        sta     $D018                           ; C088 8D 18 D0                 ...
        lda     #$02                            ; C08B A9 02                    ..
        ldx     #$08                            ; C08D A2 08                    ..
        ldy     #$00                            ; C08F A0 00                    ..
        jsr     EFS_setlfs                      ; C091 20 BA FF                  ..
        lda     #titlepiclength
        ldx     #<titlepicname
        ldy     #>titlepicname
        jsr     EFS_setnam                      ; C09A 20 BD FF                  ..
        lda     #$00                            ; C09D A9 00                    ..
        ldx     #$00                            ; C09F A2 00                    ..
        ldy     #$08                            ; C0A1 A0 08                    ..
        jsr     EFS_load                        ; C0A3 20 D5 FF                  ..
        lda     #$40                            ; C0A6 A9 40                    .@
        sta     $14                             ; C0A8 85 14                    ..
        lda     #$27                            ; C0AA A9 27                    .'
        sta     $15                             ; C0AC 85 15                    ..
        lda     #$00                            ; C0AE A9 00                    ..
        sta     $16                             ; C0B0 85 16                    ..
        lda     #$CC                            ; C0B2 A9 CC                    ..
        sta     $17                             ; C0B4 85 17                    ..
        ldy     #$00                            ; C0B6 A0 00                    ..
LC0B8:  lda     ($14),y                         ; C0B8 B1 14                    ..
        sta     ($16),y                         ; C0BA 91 16                    ..
        iny                                     ; C0BC C8                       .
        bne     LC0B8                           ; C0BD D0 F9                    ..
        inc     $15                             ; C0BF E6 15                    ..
        inc     $17                             ; C0C1 E6 17                    ..
        lda     $17                             ; C0C3 A5 17                    ..
        cmp     #$D0                            ; C0C5 C9 D0                    ..
        bne     LC0B8                           ; C0C7 D0 EF                    ..
        lda     #$00                            ; C0C9 A9 00                    ..
        sta     $14                             ; C0CB 85 14                    ..
        lda     #$08                            ; C0CD A9 08                    ..
        sta     $15                             ; C0CF 85 15                    ..
        lda     #$00                            ; C0D1 A9 00                    ..
        sta     $16                             ; C0D3 85 16                    ..
        lda     #$E0                            ; C0D5 A9 E0                    ..
        sta     $17                             ; C0D7 85 17                    ..
        ldy     #$00                            ; C0D9 A0 00                    ..
LC0DB:  lda     ($14),y                         ; C0DB B1 14                    ..
        sta     ($16),y                         ; C0DD 91 16                    ..
        iny                                     ; C0DF C8                       .
        bne     LC0DB                           ; C0E0 D0 F9                    ..
        inc     $15                             ; C0E2 E6 15                    ..
        inc     $17                             ; C0E4 E6 17                    ..
        lda     $17                             ; C0E6 A5 17                    ..
        cmp     #$00                            ; C0E8 C9 00                    ..
        bne     LC0DB                           ; C0EA D0 EF                    ..
        lda     #$28                            ; C0EC A9 28                    .(
        sta     $14                             ; C0EE 85 14                    ..
        lda     #$2B                            ; C0F0 A9 2B                    .+
        sta     $15                             ; C0F2 85 15                    ..
        lda     #$00                            ; C0F4 A9 00                    ..
        sta     $16                             ; C0F6 85 16                    ..
        lda     #$D8                            ; C0F8 A9 D8                    ..
        sta     $17                             ; C0FA 85 17                    ..
        ldy     #$00                            ; C0FC A0 00                    ..
LC0FE:  lda     ($14),y                         ; C0FE B1 14                    ..
        sta     ($16),y                         ; C100 91 16                    ..
        iny                                     ; C102 C8                       .
        bne     LC0FE                           ; C103 D0 F9                    ..
        inc     $15                             ; C105 E6 15                    ..
        inc     $17                             ; C107 E6 17                    ..
        lda     $17                             ; C109 A5 17                    ..
        cmp     #$DC                            ; C10B C9 DC                    ..
        bne     LC0FE                           ; C10D D0 EF                    ..
        lda     $DD02                           ; C10F AD 02 DD                 ...
        ora     #$03                            ; C112 09 03                    ..
        sta     $DD02                           ; C114 8D 02 DD                 ...
        lda     $DD00                           ; C117 AD 00 DD                 ...
        and     #$FC                            ; C11A 29 FC                    ).
        sta     $DD00                           ; C11C 8D 00 DD                 ...
        lda     #$3B                            ; C11F A9 3B                    .;
        sta     $D011                           ; C121 8D 11 D0                 ...
        lda     #$18                            ; C124 A9 18                    ..
        sta     $D016                           ; C126 8D 16 D0                 ...
        lda     #$38                            ; C129 A9 38                    .8
        sta     $D018                           ; C12B 8D 18 D0                 ...
        lda     #$07                            ; C12E A9 07                    ..
        sta     $D020                           ; C130 8D 20 D0                 . .
        lda     #$01                            ; C133 A9 01                    ..
        sta     $D021                           ; C135 8D 21 D0                 .!.
        lda     #$02                            ; C138 A9 02                    ..
        ldx     #$08                            ; C13A A2 08                    ..
        ldy     #$00                            ; C13C A0 00                    ..
        jsr     EFS_setlfs                      ; C13E 20 BA FF                  ..
        lda     #objectlength
        ldx     #<objectname
        ldy     #>objectname
        jsr     EFS_setnam                      ; C147 20 BD FF                  ..
        lda     #$00                            ; C14A A9 00                    ..
        ldx     #$00                            ; C14C A2 00                    ..
        ldy     #$08                            ; C14E A0 08                    ..
        jsr     EFS_load                        ; C150 20 D5 FF                  ..
        jmp     L0800                           ; C153 4C 00 08                 L..

; ----------------------------------------------------------------------------
titlepicname:
        .byte   "titlepic"
titlepiclength = * - titlepicname

objectname:
        .byte   $4F,$42,$4A,$45,$43,$54         ; C165 4F 42 4A 45 43 54        OBJECT
objectlength = * - objectname

; ----------------------------------------------------------------------------
linesstart:
        .word   $0400,$0428,$0450,$0478         ; C16B 00 04 28 04 50 04 78 04  ..(.P.x.
        .word   $04A0,$04C8,$04F0,$0518         ; C173 A0 04 C8 04 F0 04 18 05  ........
        .word   $0540,$0568,$0590,$05B8         ; C17B 40 05 68 05 90 05 B8 05  @.h.....
        .word   $05E0,$0608,$0630,$0658         ; C183 E0 05 08 06 30 06 58 06  ....0.X.
        .word   $0680,$06A8,$06D0,$06F8         ; C18B 80 06 A8 06 D0 06 F8 06  ........
        .word   $0720,$0748,$0770,$0798         ; C193 20 07 48 07 70 07 98 07   .H.p...
        .word   $07C0                           ; C19B C0 07                    ..
; ----------------------------------------------------------------------------
textstart:
        .byte   $06,$01,$42,$52,$30,$44,$45,$52 ; C19D 06 01 42 52 30 44 45 52  ..BR0DER
        .byte   $42,$55,$4E,$44,$20,$53,$4F,$46 ; C1A5 42 55 4E 44 20 53 4F 46  BUND SOF
        .byte   $54,$57,$41,$52,$45,$20,$50,$52 ; C1AD 54 57 41 52 45 20 50 52  TWARE PR
        .byte   $45,$53,$45,$4E,$54,$D3,$06,$0A ; C1B5 45 53 45 4E 54 D3 06 0A  ESENT...
        .byte   $22,$54,$48,$45,$20,$43,$41,$53 ; C1BD 22 54 48 45 20 43 41 53  "THE CAS
        .byte   $54,$4C,$45,$53,$20,$4F,$46,$20 ; C1C5 54 4C 45 53 20 4F 46 20  TLES OF 
        .byte   $44,$4F,$43,$54,$4F,$52,$20,$43 ; C1CD 44 4F 43 54 4F 52 20 43  DOCTOR C
        .byte   $52,$45,$45,$50,$A2,$0F,$0D,$42 ; C1D5 52 45 45 50 A2 0F 0D 42  REEP...B
        .byte   $59,$20,$45,$44,$20,$48,$4F,$42 ; C1DD 59 20 45 44 20 48 4F 42  Y ED HOB
        .byte   $42,$D3,$02,$17,$50,$4C,$45,$41 ; C1E5 42 D3 02 17 50 4C 45 41  B...PLEA
        .byte   $53,$45,$20,$41,$4C,$4C,$4F,$57 ; C1ED 53 45 20 41 4C 4C 4F 57  SE ALLOW
        .byte   $20,$54,$57,$4F,$20,$4D,$49,$4E ; C1F5 20 54 57 4F 20 4D 49 4E   TWO MIN
        .byte   $55,$54,$45,$53,$20,$46,$4F,$52 ; C1FD 55 54 45 53 20 46 4F 52  UTES FOR
        .byte   $20,$4C,$4F,$41,$44,$49,$4E,$C7 ; C205 20 4C 4F 41 44 49 4E C7   LOADIN.
        .byte   $05,$0F,$28,$43,$29,$20,$31,$39 ; C20D 05 0F 28 43 29 20 31 39  ..(C) 19
        .byte   $38,$34,$20,$42,$52,$30,$44,$45 ; C215 38 34 20 42 52 30 44 45  84 BR0DE
        .byte   $52,$42,$55,$4E,$44,$20,$53,$4F ; C21D 52 42 55 4E 44 20 53 4F  RBUND SO
        .byte   $46,$54,$57,$41,$52,$C5,$80,$00 ; C225 46 54 57 41 52 C5 80 00  FTWAR...
        .byte   $00                             ; C22D 00                       .
        .byte   $00                             ; C22E 00                       .

; End of "CODE" segment
; ----------------------------------------------------------------------------

