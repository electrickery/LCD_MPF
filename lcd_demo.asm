; lcdDemo

; monitor routines
SCAN:   EQU     005FEh
SCAN1:  EQU     00624h  ; carry =0; key detect. A is key position

; register storage 
USERAF: EQU     01FBCh
USERBC: EQU     01FBEh
USERDE: EQU     01FC0h
USERHL: EQU     01FC2h
UAFP:   EQU     01FC4h
UBCP:   EQU     01FC6h
UDEP:   EQU     01FC8h
UHLP:   EQU     01FCAh
USERIX: EQU     01FCCh
USERIY: EQU     01FCEh
USERSP: EQU     01FD0h
USERIF: EQU     01FD2h
FLAGH:  EQU     01FD4h
FLAGL:  EQU     01FD6h
FLAGHP: EQU     01FD8h
FLAGLP: EQU     01FDAh
USERPC: EQU     01FDCh

    org     2100h
    
   
demo:
;    ld      sp, 01900h
    call    init
    
    ld      b, 0
    ld      c, 0
    call    lcdCurs
    ld      hl, regDmp1
    call    lcdSendAsc
    
    ld      b, 1
    ld      c, 0
    call    lcdCurs
    ld      hl, (USERAF)
    ld      a, h
    call    prtByte
    ld      a, l
    call    prtByte
      
    ld      a, ' '
    call    lcdSendData
    
    ld      hl, (USERBC)
    ld      a, h
    call    prtByte
    ld      a, l
    call    prtByte
    
    ld      a, ' '
    call    lcdSendData

    ld      hl, (USERDE)
    ld      a, h
    call    prtByte
    ld      a, l
    call    prtByte
   
    ld      a, ' '
    call    lcdSendData

    ld      hl, (USERHL)
    ld      a, h
    call    prtByte
    ld      a, l
    call    prtByte

    ld      b, 2
    ld      c, 0
    call    lcdCurs
    ld      hl, regDmp2
    call    lcdSendAsc
    
    ld      b, 3
    ld      c, 0
    call    lcdCurs
    ld      hl, (UAFP)
    ld      a, h
    call    prtByte
    ld      a, l
    call    prtByte
    
    ld      a, ' '
    call    lcdSendData

    ld      hl, (UBCP)
    ld      a, h
    call    prtByte
    ld      a, l
    call    prtByte
    
    ld      a, ' '
    call    lcdSendData

    ld      hl, (UDEP)
    ld      a, h
    call    prtByte
    ld      a, l
    call    prtByte
    
    ld      a, ' '
    call    lcdSendData

    ld      hl, (UHLP)
    ld      a, h
    call    prtByte
    ld      a, l
    call    prtByte
    
dmlp:
    call    SCAN1
    jr      c, dmlp
    cp      10h         ; + key
    jr      z, dmplus
    cp      11h         ; - key
    jr      z, dmmin
    jr      dmlp
    
dmplus:
    ld      a, (lcdRow)
    ld      b, a
    ld      a, (lcdCol)
    inc     a
    ld      c, a
    call    lcdCurs
    jr      dmlp
dmmin:
    ld      a, (lcdRow)
    ld      b, a
    ld      a, (lcdCol)
    dec     a
    ld      c, a
    call    lcdCurs
    jr      dmlp
    
; 
prtByte:    
    push    af
    rrc     a
    rrc     a
    rrc     a
    rrc     a
    call    nib2asc
    call    lcdSendData
    pop     af
    call    nib2asc
    call    lcdSendData
    
    ret
    
row1:
    ld      b, 0
    ld      c, 0
    call    lcdCurs
    halt
row2:
    ld      b, 1
    ld      c, 0
    call    lcdCurs
    halt
row3:
    ld      b, 2
    ld      c, 0
    call    lcdCurs
    halt
row4:
    ld      b, 3
    ld      c, 0
    call    lcdCurs
    halt

plus: equ   21h
minus:equ   1Fh
row4m:
    call    init
rloop:
    call    scan1
    jr      c, rloop
    cp      21h ; + key
    jr      z, rplus
    cp      1Fh ; - key
    jr      z, rminus
    
    jr      rloop
    
rplus:
    ld      a, (lcdRow)
    inc     a
    ld      (lcdRow), a
    ld      b, a
    ld      a, (lcdCol)
    ld      c, a
    call    lcdCurs
    jr      rloop
    
rminus:
    ld      a, (lcdRow)
    dec     a
    ld      (lcdRow), a
    ld      b, a
    ld      a, (lcdCol)
    ld      c, a
    call    lcdCurs
    jr      rloop

hello_world:
    DEFB    ' Hello, world!', 0
    
mpf1:
    DEFB    '   from MPF-I', 0
    
regDmp1:  ;  01234567890123456789
    DEFB    ' AF   BC   DE   HL  ', 0
      
    
regDmp2:  ;  01234567890123456789
;           "A'F' B'C' D'E' H'L' "
    DEFB    ' AF', 027h, '  BC', 027h, '  DE', 027h, '  HL', 027h, 0
    
regdmp3:  ;  01234567890123456789
    DEFB    'I X  I Y  I F  S P  ', 0    
    
regdmp4:  ;  01234567890123456789
    DEFB    'PC   ', 0

    include lcdlibmpf1.asm
    
    
