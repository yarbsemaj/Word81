UNPACK_WORD:
    ; Input: HL = address of 4 packed bytes
    ; Output: DE = address to store 5 unpacked ASCII letters
    ; Unpacks 4 bytes (left-aligned 25 bits) to 5 ASCII letters (A=65)

    LD      A,(HL)        ; Byte 0
    INC     HL
    LD      B,A
    LD      A,(HL)        ; Byte 1
    INC     HL
    LD      C,A
    LD       A,(HL)      ; Byte 2
    PUSH    AF           ; Save byte 2 on stack
    LD      A,(HL)       ; Byte 3 is either 0 or 128 based on wether L if odd or even
    BIT     0, L         ; Because were dealing with 3 bits, this will toggle between odd and even
    JR      NZ, SET_128   ;As the data is also interleaved this means we can save a bit 
    LD      A,0
    PUSH    AF          ; Save byte 3 on stack

FIST_LETTER:
    ; 1st letter: bits 31-27 (B7-B3)
    LD      A,B
    AND     0xF8         ; 11111000
    SRL     A
    SRL     A
    SRL     A
    ADD     A,_A
    LD      (DE),A
    INC     DE

    ; 2nd letter: bits 26-22 (B2-B0, C7-C6)
    LD      A,B
    AND     0x07         ; 00000111
    RLCA
    RLCA             ; B2-B0 to bits 4-2
    LD      H,A           ; Save partial
    LD      A,C
    AND     0xC0         ; 11000000
    RRCA
    RRCA
    RRCA
    RRCA
    RRCA
    RRCA             ; C7-C6 to bits 1-0
    OR      H
    AND     0x1F
    ADD     A,_A
    LD      (DE),A
    INC     DE

    ; 3rd letter: bits 21-17 (C5-C1)
    LD      A,C
    AND     0x3E         ; 00111110
    SRL     A
    ADD     A,_A
    LD      (DE),A
    INC     DE

    ; 4th letter: bits 16-12 (C0, D7-D4)
    LD      A,C
    AND     0x01         ; 00000001
    RLCA
    RLCA
    RLCA
    RLCA             ; C0 to bit 4
    LD      H,A
    POP     AF           ; Get byte 3
    LD      C,A           ; Use B as temp
    POP     AF           ; Get byte 2
    LD      B,A           ; Use C as temp
    LD      A,B           ; Use byte 3 for D7-D4
    AND     0xF0         ; 11110000
    RRCA
    RRCA
    RRCA
    RRCA             ; D7-D4 to bits 3-0
    OR      H             ; Combine with C0 in bit 4
    AND     0x1F
    ADD     A,_A
    LD      (DE),A
    INC     DE

    ; 5th letter: bits 11-7 (C3-C0, B7)
    LD      A,B
    AND     0x0F         ; 00001111
    RLCA             ; C3-C0 to bits 4-1
    LD      L,A           ; Use L as temp
    LD      A,C
    AND     0x80         ; 10000000
    RRCA
    RRCA
    RRCA
    RRCA
    RRCA
    RRCA
    RRCA
    OR      L
    AND     0x1F
    ADD     A,_A
    LD      (DE),A
    INC     DE

    RET

SET_128:
    LD      A, 128
    PUSH    AF
    JR      FIST_LETTER