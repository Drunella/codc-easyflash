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


.import __LOADER_LOAD__
.import __LOADER_RUN__
.import __LOADER_SIZE__

.import __IO_WRAPPER_LOAD__
.import __IO_WRAPPER_RUN__
.import __IO_WRAPPER_SIZE__


.import _load_eapi
.import wrapper_setnam
.import wrapper_load

.export _init_loader
.export _startup_game


.segment "CODE"

    _init_loader:
        ; void __fastcall__ init_loader(void);

        ; load segment LOADER
        lda #<__LOADER_LOAD__
        sta source_address_low
        lda #>__LOADER_LOAD__
        sta source_address_high
        lda #<__LOADER_RUN__
        sta destination_address_low
        lda #>__LOADER_RUN__
        sta destination_address_high
        lda #<__LOADER_SIZE__
        sta bytes_to_copy_low
        lda #>__LOADER_SIZE__
        sta bytes_to_copy_high
        jsr copy_segment

        ; load eapi
        lda #>EAPI_DESTINATION
        jsr _load_eapi

        ; load wrapper (IO_WRAPPER)
        lda #<__IO_WRAPPER_LOAD__
        sta source_address_low
        lda #>__IO_WRAPPER_LOAD__
        sta source_address_high
        lda #<__IO_WRAPPER_RUN__
        sta destination_address_low
        lda #>__IO_WRAPPER_RUN__
        sta destination_address_high
        lda #<__IO_WRAPPER_SIZE__
        sta bytes_to_copy_low
        lda #>__IO_WRAPPER_SIZE__
        sta bytes_to_copy_high
        jsr copy_segment

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



.segment "LOADER"

    titlepicture_name:
        .byte "titlepic"
    titlepicture_name_end:
    titlepicture_name_length = titlepicture_name_end - titlepicture_name

    gameobject_name:
        .byte "objects"
    gameobject_name_end:
    gameobject_name_length = gameobject_name_end - gameobject_name

    sounds_name:
        .byte "sounds"
    sounds_name_end:
    sounds_name_length = sounds_name_end - sounds_name


    _startup_game:
        ; void __fastcall__ startup_game(void);
        lda #$7f   ; disable interrupts
        sta $dc0d
        sta $dd0d
        lda $dc0d
        sta $dd0d

        lda #$35   ; memory configuration
        sta $01
        lda #$2f
        sta $00

        ; load pic to $0800
        lda #titlepicture_name_length
        ldx #<titlepicture_name
        ldy #>titlepicture_name
        jsr wrapper_setnam
        lda #$00
        ldx #$00
        ldy #$08
        jsr wrapper_load

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
        lda #gameobject_name_length
        ldx #<gameobject_name
        ldy #>gameobject_name
        jsr wrapper_setnam
        lda #$00
        ldx #$00
        ldy #$08
        jsr wrapper_load

        ; load sound
        lda #sounds_name_length
        ldx #<sounds_name
        ldy #>sounds_name
        jsr wrapper_setnam
        lda #$00
        ldx #$00
        ldy #$b9
        jsr wrapper_load

        ; start game
        jmp $0800
