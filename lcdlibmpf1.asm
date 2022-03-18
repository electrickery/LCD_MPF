;********************
; Some simple test code to write commands and data to a 
; character LCD display (tested with a 2x16 display)
; Based on https://bread80.com/2020/07/01/connecting-an-lcd-to-a-z80-with-two-glue-chips/
;          https://github.com/Bread80/z80-character-lcd
;
; Tested with the z80asm assembler
; fjkraan@electrickery.nl, 2021-09-23
;********************

; Ports used
lcdCtrl     equ     0C8h    ;Port addresses. Change as needed.
lcdData     equ     lcdCtrl + 1

; Memory used
lcdRow:     equ     01900h
lcdCol:     equ     01901h
lcdMem:     equ     01902h

; configuration/commands
lcd_cls     equ     01h        ; Clear display                                            00000001b
lcd_home    equ     02h     ; Return home                                                 00000010b
lcd_entMd   equ     04h     ; Entry mode set (cursor move direction and display shift)    000001xxb
lcd_entSh   equ     01h     ;   Entry mode display shift bit
lcd_entCd   equ     02h     ;   Entry mode display cursor move direction bit
lcd_donMod  equ     08h     ; Display on/off control (display, cursor, blink)             00001xxxb
lcd_donD    equ     04h     ;   Display on/off control display bit             00001100b
lcd_donC    equ     02h     ;   Display on/off control cursor bit              00001010b
lcd_donB    equ     01h     ;   Display on/off control cursor blink bit        00001001b
lcd_cdShft  equ     10h     ; Cursor or display shift direction                           0001xxxxb
lcd_cdC     equ     00h     ;   Cursor shift S/C select 00010xxxb
lcd_cdD     equ     08h     ;   Display shift S/C select 00011xxxb
lcd_cdR     equ     00h     ;   Cursor or display shift left                   0001x1xxb
lcd_cdL     equ     04h     ;   Cursor or display shift right                  0001x1xxb
lcd_func    equ     20h     ; Function set                                                 001xxxxxb
lcd_set8bit equ     3fh     ;  8-bit port, 2-line display   (0011****)
; cursor or display shift

lcd_setcgradd equ   40h     ; Set CGRAM address 01xxxxxxb (bit 0-5 contain address) - Character generator
lcd_setdramad equ   80h     ; Set DDRAM address 1xxxxxxxb (bit 0-6 contain address) - Display memory

lcd_2ndrow  equ     40      ; Default address 1st char, 2nd row 40 = 28h

; status
lcd_statM   equ     80h     ; Bit 7 contains busy flag
lcd_addr    equ     7Fh     ; Bit 0-6 contain data address counter or 0-5 character graphics ac

; display specific
lcd_lines   equ    4
lcd_llength equ    20

; DART debug routines
UART_INIT:  equ     2785h
UART_TX:    equ     27b0h
PRINTHBYTE: equ     2f20h
PRINT_NEW_LINE: equ 2e8dh
;    org     2000h
    
;Initialisation
init:
    ld      a, lcd_set8bit
    call    lcdSendCmd
    
    ld      a, lcd_donMod | lcd_donD | lcd_donC | lcd_donB
    call    lcdSendCmd
    
    ld      a, lcd_cdShft | lcd_cdC | lcd_cdR
    call    lcdSendCmd
    
    ld      a,lcd_cls
    call    lcdSendCmd
    
    ld      a, 0
    ld      (lcdRow), a
    ld      (lcdCol), a
    ld      (lcdMem), a
        
    ret
    
;******************
;Send a command byte to the LCD
;Entry: A= command byte
;Exit: All preserved
;******************
lcdSendCmd:
    push    bc                ; Preserve
    call    lcdWait
    
    ld      c, lcdCtrl        ; Command port
    out     (c), a            ; Send command
    pop     bc                ; Restore
    ld      (1903h), a
    ret
    
