$NOMOD51
#include <Reg517a.inc>

; Memory Usage:
; R0  = ZnRe Low-Byte
; R1  = ZnRe High-Byte
; R2  = ZnIm Low-Byte
; R3  = ZnIm High-Byte
; R5  = n für Modulo
; R6  = k für Spalte
; R7  = Auszugebendes Zeichen
; 500 = column counter

pointAReH EQU 247 ; #111101$01b
pointAReL EQU 0
	
pointAImH EQU 250 ; #111110$10b
pointAImL EQU 0   ; #00000000b

pointBReH EQU 3 ; #000000$11b
pointBReL EQU 0 ; #00000000b
	
pointBImH EQU 6   ; #000001$10b
pointBImL EQU 0   ; #00000000b

PX EQU 20
NMax EQU 20
	
ORG 00h
	JMP program	; jump to start of program

ORG 1000h
	
program:
	LCALL init
	LCALL calcDeltaC
program_loop:
	LCALL iniZn
	//LCALL moveC
	LCALL calcColor
	LCALL calcChar
	LCALL output
	LJMP program_loop

; input:  None
; use:    None
; output: None
init:			; start of program
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

; calc delta C
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
	jmp continueCalcDeltaC
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
	clr C		; Clear carry für nächste Berechnung
	mov A, #PX	; Da PX maximal 111d beträgt, genügen 8Bit und es wird keine weitere Logik benötigt
	dec A
	; Berechnung von Delta c mit MDU
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
	mov 0x040, R0
	mov 0x041, R1
	RET

iniZn:
	mov R0, #pointAReL
	mov R1, #pointAReH
	mov R2, #pointBReL
	mov R3, #pointBReH
	RET
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


calcColor:
	; LCALL ...
	RET


; input:  Zn in R0 = ZnReL
;         R1 = ZnReH
;         R2 = ZnImL
;         R3 = ZnImH
; use:    R0-5
; output: None
checkZnAbsolutAmount:
	call checkZnRe
	call checkZnIm
	jmp calcZnAbsolutAmount

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
	cjne R5, #0, greaterThan2	;if R5 contains something, ZnImSquare > 4
	mov A, R4
	subb A, #4
	jnc greaterThan2			; that means A was greater than 4
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
	jc greaterThan2				; that means the sum was greater than 15
	mov R2, A
	subb A, #4
	jnc greaterThan2			; that means the sum was greater than 4
	clr C
	mov R3, MD3
	cjne R3, #0, greaterThan2	; if R3 contains something ZnReSquare > 4
	jmp nextIteration
	
greaterThan2:
	nop
	; to be continued
	
nextIteration:
	nop
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
	; if ZnIm is should be negativ
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
output_reset:
	ANL S0CON, #0FDh
output_counter_operations:
	; increase column counter
	MOV DPTR, #500
	MOVX A, @DPTR
	INC A
	MOVX @DPTR, A
	; check if end of row is reached
	CJNE A, #PX, output_finished
	MOV A, #255
	MOVX @DPTR, A
	MOV R7, #10d ; new line
	LJMP output
output_finished:
	RET
	
end