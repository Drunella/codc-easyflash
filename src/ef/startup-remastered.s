; -------------------------------------------------------------------------------------------------------------- ;
; The Castles of Dr Creep - CREEP.PRG: Loader Code from $c000 to $c22e
; adapted for EasyFlash by Drunella
; -------------------------------------------------------------------------------------------------------------- ;

.include "easyflash.i"

.export startup_remastered_execute
.import WrapperStart


.segment "GAMESTART_BODY"

; -------------------------------------------------------------------------------------------------------------- ;
; compiler settings
; -------------------------------------------------------------------------------------------------------------- ;
WHITE               = $01
YELLOW              = $07
COLORAM           = $D800                         ; $D800-$DBFF

SCROLY            = $D011     ; VIC Control Register 1 (and Vertical Fine Scrolling)  see: SCROLX
SCROLX            = $D016     ; VIC Control Register 2 (and Horizontal Fine Scrolling)   see: SCROLY
VMCSB             = $D018     ; VIC-II Chip Memory Control
EXTCOL            = $D020     ; Border Color
BGCOL0            = $D021     ; Background Color 0 (all text modes, sprite graphics, and multicolor bitmap graphics)

CI2PRA            = $DD00     ; Data Port Register A
VIC_MemBankClr    = $fc       ; 
C2DDRA            = $DD02     ; Data Direction Register A

; ------------------------------------------------------------------------------------------------------------- ;
PtrTxtScreen        = $14                           ; 
PtrTxtScreenLo      = $14                           ; 
PtrTxtScreenHi      = $15                           ; 

PtrColorRam         = $16                           ; 
PtrColorRamLo       = $16                           ; 
PtrColorRamHi       = $17                           ; 

PtrFrom             = $14                           ; 
PtrFromLo           = $14                           ; 
PtrFromHi           = $15                           ; 

PtrTo               = $16                           ; 
PtrToLo             = $16                           ; 
PtrToHi             = $17                           ; 
; ------------------------------------------------------------------------------------------------------------- ;
PicStart            = $0800                         ; start address load picture
MainStart           = $0800                         ; start address game code

ScreenText          = $0400                         ; game info text
ScreenMC            = $cc00                         ; target title picture screen color info
ScreenBitMap        = $e000                         ; target title picture bitmap info

PicBitMap           = PicStart                      ; $0000 - $1f3f - koala picture bitmap
PicColorsMC         = PicStart      + $1f40         ; $1f40 - $2327 - koala picture color video ram
PicColorsRam        = PicColorsMC   + $03e8         ; $2328 - $270f - koala picture color ram 
PicColorsBkgr       = PicColorsRam  + $03e8         ; $2710         - koala picture color background
; -------------------------------------------------------------------------------------------------------------- ;
startup_remastered_execute:
InfoText:           lda #<ScreenText                ; 
                    sta PtrTxtScreenLo              ; 
                    lda #>ScreenText                ; 
                    sta PtrTxtScreenHi              ; 
                    
                    lda #<COLORAM                   ; 
                    sta PtrColorRamLo               ; 
                    lda #>COLORAM                   ; 
                    sta PtrColorRamHi               ; 
                    
                    ldy #$00                        ; 
ClearTxtScrnI:      lda #$20                        ; 
ClearTxtScrn:       sta (PtrTxtScreen),y            ; 
ClearTxtColor:      sta (PtrColorRam),y             ; 
                    iny                             ; 
                    bne ClearTxtScrn                ; 
                    
                    inc PtrTxtScreenHi              ; 
                    inc PtrColorRamHi               ; 
                    lda PtrTxtScreenHi              ; 
                    cmp #<(>ScreenText + $04)       ; $04 pages
                    bne ClearTxtScrnI               ; 
                    
                    lda #<InfoTextRows              ; 
                    sta PtrFromLo                   ; 
                    lda #>InfoTextRows              ; 
                    sta PtrFromHi                   ; 
                    
SetNextTextRow:     ldy #$00                        ; 
                    lda (PtrFrom),y                 ; ($14/$15) points to header of TextRownn
                    bmi LoadPic                     ; ScrnColnn - all text rows processed
                    
                    ldy #$01                        ; 
                    lda (PtrFrom),y                 ; ScrnRownn
                    asl a                           ; *2
                    tax                             ; 
                    lda TabScreenRows,x             ; 
                    sta PtrToLo                     ; 
                    lda TabScreenRows+1,x           ; 
                    sta PtrToHi                     ; ($16/$17) points to screen row start address now
                    
                    dey                             ; $00
                    clc                             ; 
                    lda PtrToLo                     ; 
                    adc (PtrFrom),y                 ; ScrnColnn
                    sta PtrToLo                     ; 
                    lda PtrToHi                     ; 
                    adc #$00                        ; 
                    sta PtrToHi                     ; ($16/$17) points to screen row/col start address now
                    
                    clc                             ; 
                    lda PtrFromLo                   ; 
                    adc #$02                        ; text header length
                    sta PtrFromLo                   ; 
                    lda PtrFromHi                   ; 
                    adc #$00                        ; 
                    sta PtrFromHi                   ; ($14/$15) points to TextRownn now
                    
                    ldy #$00                        ; 
