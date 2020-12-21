$NOMOD51
#include <Reg517a.inc>

; Memory Usage:
; 40  = DeltaC Low-Byte
; 41  = DeltaC High-Byte
; 42  = Number of Iterations
; 50
; 51
; 53  = set if |Zn| greater than 2
; 52  = status Bytes
; 60  = column counter
; 61  = row counter
; 70  = Re(C) Low-Byte
; 71  = Re(C) High-Byte
; 72  = Im(C) Low-Byte
; 73  = Im(C) High-Byte

pointAReH EQU 247 ; #111101$11b
pointAReL EQU 0
	
pointAImH EQU 250 ; #111110$10b
pointAImL EQU 0   ; #00000000b

pointBReH EQU 3   ; #000000$11b
pointBReL EQU 0   ; #00000000b
	
pointBImH EQU 6   ; #000001$10b
pointBImL EQU 0   ; #00000000b

PX EQU 20
NMax EQU 20
	
ORG 00h
	LJMP program	; jump to start of program

ORG 1000h
	
program:
	LCALL initSerialInterface
	LCALL calcDeltaC
	LCALL initC
program_loop:
	LCALL calcColor
	LCALL calcChar
	LCALL output
	LCALL count
	LCALL isFinished
	LCALL moveC
	LJMP program_loop

; input:  None
; use:    None
; output: None
initSerialInterface:
	; SMOD = 1
	; PCON --> 10000000b
	; doubles the baud rate
	MOV PCON, #10000000b
	; COM1
	; SM0 = 0
	; SM1 = 1
	; S0CON --> 01000000b for Mode 1
	MOV S0CON, #01000000b ;
	; BD (Baudrate generator enabled) = 1
	; ADCON0 --> 10000000b
	MOV ADCON0, #10000000b
	; 28800 Baudrate --> SMOD = 1 & S0RELH|S0RELL = 3E6h
	MOV S0RELH, #03h
	MOV S0RELL, #0E6h
	RET

; input:  None
; use:    A, R0-1
; output: None
calcDeltaC:
	; starting with bRe - aRe
	mov A, #pointAReH
	jb ACC.7, addAComplement 	; aRe is negativ
	mov A, #pointBReH
	jb ACC.7, addAComplement 	; bRe is negativ
	; A > 0 and B > 0 --> normal subtraction 
	mov A, #pointBReL
	subb A, #pointAReL
	mov R0, A 					; Delta c low-Byte
	mov A, #pointBReH
	subb A, #pointAReH
	mov R1, A 					; Delta c high-Byte
	clr C
	ljmp continueCalcDeltaC
addAComplement:
	; if one of both numbers is negativ (or both are), adding the complement from a always works
	mov A, #pointAReL
	xrl A, #11111111b
	add A, #1				; to generate overflow in carry bit
	mov R0, A
	mov A, #pointAReH
	xrl A, #11111111b
	addc A, #0
	mov R1, A
	;add a
	mov A, #pointBReL
	add A, R0
	mov R0, A 				; Delta c low-Byte
	mov A, #pointBReH
	addc A, R1
	mov R1, A 				; Delta c high-Byte	
continueCalcDeltaC:
	mov A, #PX	; Da PX maximal 111d beträgt, genügen 8Bit und es wird keine weitere Logik benötigt
	dec A
	; Berechnung von Delta c mit MDU  (DIV)
	mov MD0, R0
	mov MD1, R1
	mov MD4, A
	mov MD5, #0
	; Execution Time
	nop
	nop
	nop
	nop
	; Ergebnis holen
	mov R0, MD0
	mov R1, MD1
	; Nun befindet sich Delta c in R0 und R1
	mov 40h, R0
	mov 41h, R1
	RET

; input:  None
; use:    output
; output: R0 = pointAReL
;         R1 = pointAReH
;         R2 = pointBImL
;         R3 = pointBImH
initC:
	MOV 70h, #pointAReL
	MOV 71h, #pointAReH
	MOV 72h, #pointBImL
	MOV 73h, #pointBImH
	RET
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


calcColor:
	; LCALL ...
	MOV 0x42, #1
	MOV R0, 70h
	MOV R1, 71h
	MOV R2, 72h
	MOV R3, 73h
calcColorLoop:
	LCALL checkZnAbsolutAmount
	JB ACC.0, endCalcColor
	LCALL calcZnQuadrat
	LCALL addCToZ
	INC 0x42
	MOV A, 0x42
	CJNE A, #NMax, calcColorLoop	
endCalcColor:
	MOV R7, 0x42
	RET


; input:  Zn in R0 = ZnReL
;         R1 = ZnReH
;         R2 = ZnImL
;         R3 = ZnImH
; use:    R0-6
; output: A = set if greater than 2
checkZnAbsolutAmount:
	; store Zn in 55-58h temporarily
	MOV 0x55, R0
	MOV 0x56, R1
	MOV 0x57, R2
	MOV 0x58, R3
	LCALL checkZnRe
	LCALL checkZnIm
	LCALL calcZnAbsolutAmount
	MOV R0, 0x55
	MOV R1, 0x56
	MOV R2, 0x57
	MOV R3, 0x58
	RET

