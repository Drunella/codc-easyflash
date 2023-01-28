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


.import __GAMESTART_LOAD__
.import __GAMESTART_RUN__
.import __GAMESTART_SIZE__

.import __IO_WRAPPER_LOAD__
.import __IO_WRAPPER_RUN__
.import __IO_WRAPPER_SIZE__

.import __IO_BANKING_LOAD__
.import __IO_BANKING_RUN__
.import __IO_BANKING_SIZE__

.import body_startup_remastered
.import body_startup_original

.export _init_loader
.export _startup_game_remastered
.export _startup_game_original
.export WrapperStart


.segment "CODE"

    _init_loader:
        ; void __fastcall__ init_loader(void);

        ; load segment GAMESTART
        lda #<__GAMESTART_LOAD__
        sta source_address_low
        lda #>__GAMESTART_LOAD__
        sta source_address_high
        lda #<__GAMESTART_RUN__
        sta destination_address_low
        lda #>__GAMESTART_RUN__
        sta destination_address_high
        lda #<__GAMESTART_SIZE__
        sta bytes_to_copy_low
        lda #>__GAMESTART_SIZE__
        sta bytes_to_copy_high
        jsr copy_segment

        jsr wrapper_prepare

        rts


    bytes_to_copy_low:
         .byte $ff
    bytes_to_copy_high:
         .byte $ff

    copy_segment:
        lda bytes_to_copy_low
        beq copy_segment_loop
        inc bytes_to_copy_high
    copy_segment_loop:
    source_address_low = source_address + 1
    source_address_high = source_address + 2
    source_address:
        lda $ffff
    destination_address_low = destination_address + 1
    destination_address_high = destination_address + 2
    destination_address:
        sta $ffff
        ; increase source
        inc source_address_low
        bne :+
        inc source_address_high
    :   ; increase destination
        inc destination_address_low
        bne :+
        inc destination_address_high
    :   ; decrease size
        dec bytes_to_copy_low
        bne copy_segment_loop
        dec bytes_to_copy_high
        bne copy_segment_loop
        rts



.segment "GAMESTART"


    _startup_game_original:
        ; void __fastcall__ startup_game_original(void);
        jsr restore_minieapi
        jmp body_startup_original


    _startup_game_remastered:
        ; void __fastcall__ startup_game_remastered(void);
        jsr restore_minieapi
        jmp body_startup_remastered


    restore_minieapi:
        lda #$37
        sta $01
        lda #$80 | $07  ; led, 16k mode
        sta $de02
        lda #$00        ; EFSLIB_ROM_BANK
        sta $de00
        jsr EFS_init

        jsr EFS_init_minieapi

        lda #$36
        sta $01
        lda #$04   ; easyflash off
        sta $de02

        rts
        

; ------------------------------------------------------------------------
; startup remastered game


    wrapper_prepare:
        ldy #$00
      @loop1:
        lda __IO_WRAPPER_LOAD__, y
        sta storage_wrapper_io, y
        iny
        cpy #<__IO_WRAPPER_SIZE__
        bne @loop1
        
        ldy #$00
      @loop2:
        lda __IO_BANKING_LOAD__, y
        sta storage_banking_io, y
        iny
        cpy #<__IO_BANKING_SIZE__
        bne @loop2

        rts


    WrapperStart:
        ldy #$00
      @loop1:
        lda storage_wrapper_io, y
        sta __IO_WRAPPER_RUN__, y
        iny
        cpy #<__IO_WRAPPER_SIZE__
        bne @loop1
        
        ldy #$00
      @loop2:
        lda storage_banking_io, y
        sta __IO_BANKING_RUN__, y
        iny
        cpy #<__IO_BANKING_SIZE__
        bne @loop2

        rts


    storage_wrapper_io = __GAMESTART_RUN__ + __GAMESTART_SIZE__

    storage_banking_io = storage_wrapper_io + __IO_WRAPPER_SIZE__




/*    body_startup_original:
        ; void __fastcall__ startup_game(void);
        lda #$7f   ; disable interrupts
        sta $dc0d
        sta $dd0d
        lda $dc0d
        sta $dd0d
        cli

        lda #$37   ; memory configuration
        sta $01
        lda #$2f
        sta $00

        ; load pic to $0800
        ldy #$00
        jsr EFS_setlfs

        lda #titlepicture_name_length
        ldx #<titlepicture_name
        ldy #>titlepicture_name
        jsr EFS_setnam

        lda #$00
        ldx #$00
        ldy #$08
        jsr EFS_load

        ; show pic
        lda #$40   
        sta $14    
        lda #$27   
        sta $15    
        lda #$00   
        sta $16    
        lda #$cc   
        sta $17    

        ldy #$00
    :   lda ($14), y
        sta ($16), y
        iny           
        bne :-
        inc $15       
        inc $17       
        lda $17       
        cmp #$d0      
        bne :-
        lda #$00      
        sta $14       
        lda #$08      
        sta $15       
        lda #$00      
        sta $16       
        lda #$e0      
        sta $17       

        ldy #$00      
    :   lda ($14), y 
        sta ($16), y 
        iny            
        bne :-
        inc $15        
        inc $17        
        lda $17        
        cmp #$00       
        bne :-
        lda #$28       
        sta $14        
        lda #$2b       
        sta $15        
        lda #$00       
        sta $16        
        lda #$d8       
        sta $17        
        
        ldy #$00                       
    :   lda ($14), y  
        sta ($16), y  
        iny             
        bne :-
        inc $15         
        inc $17         
        lda $17         
        cmp #$dc        
        bne :-

        lda $dd02  ; show pic
        ora #$03  
        sta $dd02 
        lda $dd00 
        and #$fc  
        sta $dd00 
        lda #$3b  
        sta $d011 
        lda #$18  
        sta $d016 
        lda #$38  
        sta $d018 
        lda #$07  
        sta $d020 
        lda #$01  
        sta $d021 

        ; load objects
        ldy #$00
        jsr EFS_setlfs

        lda #object_name_length
        ldx #<object_name
        ldy #>object_name
        jsr EFS_setnam

        lda #$00
        ldx #$00
        ldy #$08
        jsr EFS_load

        ; start game
        jmp $0800


    titlepicture_name:
        .byte "titlepic"
    titlepicture_name_end:
    titlepicture_name_length = titlepicture_name_end - titlepicture_name

    object_name:
        .byte "object"
    object_name_end:
    object_name_length = object_name_end - object_name
*/