;******************
;Send a data byte to the LCD
;Entry: A= data byte
;Exit: All preserved
;******************
lcdSendData:
    push    bc                ; Preserve
    call    lcdWait
    
    ld      c, lcdData        ; Data port
    out     (c), a            ; Send data
    pop     bc                ; Restore
    ld      a, (lcdCol)
    inc     a
    ld      (lcdCol), a
    ret
    
;******************
;Gets a data byte to the LCD
;Entry: -
;Exit: Byte in A, all others preserved
;******************
lcdGetData:
    push    bc                ; Preserve
    call    lcdWait
    
    ld      c, lcdData        ; Data port
    in      a, (c)
    pop     bc
    ret
    
;******************
;Send an asciiz string to the LCD
;Entry: HL=address of string
;Exit: HL=address of ending zero of the string. All others preserved
;******************
lcdSendAsc:
    push    af
    push    bc                ; Preserve
lcdAscC
    call    lcdWait
    
    ld      a,(hl)            ; Get character
    and     a                 ; Is it zero?
    jr      z, lcdAscD        ; If so, we're done
    
    ld      c, lcdData        ; Data port
    out     (c),a             ; Send data
    inc     hl                ; Next char
    jr      lcdAscC
    
lcdAscD:
    pop     bc                ; Restore
    pop     af
    ret


; Wait for the busy flag (BF) to be cleared. This hangs with no display detected.
lcdWait:                      ; Destroys flags
    push    bc
    ld      c, lcdCtrl        ; Command port
lcdWaitL:
    in      b, (c)            ; Read status byte
    sla     b                 ; Shift busy bit (7) into carry flag
    jr      c, lcdWaitL       ; While busy
    pop     bc
    ret

; Get the address counter from the status register. Destroys A.
lcdAddrC:
    call    lcdWait
    in      a, (c)            ; Read status byte
    and     7Fh               ; mask off busy flag
    ret

; Set cursor to proper line and position
; B contains row, C contains line position
lcdCurs:
    ld      a, b
    ld      (lcdRow), a
    ld      a, c
    ld      (lcdCol), a
    cp      20          ; C: must be 19 maximum (13h)
    jr      nc, lccErr  ; check column <=19

    ld      hl, lRowOfs
    ld      a, l
    add     a, b
    ld      l, a
    jr      nc, lcNoC   ; no carry in L, skip H increment
    inc     h
lcNoC:
    ld      a, (hl)
    ld      (lcdMem), a
    or      lcd_setdramad
    
    call    PRINT_NEW_LINE
    call    PRINTHBYTE
    
    call    lcdSendCmd
    jr      lcDone

; B: 0 - 1st line starts at 0   - add 0             ; 00h
;    1 - 2nd line starts at 40  - add 40h           ; 28h
;    2 - 3rd line starts at 20  - add 20            ; 14h
;    3 - 4th line starts at 60  - add 40h + 20      ; 3Ch
lRowOfs:
    defb    00
    defb    40h
    defb    lcd_llength
    defb    40h + lcd_llength

lcrErr:
    jr      lcDone
lccErr:
    halt
lcDone:
    ret

nib2asc:
        AND     0Fh                 ;Only low nibble in byte
        ADD     A,'0'               ;Adjust for char offset
        CP      '9' + 1             ;Is the hex digit > 9?
        JR      C,n2a1              ;Yes - Jump / No - Continue
        ADD     A,'A' - '0' - 0Ah 	;Adjust for A-F
n2a1:
        RET

; vertical scroll / carriage return
; read characters from line 1 and write them to line 0
; for x=0 to 59:
;  write (x, (read x + 20))
; d will iterate up from 20 to 79
; e will count down from 59 to 0
; b is temporary storage
vscroll:
    push    de
    push    bc
    ld      d, 20   ; first char to transfer
    ld      e, 59   ; number of characters to transfer
vsloop:
    ld      a, d
    or      lcd_setdramad
    call    lcdSendCmd
    call    lcdGetData
    ld      b, a
    ld      a, d
    sub     20
    or      lcd_setdramad
    ld      a, b
    call    lcdSendAsc
    dec     e
    jr      nz, vsloop
    pop     bc
    pop     de
    ret
    
