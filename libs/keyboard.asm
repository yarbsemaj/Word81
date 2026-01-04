DRAW_BLANK_KEYBOARD:
	dFileOffsetToHL 05, 17 ;Keyboard 1st Underline
	LD	B, $17
	CALL DRAW_H_LINE_WITH_SPACES
	dFileOffsetToHL 05, 19 ;Keyboard 2nd Underline
	LD	B, $17
	CALL DRAW_H_LINE_WITH_SPACES
	dFileOffsetToHL 05, 21 ;Keyboard 3rd Underline
	LD	B, $17
	CALL DRAW_H_LINE_WITH_SPACES


	LD	B, 26					;26 keys
	LD	DE, keyboardOffsets - 1	;Address Of the key offset
DRAW_BLANK_KEYBOARD_LOOP:
	LD		A,B
	LD		(scratchPad1_8Bit), A
	LD		A, _A - 1			;Convert the letter to the ZX81 Char set 
	ADD 	B
	PUSH	BC
	LD		HL, (D_FILE)		;Start of D file
	PUSH	DE
	LD		DE, 528				;Offset to the start of the keyboard line
	ADD		HL, DE				;Get to the start of the keyboard in the dfile and Put in in HL
	POP		DE					;Get back our Offset Array
	PUSH	HL					;Save dfile
	LD		L,B					;Put the current loop iternation into HL
	LD		H,0
	ADD		HL, DE				;Add The offset to DE (Keyboard Offset Array), to get the address of the current offset				;Get The 
	PUSH	AF
	LD		A, (HL)				; A now has the offset fot the specific letter stored in it
	
	LD		C,A	
	LD 		B,0					;Get the offset to the letter in BC
	POP		AF					;Get AF back
	POP		HL					;Get HL Back
	ADD		HL, BC				;We now have our final D file offset
	PUSH	HL
	PUSH	AF
	LD		A,(scratchPad1_8Bit)
	DEC		A 					;Array is Zero Indexed
	LD		L,A					;Put the current loop iternation into HL
	POP		AF		
	LD		H,0
	PUSH	DE
	LD		DE, keyboardState	;Offset to the start of the keyboard state array
	ADD		HL, DE				;Get the address
	POP		DE	
	PUSH	AF
	LD		A,(HL)
	BIT		keyboard_no_match_bit,A
	JR		NZ, PRINT_KEYBOARD_BLANK
	BIT		keyboard_both_bit,A
	JR		NZ, PRINT_KEYBOARD_BOLD
	BIT		keyboard_char_bit,A
	JR		NZ, PRINT_KEYBOARD_UNDERLINE
DRAW_KEYBOARD_PRINT_CHAR:
	POP		AF
	POP		HL
	LD		(HL),A				;Put our char in there
	POP		BC
	DJNZ	DRAW_BLANK_KEYBOARD_LOOP
	RET
PRINT_KEYBOARD_BLANK:
	POP		AF
	LD		A,0
	PUSH	AF
	JR		DRAW_KEYBOARD_PRINT_CHAR
PRINT_KEYBOARD_BOLD:
	POP		AF
	ADD		$80
	PUSH	AF
	JR		DRAW_KEYBOARD_PRINT_CHAR

PRINT_KEYBOARD_UNDERLINE:
	POP		AF				;Were going to modify HL and AF so save it away for later
	POP		HL
	PUSH	HL
	PUSH	AF					
	LD		BC, 33			;Move the cursor 33 address down
	ADD		HL,BC
	LD		(HL), $03
	JR		DRAW_KEYBOARD_PRINT_CHAR