; this function checks whether ZnRe is negativ and gets the complement
checkZnRe:
	; check ZnRe negativ
	mov 0x50, #0			; resest 0x50
	mov A, R1
	jnb ACC.7, checkZnReRet
	mov 0x50, #1			; set 0x50 if ZnRe negativ
	mov A, R0
	xrl A, #11111111b
	add A, #1				; to generate overflow in carry bit
	mov R0, A
	mov A, R1
	xrl A, #11111111b
	addc A, #0
	mov R1, A
checkZnReRet:
	ret
; this function checks whether ZnIm is negativ and gets the complement
checkZnIm:
	mov 0x51, #0			; reset 0x51
	mov A, R3
	jnb ACC.7, checkZnImRet
	mov 0x51, #1			; set 0x51 if ZnIm negativ
	mov A, R2
	xrl A, #11111111b
	add A, #1				; to generate overflow in carry bit
	mov R2, A
	mov A, R3
	xrl A, #11111111b
	addc A, #0
	mov R3, A
checkZnImRet:
	ret
	
calcZnAbsolutAmount:
	; calc ZnImSquare
	mov MD0, R2
	mov MD4, R2
	mov MD1, R3
	mov MD5, R3
	; Execution Time
	nop
	nop
	nop
	nop
	;check amount
	mov R2, MD0
	mov R3, MD1
	mov R4, MD2
	mov R5, MD3
	cjne R5, #0, greaterThan2		;if R5 contains something, ZnImSquare > 4
	mov A, R4
	subb A, #64
	jnc greaterThan2				; that means A was greater than 64
	clr C
	; calc ZnReSquare
	mov MD0, R0
	mov MD4, R0
	mov MD1, R1
	mov MD5, R1
	; Execution Time
	nop
	nop
	nop
	nop
	;check amount
	mov A, MD0
	add A, R2
	mov R0, A
	mov A, MD1
	addc A, R3
	mov R1, A
	mov A, MD2
	addc A, R4
	mov R2, A
	mov A, MD3
	addc A, R5
	mov R3, A
	cjne R3, #0, greaterThan2		; if R3 contains something ZnReSquare > 4
	mov A, R2
	anl A, #11000000b
	cjne A, #0, greaterThan2
	mov A, #0
	;jc greaterThan2				; that means the sum was greater than 15
	;mov R2, A
	;mov R3, MD3
	;cjne R3, #0, greaterThan2	; if R3 contains something ZnReSquare > 4
	;mov A, R2
	;subb A, #64
	;jnc greaterThan2				; that means the sum was greater than 4 -->
	;clr C
	;mov A, #0
	ret
greaterThan2:
	mov A, #1
	ret
	; to be continued	

; input:  Zn in R0 = ZnReL
;         R1 = ZnReH
;         R2 = ZnImL
;         R3 = ZnImH
; use:    R0-7
; output: Zn in R0 = ZnReL
;         R1 = ZnReH
;         R2 = ZnImL
;         R3 = ZnImH
calcZnQuadrat:
	mov R0, 70h
	mov R1, 71h
	mov R2, 72h
	mov R3, 73h
	; calc ZnIm
	call checkZnRe
	call checkZnIm
	mov A, 0x50
	add A, 0x51
	cjne A, #1, NewZnImPositiv
	mov 0x52, #1
NewZnImPositiv:
	; ZnRe * ZnIm * 2 = new ZnIm
	mov MD0, R0
	mov MD4, R2
	mov MD1, R1
	mov MD5, R3
	; Execution Time
	nop
	nop
	nop
	nop
	; Get results, *2 will be realized as rlc
	mov A, MD0		; has to be first read
	rlc A
	mov R4, A
	mov A, MD1
	rlc A
	mov R5, A
	mov A, MD2
	rlc A
	mov R6, A
	mov A, MD3
	rlc A
	mov R7, A
	clr C			; always clr c
	; reduce to 16 Bit with rotations
	mov A, R7
	rrc A
	mov R7, A
	mov A, R6
	rrc A
	mov R6, A
	mov A, R5
	rrc A
	mov R5, A
	clr C
	mov A, R7
	rrc A
	mov R7, A
	mov A, R6
	rrc A
	mov R6, A
	mov A, R5
	rrc A
	mov R5, A
	clr C			; safety first
	; new ZnImPositiv in R6|R5
	mov A, 0x52
	mov 0x52, #0 	; reset 0x52
	jnb ACC.0, NewZnRe
	; if ZnIm should be negativ
	mov A, R5
	xrl A, #11111111b
	add A, #1				; to generate overflow in carry bit
	mov R5, A
	mov A, R6
	xrl A, #11111111b
	addc A, #0
	mov R6, A
	; move new ZnIm in R7|R6 to create space
	mov A, R6
	mov R7, A
	mov A, R5
	mov R6, A
	; calc NewZnRe = ZnReSquare- ZnImSquare