TextRowOut:          lda (PtrFrom),y                 ; 
                    bmi LastCharOut                 ; 
                    
                    sta (PtrTo),y                   ; 
                    iny                             ; 
                    jmp TextRowOut                  ; 
                    
LastCharOut:        and #$7f                        ;
                    sta (PtrTo),y                   ; 
                    
                    iny                             ; length last text row
                    tya                             ; 
                    clc                             ; 
                    adc PtrFromLo                   ; 
                    sta PtrFromLo                   ; 
                    lda PtrFromHi                   ; 
                    adc #$00                        ; 
                    sta PtrFromHi                   ; ($14/$15) points to header of next TextRownn now
                    jmp SetNextTextRow              ; 
; -------------------------------------------------------------------------------------------------------------- ;
LoadPic:            lda #YELLOW                     ; 
                    sta EXTCOL                      ; VIC($D020) Border Color
                    sta BGCOL0                      ; VIC($D021) Background Color 0
                    lda #$16                        ; ...x.xx. - 01=screen($0400-$07e7) 03=char($1800-$1fff)
                    sta VMCSB                       ; VIC($D018) VIC Chip Memory Control
                    
                    lda #$02                        ; 
                    ldx #$08                        ; 
                    ldy #$00                        ; 
                    jsr EFS_setlfs
                    
                    lda #Blank - PicATitle          ; length file name
                    ldx #<PicATitle                 ; 
                    ldy #>PicATitle                 ; 
                    jsr EFS_setnam
                    
                    lda #$00                        ; flag: load
                    ldx #<PicStart                  ; 
                    ldy #>PicStart                  ; 
                    jsr EFS_load
                    
                    lda #<PicColorsMC               ; 
                    sta PtrFromLo                   ; 
                    lda #>PicColorsMC               ; 
                    sta PtrFromHi                   ; 
                    
                    lda #<ScreenMC                  ; 
                    sta PtrToLo                     ; 
                    lda #>ScreenMC                  ; 
                    sta PtrToHi                     ; 
                    
                    ldy #$00                        ; 
CopyPicColorsMC:    lda (PtrFrom),y                 ; 
                    sta (PtrTo),y                   ; 
                    iny                             ; 
                    bne CopyPicColorsMC             ; 
                    
                    inc PtrFromHi                   ; 
                    inc PtrToHi                     ; 
                    lda PtrToHi                     ; 
                    cmp #<(>ScreenMC + $04)         ; $04 pages
                    bne CopyPicColorsMC             ; 
                    
                    lda #<PicBitMap                 ; 
                    sta PtrFromLo                   ; 
                    lda #>PicBitMap                 ; 
                    sta PtrFromHi                   ; 
                    
                    lda #<ScreenBitMap              ; 
                    sta PtrToLo                     ; 
                    lda #>ScreenBitMap              ; 
                    sta PtrToHi                     ; 
                    
                    ldy #$00                        ; 
CopyPicBitMap:      lda (PtrFrom),y                 ; 
                    sta (PtrTo),y                   ; 
                    iny                             ; 
                    bne CopyPicBitMap               ; 
                    
                    inc PtrFromHi                   ; 
                    inc PtrToHi                     ; 
                    lda PtrToHi                     ; 
                    cmp #<(>ScreenBitMap + $20)     ; $20 pages
                    bne CopyPicBitMap               ; 
                    
                    lda #<PicColorsRam              ; 
                    sta PtrFromLo                   ; 
                    lda #>PicColorsRam              ; 
                    sta PtrFromHi                   ; 
                    
                    lda #<COLORAM                   ; 
                    sta PtrToLo                     ; 
                    lda #>COLORAM                   ; 
                    sta PtrToHi                     ; 
                    
                    ldy #$00                        ; 
CopyPicColorsRam:   lda (PtrFrom),y                 ; 
                    sta (PtrTo),y                   ; 
                    iny                             ; 
                    bne CopyPicColorsRam            ; 
                    inc PtrFromHi                   ; 
                    inc PtrToHi                     ; 
                    lda PtrToHi                     ; 
                    cmp #$dc                        ; 
                    bne CopyPicColorsRam            ; 
                    
