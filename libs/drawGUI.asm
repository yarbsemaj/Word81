DRAW_FRAME:
	;Code to draw horizontal lines
	dFileOffsetToHL $0b, 0 ; 1st Line of words
	LD	B, $0B
	CALL DRAW_H_LINE
	dFileOffsetToHL $0b, 2 ;2nd Line of words
	LD	B, $0B
	CALL DRAW_H_LINE
	dFileOffsetToHL $0b, 4 ;3rd Line of words
	LD	B, $0B
	CALL DRAW_H_LINE
	dFileOffsetToHL $0b, 6 ;4th Line of words
	LD	B, $0B
	CALL DRAW_H_LINE
	dFileOffsetToHL $0b, 8 ;5th Line of words
	LD	B, $0B
	CALL DRAW_H_LINE
	dFileOffsetToHL $0b, 10 ;6th Line of words
	LD	B, $0B
	CALL DRAW_H_LINE
	dFileOffsetToHL $0b, 12 ;7th Line of words
	LD	B, $0B
	CALL DRAW_H_LINE
				
	dFileOffsetToHL 05, 14  ;Top of Keyboard
	LD	B, $17
	CALL DRAW_H_LINE

	dFileOffsetToHL 5, 22
	LD	B, $17
	CALL DRAW_H_LINE

	;Draw Vertical line
	dFileOffsetToHL 11, 1 ;1st Line of words
	LD	B, $0B
	CALL DRAW_H_LINE_WITH_SPACES
	dFileOffsetToHL 11, 3 ;2nd Line of words
	LD	B, $0B
	CALL DRAW_H_LINE_WITH_SPACES
	dFileOffsetToHL 11, 5 ;3rd Line of words
	LD	B, $0B
	CALL DRAW_H_LINE_WITH_SPACES
	dFileOffsetToHL 11, 7 ;4th Line of words
	LD	B, $0B
	CALL DRAW_H_LINE_WITH_SPACES
	dFileOffsetToHL 11, 9 ;5th Line of words
	LD	B, $0B
	CALL DRAW_H_LINE_WITH_SPACES
	dFileOffsetToHL 11, 11 ;6th Line of words
	LD	B, $0B
	CALL DRAW_H_LINE_WITH_SPACES		
	dFileOffsetToHL 05, 15 ;Keyboard Top Boarder
	LD	B, $17
	CALL DRAW_H_LINE_WITH_SPACES
	dFileOffsetToHL 05, 16 ;Keyboard Top Boarder
	LD	B, $17
	CALL DRAW_H_LINE_WITH_SPACES
	dFileOffsetToHL 05, 18 ;Keyboard Top Boarder
	LD	B, $17
	CALL DRAW_H_LINE_WITH_SPACES
	dFileOffsetToHL 05, 20 ;Keyboard 3rd Letters
	LD	B, $17
	CALL DRAW_H_LINE_WITH_SPACES
	

	CALL DRAW_BLANK_KEYBOARD
	RET

DRAW_H_LINE:
	LD	A, $88
DRAW_H_LINE_LOOP:
	LD		(HL), A
	INC		HL
	DJNZ DRAW_H_LINE_LOOP
	RET


DRAW_H_LINE_WITH_SPACES:
	LD	A, $88
	LD	(HL), A
	INC	HL
	DEC B	;Account for the first and last line
	DEC B
	LD	A, $00
DRAW_H_LINE_LOOP_W_SPACES:
	LD		(HL), A
	INC		HL
	DJNZ DRAW_H_LINE_LOOP_W_SPACES
	LD	A, $88
	LD	(HL), A
	RET

PRINT_THINKING:
	PUSH	AF
	PUSH	BC
	PUSH	HL
	LD		BC, $0D0B
	CALL	PRINTAT
	LD		HL,THINKING
	CALL	PLINE
	POP		HL
	POP		BC
	POP		AF
	RET

PRINT_WORD_INVALID:
	LD		BC, $0D09
	CALL	PRINTAT
	LD		HL,WORD_INVALID
	CALL	PLINE
	JP		DELAY_TS

CLEAR_STATUS_LINE:
	PUSH	AF
	PUSH	BC
	PUSH	HL
	dFileOffsetToHL(9,$0D)
	LD		B,$10
CLEAR_STATUS_LINE_LOOP:
	LD		(HL),0
	INC		HL
	DJNZ	CLEAR_STATUS_LINE_LOOP
	POP		HL
	POP		BC
	POP		AF
	RET