NewZnRe:
	; ZnRe and ZnIm are already positiv, so there are no problems
	; start with ZnImSquare, result in R5|R4|R3|R2
	mov MD0, R2
	mov MD4, R2
	mov MD1, R3
	mov MD5, R3
	; Execution Time
	nop
	nop
	nop
	nop
	; 
	mov R2, MD0
	mov R3, MD1
	mov R4, MD2
	mov R5, MD3
	; calc ZnReSquare
	mov MD0, R0
	mov MD4, R0
	mov MD1, R1
	mov MD5, R1
	; Execution Time
	nop
	nop
	nop
	nop
	; ZnReSquare-ZnImSquare
	mov A, MD0
	subb A, R2
	mov R0, A
	mov A, MD1
	subb A, R3
	mov R1, A
	mov A, MD2
	subb A, R4
	mov R2, A
	mov A, MD3
	subb A, R5
	mov R3, A
	; reduce to 16 bit
	mov A, R3
	rrc A
	mov R3, A
	mov A, R2
	rrc A
	mov R2, A
	mov A, R1
	rrc A
	mov R1, A
	clr C
	mov A, R3
	rrc A
	mov R3, A
	mov A, R2
	rrc A
	mov R2, A
	mov A, R1
	rrc A
	mov R1, A
	clr C			; clean up
	; Structure output (at the moment ZnIm: R7|R6 and ZnRe: R2|R1)
	mov A, R1
	mov R0, A
	mov A, R2
	mov R1, A
	mov A, R6
	mov R2, A
	mov A, R7
	mov R3, A

; input:  Zn in R0 = ZnReL
;         R1 = ZnReH
;         R2 = ZnImL
;         R3 = ZnImH
; use:    R0-3, A
; output: Zn in R0 = ZnReL
;         R1 = ZnReH
;         R2 = ZnImL
;         R3 = ZnImH
addCToZ:
	; Re Low
	MOV A, 70h
	ADD A, R0
	MOV R0, A
	; Re High
	MOV A, 71h
	ADDC A, R1
	MOV R1, A
	; Im Low
	MOV A, 72h
	ADD A, R2
	MOV R2, A
	; Im High
	MOV A, 73h
	ADDC A, R3
	MOV R3, A
	RET
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
; input:  R7 = n
; use:    A = bitwise AND
;         R7 = everything else
; output: R7 = char
calcChar:
	CJNE R7, #NMax, calcCharMod8 ; Jump to calcCharMod8 if n != NMax
	MOV R7, #32d ; if n = NMax -> char = ' '
	RET
calcCharMod8:
	MOV A, R7
	ANL A, #111b ; value of the fourth and higher bits are devidable by 8, so they dont add up to modulo
	MOV R7, A
	CJNE R7, #0, calcCharMod8eq1
	MOV R7, #164d
	RET
calcCharMod8eq1:
	DJNZ R7, calcCharMod8eq2
	MOV R7, #43d
	RET
calcCharMod8eq2:
	DJNZ R7, calcCharMod8eq3
	MOV R7, #169d
	RET
calcCharMod8eq3:
	DJNZ R7, calcCharMod8eq4
	MOV R7, #45d
	RET
calcCharMod8eq4:
	DJNZ R7, calcCharMod8eq5
	MOV R7, #42d
	RET
calcCharMod8eq5:
	DJNZ R7, calcCharMod8eq6
	MOV R7, #64d
	RET
calcCharMod8eq6:
	DJNZ R7, calcCharMod8eq7
	MOV R7, #183d
	RET
calcCharMod8eq7:
	MOV R7, #174d
	RET

; input:  R7 = char
; use:    A = check TI and save column number
;         DPTR = column counter address
; output: None
output:
	; output of R7 via COM 0
	MOV S0BUF, R7
output_wait:
	; check if sent
	MOV A, S0CON
	JNB ACC.1, output_wait
output_finished:
	ANL S0CON, #0FDh
	RET
	
; input:  None
; use:    A
; output: None
count:
	; increase column counter
	MOV A, 60h
	INC A
	MOV 60h, A
	; check if end of row is reached
	CJNE A, #PX, count_finshed
	; reset column count
	MOV A, #0
	MOV 60h, A
	; increse row counter
	MOV A, 61h
	INC A
	MOV 61h, A
	MOV R7, #10d ; print new line
	LCALL output
count_finshed:
	RET

; input:  None
; use:    A
; output: None
isFinished:
	MOV A, 61h
	CJNE A, #PX, isFinishedNo
	LJMP finish
isFinishedNo:
	RET
	
; input:  None
; use:    R4-5, A
; output: None
moveC:
	MOV A, 60h
	JZ moveCIm ; check if column number = 0
	; add deltaC to C (Re)
	MOV R4, 70h
	MOV R5, 71h
	MOV A, 40h
	ADD A, R4
	MOV 70h, A
	MOV A, 41h
	ADDC A, R5
	MOV 71h, A
	RET
moveCIm:
	; add deltaC to C (Im)
	MOV R4, 72h
	MOV R5, 73h
	MOV A, 40h
	ADD A, R4
	MOV 72h, A
	MOV A, 41h
	ADDC A, R5
	MOV 73h, A
	; reset C (Re)
	MOV 70h, #pointAReL
	MOV 71h, #pointAReH
	RET

; input:  None
; use:    None
; output: None
finish:
	NOP
	
end