/*
    PtrFrom             = $14                           ; 
    PtrFromLo           = $14                           ; 
    PtrFromHi           = $15                           ; 
    PtrTo               = $16                           ; 
    PtrToLo             = $16                           ; 
    PtrToHi             = $17                           ; 
    PicStart            = $0800                         ; start address load picture
    MainStart           = $0800                         ; start address game code
    ScreenText          = $0400                         ; game info text
    ScreenMC            = $cc00                         ; target title picture screen color info
    ScreenBitMap        = $e000                         ; target title picture bitmap info
    PicBitMap           = PicStart                      ; $0000 - $1f3f - koala picture bitmap
    PicColorsMC         = PicStart      + $1f40         ; $1f40 - $2327 - koala picture color video ram
    PicColorsRam        = PicColorsMC   + $03e8         ; $2328 - $270f - koala picture color ram 
    PicColorsBkgr       = PicColorsRam  + $03e8    
    COLORAM             = $d800

    body_startup_remastered:
;        ldx #$00
;        lda #$20
;      @loop:   
;        sta $0400,x
;        sta $0500,x
;        sta $0600,x
;        sta $0700,x
;        dex
;        bne @loop

        lda #$07
        sta $d020
        sta $d021
        lda #$16                       
        sta $d018                      
                                       
        ldy #$00
        jsr EFS_setlfs
                                       
        lda #title3picture_name_length
        ldx #<title3picture_name
        ldy #>title3picture_name       
        jsr EFS_setnam
                                       
        lda #$00
        ldx #<PicStart                 
        ldy #>PicStart                 
        jsr EFS_load
                                       
        lda #<PicColorsMC              
        sta PtrFromLo                  
        lda #>PicColorsMC              
        sta PtrFromHi                  
                                       
        lda #<ScreenMC                 
        sta PtrToLo                    
        lda #>ScreenMC                 
        sta PtrToHi                    
                                       
        ldy #$00                       
    CopyPicColorsMC:
        lda (PtrFrom),y                
        sta (PtrTo),y                  
        iny                            
        bne CopyPicColorsMC            
                                       
        inc PtrFromHi                  
        inc PtrToHi                    
        lda PtrToHi                    
        cmp #<(>ScreenMC + $04)        
        bne CopyPicColorsMC            
                                       
        lda #<PicBitMap                
        sta PtrFromLo                  
        lda #>PicBitMap                
        sta PtrFromHi                  
                                       
        lda #<ScreenBitMap             
        sta PtrToLo                    
        lda #>ScreenBitMap             
        sta PtrToHi                    
                                       
        ldy #$00                       
    CopyPicBitMap:
        lda (PtrFrom),y                
        sta (PtrTo),y                  
        iny                            
        bne CopyPicBitMap              
                                       
        inc PtrFromHi                  
        inc PtrToHi                    
        lda PtrToHi                    
        cmp #<(>ScreenBitMap + $20)    
        bne CopyPicBitMap              
                                       
        lda #<PicColorsRam             
        sta PtrFromLo                  
        lda #>PicColorsRam             
        sta PtrFromHi                  
                                       
        lda #<COLORAM                  
        sta PtrToLo                    
        lda #>COLORAM                  
        sta PtrToHi                    
                                       
        ldy #$00                       
    CopyPicColorsRam:
        lda (PtrFrom),y                
        sta (PtrTo),y                  
        iny                            
        bne CopyPicColorsRam           
        inc PtrFromHi                  
        inc PtrToHi                    
        lda PtrToHi                    
        cmp #$dc                       
        bne CopyPicColorsRam           
              
    ShowPic:                         
        lda $DD02
        ora #$03                       
        sta $DD02
                                       
        lda $DD00
        and #$fc  ; #VIC_MemBankClr            
        sta $DD00
                                       
        lda #$3b                       
        sta $D011
                                       
        lda #$18                       
        sta $D016
                                       
        lda #$38                       
        sta $D018
                                       
        lda #$07
        sta $D020
        lda #$01
        sta $D021
                                       
        ldy #$00                       
        jsr EFS_setlfs
                                       
        lda #x3object_name_length
        ldx #<x3object_name       
        ldy #>x3object_name            
        jsr EFS_setnam
                                       
        lda #$00                       
        ldx #<MainStart                
        ldy #>MainStart                
        jsr EFS_load
                                       
        jmp MainStart


    title3picture_name:
        .byte "3titlepic"
    title3picture_name_end:
    title3picture_name_length = title3picture_name_end - title3picture_name

    x3object_name:
        .byte "3object"
    x3object_name_end:
    x3object_name_length = x3object_name_end - x3object_name
*/