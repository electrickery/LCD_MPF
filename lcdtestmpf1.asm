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

; write
lcd_cls     equ     01h        ; Clear display
lcd_home    equ     02h     ; Return home
lcd_entMd   equ     04h     ; Entry mode set (cursor move direction and display shift)
lcd_entSh   equ     01h     ;   Entry mode display shift bit
lcd_entCd   equ     02h     ;   Entry mode display cursor move diection bit
lcd_donMod  equ     08h     ; Display on/off control (display, cursor, blink)
lcd_donD    equ     04h     ;   Display on/off control display bit
lcd_donC    equ     02h     ;   Display on/off control cursor bit
lcd_donB    equ     01h     ;   Display on/off control cursor blink bit
lcd_cdShft  equ     10h     ; Cursor or display shift 
lcd_cdC     equ     08h     ;   Cursor or display shift S/C (display / cursor)
lcd_cdR     equ     04h     ;   Cursor or display shift R/L (right / left)

lcd_set8bit equ     3fh     ; 8-bit port, 2-line display
lcd_curOn   equ     0fh     ; Turn cursors on (lcd_donMod + lcd_donD + lcd_donC + lcd_donB)

lcd_setcgradd equ   40h     ; Set CGRAM address (bit 0-5 contain address)
lcd_setdramad equ   80h     ; Set DDRAM address (bit 0-6 contain address)

lcd_2ndrow  equ     40h     ; Default address 1st char, 2nd row

; read
lcd_statM   equ     80h     ; Bit 7 contains busy flag
lcd_addr    equ     4Fh     ; Bit 0-6 contain address counter

    org     2000h
    
    ;Initialisation
    ld      a,lcd_set8bit
    call    lcdSendCmd
    
    ld      a,lcd_curOn
    call    lcdSendCmd
    
    ld      a,lcd_cls
    call    lcdSendCmd
    
    ;Send a single character
    ld      a,'>'
    call    lcdSendData
    
    ;Send a string
    ld      hl,hello_world
    call    lcdSendAsc
    
    ;2nd line
    ld      a, lcd_setdramad + lcd_2ndrow
    call    lcdSendCmd
    ;
    ld      hl,mpf1
    call    lcdSendAsc
    
    ld      a, lcd_home
    call    lcdSendCmd
    
    halt
    
hello_world:
    DEFB    ' Hello, world!', 0
    
mpf1:
    DEFB    '   from MPF-I', 0
    
;******************
;Send a command byte to the LCD
;Entry: A= command byte
;Exit: All preserved
;******************
lcdSendCmd:
    push    bc                ; Preserve
    call    lcdWait
    
    out     (c), a            ; Send command
    pop     bc                ; Restore
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
    jr      z,lcdAscD         ; If so, we're done
    
    ld      c,lcdData         ; Data port
    out     (c),a             ; Send data
    inc     hl                ; Next char
    jr      lcdAscC
    
lcdAscD:
    pop     bc                ; Restore
    pop     af
    ret

; Wait for the busy flag (BF) to be cleared. This hangs with no display detected.
lcdWait:                      ; Destroys bc
    ld      c, lcdCtrl        ; Command port
lcdWaitL:
    in      b, (c)            ; Read status byte
    sla     b                 ; Shift busy bit (7) into carry flag
    jr      c, lcdWaitL       ; While busy
    ret