ShowPic:            lda C2DDRA                      ; CIA2($DD02) Data Dir A
                    ora #$03                        ; ......xx - 1=output
                    sta C2DDRA                      ; CIA2($DD02) Data Dir A
                    
                    lda CI2PRA                      ; CIA2($DD00) Data Port A - Bits 0-1 = VIC mem bank
                    and #VIC_MemBankClr             ; xxxxxx.. 00 = VIC_MemBank_3 - $c000-$ffff
                    sta CI2PRA                      ; CIA2($DD00) Data Port A - Bits 0-1 = VIC mem bank
                    
                    lda #$3b                        ; ..xxx.xx - 25rows / screen enab / bitmap mode
                    sta SCROLY                      ; VIC($D011) VIC Control Register 1 (and Vertical Fine Scrolling)
                    
                    lda #$18                        ; ...xx... - 40 cols / multi color mode
                    sta SCROLX                      ; VIC($D016) VIC Control Register 2 (and Horizontal Fine Scrolling)
                    
                    lda #$38                        ; ..xx x.. . - color $0c00-$0fe7  screen $2000-$3fff
                    sta VMCSB                       ; VIC($D018) VIC Chip Memory Control
                    
                    lda #YELLOW                     ; 
                    sta EXTCOL                      ; VIC($D020) Border Color
                    lda #WHITE                      ; 
                    sta BGCOL0                      ; VIC($D021) Background Color 0
                    
                    lda #$02                        ; 
                    ldx #$08                        ; 
                    ldy #$00                        ; 
                    jsr EFS_setlfs
                    
                    lda #TabScreenRows - Object     ; length file name
                    ldx #<Object                    ; 
                    ldy #>Object                    ; 
                    jsr EFS_setnam
                    
                    lda #$00                        ; flag: load
                    ldx #<MainStart                 ; 
                    ldy #>MainStart                 ; 
                    jsr EFS_load

                    jsr WrapperStart
                    
StartGame:          jmp MainStart                   ; 
; -------------------------------------------------------------------------------------------------------------- ;
                    .byte $81 ; 
; -------------------------------------------------------------------------------------------------------------- ;
PicATitle:          .byte $33 ; 3
                    .byte $54 ; t
                    .byte $49 ; i
                    .byte $54 ; t
                    .byte $4c ; l
                    .byte $45 ; e
                    .byte $50 ; p
                    .byte $49 ; i
                    .byte $43 ; c
PicATitleLength = * - PicATitle

Blank:              .byte $20
                    .byte $20
                    .byte $20
                    
Object:             .byte $33 ; 3
                    .byte $4f ; o
                    .byte $42 ; b
                    .byte $4a ; j
                    .byte $45 ; e
                    .byte $43 ; c
                    .byte $54 ; t
ObjectLenth = * - Object

; -------------------------------------------------------------------------------------------------------------- ;
TabScreenRows:      .word $0400 ; row 01
                    .word $0428 ; row 02
                    .word $0450 ; row 03
                    .word $0478 ; row 04
                    .word $04a0 ; row 05
                    .word $04c8 ; row 06
                    .word $04f0 ; row 07
                    .word $0518 ; row 08
                    .word $0540 ; row 09
                    .word $0568 ; row 10
                    .word $0590 ; row 11
                    .word $05b8 ; row 12
                    .word $05e0 ; row 13
                    .word $0608 ; row 14
                    .word $0630 ; row 15
                    .word $0658 ; row 16
                    .word $0680 ; row 17
                    .word $06a8 ; row 18
                    .word $06d0 ; row 19
                    .word $06f8 ; row 20
                    .word $0720 ; row 21
                    .word $0748 ; row 22
                    .word $0770 ; row 23
                    .word $0798 ; row 24
                    .word $07c0 ; row 25
; -------------------------------------------------------------------------------------------------------------- ;
InfoTextRows = *
; -------------------------------------------------------------------------------------------------------------- ;
ScrnCol01:          .byte $06 ; 
ScrnRow01:          .byte $01 ; 
TextRow01:          .byte $42 ; b
                    .byte $52 ; r
                    .byte $30 ; 0
                    .byte $44 ; d
                    .byte $45 ; e
                    .byte $52 ; r
                    .byte $42 ; b
                    .byte $55 ; u
                    .byte $4e ; n
                    .byte $44 ; d
                    .byte $20 ; _
                    .byte $53 ; s
                    .byte $4f ; o
                    .byte $46 ; f
                    .byte $54 ; t
                    .byte $57 ; w
                    .byte $41 ; a
                    .byte $52 ; r
                    .byte $45 ; e
                    .byte $20 ; _
                    .byte $50 ; p
                    .byte $52 ; r
                    .byte $45 ; e
                    .byte $53 ; s
                    .byte $45 ; e
                    .byte $4e ; n
                    .byte $54 ; t
