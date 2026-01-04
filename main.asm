dFileOffsetToHL macro  x,y
	LD		HL,dfile + 1 + x + 33 * y
    endm 

keyboard_both_bit equ 2
keyboard_char_bit equ 1
keyboard_no_match_bit equ 0

AUTORUN  .equ line1
include "libs/sysvars.asm"
include "libs/line0.asm"
include "libs/charcode.asm"
include "libs/rom.asm"

PROG_START:
	CALL 	CLS
	CALL 	INIT_VARS
	CALL 	GET_WORD
	CALL 	DRAW_FRAME
	CALL	REDRAW_ACTIVE_LINE

GAME_LOOP:
;Read the Keyboard
KEY_LOOP:
	CALL 	KSCAN		; get a key from the keyboard
	LD		B,H
	LD		C,L
	LD		D,C
	INC		D
	LD		A,01h					; If no key entered
	JR		Z, KEY_LOOP				; then loop
	CALL	FINDCHAR				; Translate keyboard result to character
	CALL	CLEAR_STATUS_LINE
	LD		A,(HL)					; Put results into reg a
	CP		$77
	JR		Z, GO_BACK
	CP		$76
	JR		Z, ENTER_GUESS
	CP		_A
	JR		C, KEY_LOOP
	CP		_Z + 1
	JR		C, KEY_ACCEPT
	JR		KEY_LOOP
KEY_ACCEPT:
	LD		(scratchPad1_8Bit),A	;Save the pressed key
	LD		A, (bufferL)			;Get the Current Buffer Length 
	CP		5						;Are we at the end of the buffer
	JR		Z, KEY_LOOP				;If so, go home
	LD		HL, buffer				;If not Update the buffer
	LD		C,A
	LD		B,0
	ADD		HL, BC					;Jump to the end of the buffer
	INC		A
	LD		(bufferL), A
	LD		A,(scratchPad1_8Bit)	;Get by the pressed key
	LD		(HL), A					;Save the chat to the buffer
	CALL	REDRAW_ACTIVE_LINE

DELAY_TS
	LD		BC,$1200				; Set pause to $1200
DELAY_LOOP
	DEC		BC						; Pause routine  - Probably need a debounce routine
	LD		A,B
	OR		C
	JR		NZ,DELAY_LOOP
	JR		KEY_LOOP

GO_BACK:
	LD		A, (bufferL)
	OR		A
	JR		Z,DELAY_TS
	DEC		A
	LD		(bufferL), A
	CALL	REDRAW_ACTIVE_LINE
	JR		DELAY_TS

ENTER_GUESS:
	LD		A, (bufferL)
	CP		5
	JR		NZ, DELAY_TS		;Guess Not Long Enough
CHECK_WORD_IN_DICTIONARY:
	LD		HL, words - 4
	LD		(scratchPad1_16Bit), HL
	CALL	PRINT_THINKING
CHECK_WORD_IN_DICTIONARY_LOOP:
	LD		HL, (scratchPad1_16Bit)
	INC		HL
	INC		HL
	INC		HL
	INC		HL
	LD		(scratchPad1_16Bit), HL
	LD		A, (HL)
	CP		$FF					;The buffer ends with a FF
	JP		Z, PRINT_WORD_INVALID
	LD		DE, dictionaryWord
	PUSH	HL
	CALL	UNPACK_WORD
	POP		HL
	LD		B,5
	LD		HL, dictionaryWord
	LD		DE, buffer
CHECK_WORD_IN_DICTIONARY_LETTER_BY_LETTER_LOOP:
	LD		A, (HL)
	LD		C,A
	LD		A, (DE)
	CP		C
	JR		NZ, CHECK_WORD_IN_DICTIONARY_LOOP
	INC		HL
	INC		DE
	DJNZ	CHECK_WORD_IN_DICTIONARY_LETTER_BY_LETTER_LOOP