REDRAW_ACTIVE_LINE:
	LD		A, (guess)
REDRAW_LINE:
	LD		DE, $010C				;This IS our Starting Point
	OR		A
	JR		Z, REDRAW_ACTIVE_LINE_LOOP_END	
	;If were on guess 0 no need to move
	LD		B,A
REDRAW_LINE_LOOP:
	INC		D
	INC		D
	DJNZ	REDRAW_LINE_LOOP
REDRAW_ACTIVE_LINE_LOOP_END:
	PUSH	DE
	POP		BC
	CALL	PRINTAT					;Move the Cursor to the start of the line
	LD		B, 0					; Line Length
	LD		HL, buffer
	LD		DE, activeLineState
LINE_PRINT_LOOP:
	LD		A,	(bufferL)		
	CP		B
	JR		Z, PRINT_CURSOR
	JR		C, PRINT_BLANK
	LD		A,(HL)
	PUSH	BC
	LD		B,A
	LD		A,(DE)
	BIT		keyboard_both_bit, A
	CALL	NZ, INVERT_CHAR_IN_B
	LD		A,B
	CALL	PRINT
	POP		BC
	INC		HL
	INC		DE
PRINT_SPACER:
	INC		B
	LD		A,B
	CP		5
	RET		Z
	LD		A,0
	CALL	PRINT
	JR		LINE_PRINT_LOOP
PRINT_CURSOR:
	LD		A, $96
	CALL	PRINT
	JR		PRINT_SPACER

INVERT_CHAR_IN_B:
	LD		A,B
	ADD		$80
	LD		B,A
	RET

REDRAW_ACTIVE_UNDERLINE:
	LD		A, (guess)
	LD		DE, $020C				;This IS our Starting Point
	OR		A
	JR		Z, REDRAW_ACTIVE_UNDERLINE_LOOP_END	
	;If were on guess 0 no need to move
	LD		B,A
REDRAW_UNDERLINE_LOOP:
	INC		D
	INC		D
	DJNZ	REDRAW_UNDERLINE_LOOP
REDRAW_ACTIVE_UNDERLINE_LOOP_END:
	PUSH	DE
	POP		BC
	CALL	PRINTAT					;Move the Cursor to the start of the line
	LD		B, 0					; Line Length
	LD		DE, activeLineState
UNDERLINE_PRINT_LOOP:
	LD		A,(DE)
	BIT		keyboard_char_bit, A

	JR		NZ, PRINT_UNDERLINE
	LD		A,$88
	CALL	PRINT
PRINT_UNDERLINE_SPACER:
	INC		DE
	INC		B
	LD		A,B
	CP		5
	RET		Z
	LD		A,$88
	CALL	PRINT
	JR		UNDERLINE_PRINT_LOOP

PRINT_UNDERLINE:
	LD		A,$89
	CALL	PRINT
	JR		PRINT_UNDERLINE_SPACER

PRINT_BLANK
	LD		A, 0
	CALL	PRINT
	JR		PRINT_SPACER


PLAY_AGAIN_LOOP
	CALL 	KSCAN		; get a key from the keyboard
	LD		B,H
	LD		C,L
	LD		D,C
	INC		D
	LD		A,01h					; If no key entered
	JR		Z, PLAY_AGAIN_LOOP			; then loop
	CALL	FINDCHAR				; Translate keyboard result to character
	LD		A,(HL)					; Put results into reg a
	CP		_Y						;
	JP 		Z, PROG_START				;
	CP		_N						;
	JR 		Z, QUIT					;
	LD		BC,$1200				; Set pause to $1200
PA_DELAY
	DEC		BC						; Pause routine  - Probably need a debounce routine
	LD		A,B
	OR		C
	JR		NZ,PA_DELAY
	JP		PLAY_AGAIN_LOOP

QUIT
	RET

GAME_OVER:
	LD		BC, $0D00
	CALL	PRINTAT
	LD		HL,LOSS_MESSAGE
	CALL	PLINE
	CALL	PRINT_ACTIVE_WORD
	LD		HL,PLAY_AGAIN
	CALL	PLINE
	JP		PLAY_AGAIN_LOOP

PLINE	
	LD		A,(HL)		;load A with a character at HL
	CP		$FF			;is this $FF
	RET		Z			;if so, then jump to end
	CALL	PRINT		;print character
	INC		HL			;increment HL to get to next character
	JP		PLINE		;jump to beginning of loop