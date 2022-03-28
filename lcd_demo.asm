; lcdDemo

; monitor routines
SCAN:   EQU     005FEh
SCAN1:  EQU     00624h  ; carry =0; key detect. A is key position

; keys
PLUSK:  EQU     021h
MINK:   EQU     01Fh

; register storage 
USERAF: EQU     01FBCh ; AF
USERBC: EQU     01FBEh ; BC
USERDE: EQU     01FC0h ; DE
USERHL: EQU     01FC2h ; HL
UAFP:   EQU     01FC4h ; AF'
UBCP:   EQU     01FC6h ; BC'
UDEP:   EQU     01FC8h ; ED'
UHLP:   EQU     01FCAh ; HL'
USERIX: EQU     01FCCh ; IX
USERIY: EQU     01FCEh ; IY
USERSP: EQU     01FD0h ; SP
USERIF: EQU     01FD2h ; I and IFF2
FLAGH:  EQU     01FD4h ; flags (F)  high: S Z . H
FLAGL:  EQU     01FD6h ; flags (F)  low:  . P N C 
FLAGHP: EQU     01FD8h ; flags (F') high: S Z . H
FLAGLP: EQU     01FDAh ; flags (F') low:  . P N C 
USERPC: EQU     01FDCh

    org     2100h
   
start:
    ld      sp, 01980h
    call    init
    call    regPg1
    call    regPg1p
    jp      dmlp
    
regPg1: 
    ld      a, lcd_cls
    call    lcdSendCmd
   
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
    
    ret

regPg1p:
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
    ret
    
regPg2:
    ld      a, lcd_cls
    call    lcdSendCmd
   
    ld      b, 0
    ld      c, 0
    call    lcdCurs
    ld      hl, regIXY
    call    lcdSendAsc
    
    ld      b, 1
    ld      c, 0
    call    lcdCurs
    ld      hl, (USERIX)
    ld      a, h
    call    prtByte ; 0-1
    ld      a, l
    call    prtByte ; 2-3
      
    ld      b, 1
    ld      c, 5
    call    lcdCurs
    ld      hl, (USERIY)
    ld      a, h
    call    prtByte ; 5-6
    ld      a, l
    call    prtByte ; 7-8
    
    ld      b, 0
    ld      c, 10
    call    lcdCurs
    ld      hl, regIFSP
    call    lcdSendAsc
    
    ld      b, 1
    ld      c, 10
    call    lcdCurs
    ld      hl, (USERIF)
    ld      a, h
    call    prtByte ; 10-11
    ld      a, l
    call    prtByte ; 12-13
    
    ld      b, 1
    ld      c, 15
    call    lcdCurs
    ld      hl, (USERSP)
    ld      a, h
    call    prtByte ; 15-16
    ld      a, l
    call    prtByte ; 17-18
    
    ret

regFl:    
    ld      b, 2
    ld      c, 0
    call    lcdCurs
    ld      hl, regDmp4
    call    lcdSendAsc
    
    ld      b, 3
    ld      c, 0
    call    lcdCurs
    ld      a, (USERAF)
    call    bits2lcd
    
    ret
    
regFlp:    
    ld      b, 2
    ld      c, 10
    call    lcdCurs
    ld      hl, regDmp4p
    call    lcdSendAsc
    
    ld      b, 3
    ld      c, 10
    call    lcdCurs
    ld      a, (UAFP)
    call    bits2lcd
   
    ret
    
getBit7:
    bit     7, a
    jr      z, gbx0
    jr      gbx1
    
getBit6:
    bit     6, a
    jr      z, gbx0
    jr      gbx1
    
getBit5:
    bit     5, a
    jr      z, gbx0
    jr      gbx1
    
getBit4:
    bit     4, a
    jr      z, gbx0
    jr      gbx1
    
gbx1:
    ld      a, '1'
    ret
gbx0:
    ld      a, '0'
    ret
    
dmlp:
    ld      ix, lcdBan3
    call    SCAN1
    jr      c, dmlp
    cp      PLUSK         ; + key
    jr      z, dmplus
    cp      MINK         ; - key
    jr      z, dmmin
    jr      dmlp
    
dmplus:
    call    regPg2
    call    regFl
    call    regFlp
    jr      dmlp
dmmin:
    call    regPg1
    call    regPg1p
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
    
bits2lcd:
    push    bc
    push    de
    ld      e, 8
    ld      c, a
nextbit:
    rlc     c
    jr      c, one
    call    send0
    jr      tonext
one:
    call    send1
tonext:
    dec     e
    jr      nz, nextbit
    pop     de
    pop     bc
    ret
    
send1:
    ld      a, '1'
    call    lcdSendData
    ret
    
send0:
    ld      a, '0'
    call    lcdSendData
    ret

hello_world:
    DEFB    ' Hello, world!', 0
    
mpf1:
    DEFB    '   from MPF-I', 0
    
lcdBan: ;    F     P     m     d     C     L   ; reverse banner; R-to-L
    DEFB    00Fh, 01Fh, 02Bh, 0B3h, 08Dh, 085h

lcdBan2: ;    F     P     u     d     C     L   ; reverse banner; R-to-L
    DEFB    00Fh, 01Fh, 036h, 0B3h, 08Dh, 085h
    
lcdBan3: ;    F     P     u     d     C     L   ; reverse banner; R-to-L
    DEFB    00Fh, 01Fh, 0A1h, 0B3h, 08Dh, 085h
    
regDmp1:  ;  01234567890123456789
    DEFB    ' AF   BC   DE   HL  ', 0
      
    
regDmp2:  ;  01234567890123456789
;           "A'F' B'C' D'E' H'L' "
    DEFB    ' AF', 027h, '  BC', 027h, '  DE', 027h, '  HL', 027h, 0
    
regIXY:  ;  01234567890123456789
    DEFB    'IX   IY', 0  
      
regIFSP:  ;  01234567890123456789
    DEFB    'IF   SP  ', 0    
    
regDmp4:  ;  01234567890123456789
    DEFB    'SZ.H.PNC', 0

regDmp4p:  ;  01234567890123456789
    DEFB    'SZ.H.PNC', 027h, 0
    
memDmp1:    ;   01234567890123456789
            ;   xxxx xxxx xxxx xxxx   (start address in 7-seg display)

memDmp2:    ;   01234567890123456789
            ;    aa  aa  aa  aa       (start address in 7-seg display)
    include lcdlibmpf1.asm
    
    