VALIDATE_GUESS:
	CALL	CLEAR_STATUS_LINE
	LD		HL, buffer
	LD		DE, currentWord
	LD		B, 0				;Were Going Over 5 Letters
VALIDATE_LOOP:
	LD		A, (HL)
	LD		C,A
	LD		A, (DE)
	LD		(scratchPad1_8Bit), A
	LD		(scratchPad1_16Bit), HL
	LD		(scratchPad2_16Bit), DE
	LD		(scratchPad3_16Bit), BC
	CP		C
	JP		Z,BOTH_MATCH
CHECK_FOR_POS:
	;IF both position and place don't match then we could still have the right letter in the wrong place, lets look for that
	LD		B,5					;Look over 5 chars	
	LD		DE, currentWord		;Lets Reset DE
CHECK_FOR_POS_LOOP
	LD		A, (HL)				;Lets get our char back
	LD		C,A					;Save Our word
	LD		A,(DE)				;Char from the current word
	CP		C
	JP		Z, CHAR_MATCH		;They match
	INC		DE					;If not lets move onto the next char
	DEC		B
	LD		A,B
	OR		A					;Are we at the end of the loop
	JR		NZ, CHECK_FOR_POS_LOOP
	
NO_MATCH:						;IF we get here, we don't have any matches
	LD		BC, (scratchPad3_16Bit)
	LD		HL, (scratchPad1_16Bit)
	LD		A, (scratchPad1_8Bit)
	LD		A,C							;C contains the letter were looking at in our word
	SUB		_A							;Base 0 the Char
	LD		C,A	
	LD		B,0
	LD		HL, keyboardState
	ADD		HL,BC
	SET     keyboard_no_match_bit,(HL) 	;Update the keyboard
	LD		HL, activeLineState			;Now Start on the active line
	LD		BC, (scratchPad3_16Bit)		;Get Back our Char
	LD		C,B
	LD		B,0
	ADD		HL,BC					;Add B to activeLineState to get the array position
	SET     keyboard_no_match_bit,(HL);Update the active line

END_OF_CHAR_MATCHING:
	LD		DE, (scratchPad2_16Bit)
	LD		BC, (scratchPad3_16Bit)
	LD		HL, (scratchPad1_16Bit)
	LD		A, (scratchPad1_8Bit)
	INC		HL					;Next Char in the Buffer
	INC		DE					;Next Char in thw word
	INC		B					;One Less loop
	LD		A,B
	CP		5	
	JP		NZ, VALIDATE_LOOP

	CALL	DRAW_BLANK_KEYBOARD
	CALL	REDRAW_ACTIVE_LINE
	CALL	REDRAW_ACTIVE_UNDERLINE

;Check for a win
	LD		B,5
	LD		HL, activeLineState
CHECK_WIN_LOOP:
	LD		A,(HL)
	BIT		keyboard_both_bit, a
	JR		Z, CLEAR_ACTIVE_LINE_STATE
	INC		HL
	DJNZ	CHECK_WIN_LOOP
;We have won!
	LD		BC, $0D07
	CALL	PRINTAT
	LD		HL,WIN_MESSAGE
	CALL	PLINE
	LD		HL,PLAY_AGAIN
	CALL	PLINE
	JP		PLAY_AGAIN_LOOP
	
;We have drawn the line, now clear its state so we can draw the next one
CLEAR_ACTIVE_LINE_STATE:
	LD		B,5
	LD		HL,activeLineState
CLEAR_ACTIVE_LINE_STATE_LOOP:
	LD		(HL),0
	INC		HL
	DJNZ	CLEAR_ACTIVE_LINE_STATE_LOOP
	LD		A, (guess)
	INC		A
	CP		6
	JP		Z, GAME_OVER
	LD		(guess), A
	LD		A,0
	LD		(bufferL),A
	CALL	REDRAW_ACTIVE_LINE
	JP		DELAY_TS