EoTxRow01:          .byte $d3 ; S
; -------------------------------------------------------------------------------------------------------------- ;
ScrnCol02:          .byte $06 ; 
ScrnRow02:          .byte $0a ; 
TextRow02:          .byte $22 ; "
                    .byte $54 ; t
                    .byte $48 ; h
                    .byte $45 ; e
                    .byte $20 ; _
                    .byte $43 ; c
                    .byte $41 ; a
                    .byte $53 ; s
                    .byte $54 ; t
                    .byte $4c ; l
                    .byte $45 ; e
                    .byte $53 ; s
                    .byte $20 ; _
                    .byte $4f ; o
                    .byte $46 ; f
                    .byte $20 ; _
                    .byte $44 ; d
                    .byte $4f ; o
                    .byte $43 ; c
                    .byte $54 ; t
                    .byte $4f ; o
                    .byte $52 ; r
                    .byte $20 ; _
                    .byte $43 ; c
                    .byte $52 ; r
                    .byte $45 ; e
                    .byte $45 ; e
                    .byte $50 ; p
EoTxRow02:          .byte $a2 ; <shift> "
; -------------------------------------------------------------------------------------------------------------- ;
ScrnCol03:          .byte $0f ; 
ScrnRow03:          .byte $0d ; <enter>
TextRow03:          .byte $42 ; b
                    .byte $59 ; y
                    .byte $20 ; _
                    .byte $45 ; e
                    .byte $44 ; d
                    .byte $20 ; _
                    .byte $48 ; h
                    .byte $4f ; o
                    .byte $42 ; b
                    .byte $42 ; b
EoTxRow03:          .byte $d3 ; S
; -------------------------------------------------------------------------------------------------------------- ;
ScrnCol04:          .byte $02 ; 
ScrnRow04:          .byte $17 ; 
TextRow04:          .byte $50 ; p
                    .byte $4c ; l
                    .byte $45 ; e
                    .byte $41 ; a
                    .byte $53 ; s
                    .byte $45 ; e
                    .byte $20 ; _
                    .byte $41 ; a
                    .byte $4c ; l
                    .byte $4c ; l
                    .byte $4f ; o
                    .byte $57 ; w
                    .byte $20 ; _
                    .byte $54 ; t
                    .byte $57 ; w
                    .byte $4f ; o
                    .byte $20 ; _
                    .byte $4d ; m
                    .byte $49 ; i
                    .byte $4e ; n
                    .byte $55 ; u
                    .byte $54 ; t
                    .byte $45 ; e
                    .byte $53 ; s
                    .byte $20 ; _
                    .byte $46 ; f
                    .byte $4f ; o
                    .byte $52 ; r
                    .byte $20 ; _
                    .byte $4c ; l
                    .byte $4f ; o
                    .byte $41 ; a
                    .byte $44 ; d
                    .byte $49 ; i
                    .byte $4e ; n
EoTxRow04:          .byte $c7 ; G
; -------------------------------------------------------------------------------------------------------------- ;
ScrnCol05:          .byte $05 ; 
ScrnRow05:          .byte $0f ; 
TextRow05:          .byte $42 ; b
                    .byte $52 ; r
                    .byte $4f ; o
                    .byte $4b ; k
                    .byte $45 ; e
                    .byte $4e ; n
                    .byte $20 ; _
                    .byte $42 ; b
                    .byte $59 ; y
                    .byte $20 ; _
                    .byte $42 ; b
                    .byte $4c ; l
                    .byte $41 ; a
                    .byte $44 ; d
                    .byte $45 ; e
                    .byte $20 ; _
                    .byte $52 ; r
                    .byte $55 ; u
                    .byte $4e ; n
                    .byte $4e ; n
                    .byte $45 ; e
                    .byte $52 ; r
                    .byte $20 ; _
                    .byte $37 ; 7
                    .byte $2f ; /
                    .byte $38 ; 8
                    .byte $34 ; 4
EoTxRow05:          .byte $a0 ; <_ (shift)>
; -------------------------------------------------------------------------------------------------------------- ;
EoInfoTextRows:     .byte $80 ; 
; -------------------------------------------------------------------------------------------------------------- ;
                    .byte $00 ; 
                    .byte $00 ; 
                    .byte $00 ; 
; -------------------------------------------------------------------------------------------------------------- ;
