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


EAPI_SOURCE  = $b800  ; $a000 (hirom) + 1800
EAPI_DESTINATION = $7500

; io functions
EF_SETNAM = $0200
EF_LOAD = $0203
EF_SAVE = $0206
_

; eapi functions
EASYFLASH_BANK    = $de00
EASYFLASH_CONTROL = $de02
EASYFLASH_LED     = $80
EASYFLASH_16K     = $07
EASYFLASH_KILL    = $04

EAPIInit          = EAPI_DESTINATION + $14
EAPIWriteFlash    = $df80
EAPIEraseSector   = $df83
EAPISetBank       = $df86
EAPIGetBank       = $df89
EAPISetPtr        = $df8c
EAPISetLen        = $df8f
EAPIReadFlashInc  = $df92
EAPIWriteFlashInc = $df95
EAPISetSlot       = $df98
EAPIGetSlot       = $df9b