CHAR_MATCH:
	SUB		_A						;Base 0 the Char
	LD		C,A	
	LD		B,0
	LD		HL, keyboardState
	ADD		HL,BC
	SET     keyboard_char_bit,(HL)	;Update the keyboard
	LD		HL, activeLineState		;Now Start on the active line

	LD		BC, (scratchPad3_16Bit)	;Get back or position on the line
	LD		C,B
	LD		B,0
	ADD		HL,BC					;Add B to activeLineState to get the array position
	SET     keyboard_char_bit, (HL)	;Update the active line
	JP		END_OF_CHAR_MATCHING

BOTH_MATCH:
	SUB		_A						;Base 0 the Char
	LD		C,A	
	LD		B,0
	LD		HL, keyboardState
	ADD		HL,BC
	SET     keyboard_both_bit, (HL)	;Update the keyboard
	LD		HL, activeLineState		;Now Start on the active line
	LD		BC, (scratchPad3_16Bit)
	LD		C,B
	LD		B,0
	ADD		HL,BC					;Add B to activeLineState to get the array position
	SET	    keyboard_both_bit, (HL)	;Update the active line
	JP		END_OF_CHAR_MATCHING

INIT_VARS:
	LD		B, varEnd-varStart
	LD		HL, varStart
INT_VAR_LOOP:
	LD		(HL), 0
	INC		HL
	DJNZ	INT_VAR_LOOP
	RET


GET_WORD:
	LD 		DE,($4034)
	LD		A,D
	AND		00000111b
	LD		D,A
	INC		DE
	LD		HL, words - 4 ; We always add 5 to the array offset 
GET_WORD_LOOP:
	INC		HL
	INC		HL
	INC		HL
	INC		HL
	DEC		DE
	LD 		A,D
    OR 		E
    JP 		NZ,GET_WORD_LOOP
	LD		DE, currentWord
	CALL	UNPACK_WORD
	RET

PRINT_ACTIVE_WORD
	LD		B,5
	LD		HL,currentWord
PRINT_ACTIVE_WORD_LOOP:
	LD		A,(HL)
	INC		HL
	PUSH	HL
	CALL	PRINT
	POP		HL
	DJNZ	PRINT_ACTIVE_WORD_LOOP
	RET

; the ordering of this file's includes is critical - don't change it.
;
WIN_MESSAGE:
		.byte	_Y,_O,_U,$00,_W,_O,_N,$ff
PLAY_AGAIN:
		.byte	$1B,$00,_P,_L,_A,_Y,$00,_A,_G,_A,_I,_N,$0F,$ff
LOSS_MESSAGE:
		.byte	_T,_H,_E,$00,_W,_O,_R,_D,$00,_W,_A,_S,$00,$ff
THINKING:
		.byte	_T,_H,_I,_N,_K,_I,_K,_G,$1B,$1B,$1B,$ff
WORD_INVALID:
		.byte	_W,_O,_R,_D,$00,_N,_O,_T,$00,_I,_N,$00,_L,_I,_S,_T,$ff

include "libs/unpackWord.asm"
include "libs/keyboard.asm"
include "libs/drawGUI.asm"
keyboardOffsets:
include "data/keyboardOffset.asm"
words:
include "data/words_packed.asm"
	.byte	$FF
varStart:
;Scratch PAD Vars
scratchPad1_8Bit;
	defs 1
scratchPad1_16Bit;
	defs 2
scratchPad2_16Bit;
	defs 2
scratchPad3_16Bit;
	defs 2
dictionaryWord:
	defs 5		;When checking the word, we expand into this buffer
currentWord:
	defs 5		;Expanded word were trying to guess
activeLineState:
	defs 5
keyboardState:
	defs 26
buffer
	defs 5
guess:
	defs 1		;Guess Number
bufferL:
	defs 1		;Guess Number
varEnd:


include "libs/line1.asm"


