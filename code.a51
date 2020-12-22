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

; Startwerte a)
pointAReH EQU 247d ; #111101$11b
pointAReL EQU 0d   ; #00000000b
	
pointAImH EQU 250d ; #111110$10b
pointAImL EQU 0d   ; #00000000b

pointBReH EQU 3d   ; #000000$11b
pointBReL EQU 0d   ; #00000000b
	
pointBImH EQU 6d   ; #000001$10b
pointBImL EQU 0d   ; #00000000b

; Startwerte b)
;pointAReH EQU 252d ; #111111$00b
;pointAReL EQU 205d ; #11001101b
;	
;pointAImH EQU 254d ; #111111$10b
;pointAImL EQU 103d ; #01100111b

;pointBReH EQU 2d   ; #000000$10b
;pointBReL EQU 102d ; #01100110b
;	
;pointBImH EQU 4d   ; #000001$00b
;pointBImL EQU 0d   ; #00000000b

PX EQU 20d
NMax EQU 20d
	
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
	MOV A, #pointBReL
	SUBB A, #pointAReL
	MOV R0, A 					; Delta c low-Byte
	MOV A, #pointBReH
	SUBB A, #pointAReH
	MOV R1, A 					; Delta c high-Byte
	CLR C
	MOV A, #PX	; Da PX maximal 111d beträgt, genügen 8Bit und es wird keine weitere Logik benötigt
	DEC  A
	; Berechnung von Delta c mit MDU (DIV)
	MOV MD0, R0
	MOV MD1, R1
	MOV MD4, A
	MOV MD5, #0
	; Execution Time
	NOP
	NOP
	NOP
	NOP
	; Ergebnis holen
	MOV 40h, MD0
	MOV 41h, MD1
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
	NOP
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
	MOV 0x50, #0			; resest 0x50
	MOV A, R1
	JNB ACC.7, checkZnReRet
	MOV 0x50, #1			; set 0x50 if ZnRe negativ
	MOV A, R0
	XRL A, #11111111b
	ADD A, #1				; to generate overflow in carry bit
	MOV R0, A
	MOV A, R1
	XRL A, #11111111b
	ADDC A, #0
	MOV R1, A
checkZnReRet:
	RET
; this function checks whether ZnIm is negativ and gets the complement
checkZnIm:
	MOV 0x51, #0			; reset 0x51
	MOV A, R3
	JNB ACC.7, checkZnImRet
	MOV 0x51, #1			; set 0x51 if ZnIm negativ
	MOV A, R2
	XRL A, #11111111b
	ADD A, #1				; to generate overflow in carry bit
	MOV R2, A
	MOV A, R3
	XRL A, #11111111b
	ADDC A, #0
	MOV R3, A
checkZnImRet:
	RET
	
calcZnAbsolutAmount:
	; calc ZnImSquare
	MOV MD0, R2
	MOV MD4, R2
	MOV MD1, R3
	MOV MD5, R3
	; Execution Time
	NOP
	NOP
	NOP
	NOP
	;check amount
	MOV R2, MD0
	MOV R3, MD1
	MOV R4, MD2
	MOV R5, MD3
	
	; check if already greater than 4
	CJNE R5, #0, greaterThan2
	MOV A, R4
	ANL A, #11000000b
	CJNE A, #0, greaterThan2
	
	; calc ZnReSquare
	MOV MD0, R0
	MOV MD4, R0
	MOV MD1, R1
	MOV MD5, R1
	; Execution Time
	NOP
	NOP
	NOP
	NOP
	;check amount
	MOV A, MD0
	ADD A, R2
	MOV R2, A
	MOV A, MD1
	ADDC A, R3
	MOV R3, A
	MOV A, MD2
	ADDC A, R4
	MOV R4, A
	MOV A, MD3
	ADDC A, R5
	
	; check if greater than 4
	CJNE A, #0, greaterThan2
	MOV A, R4
	ANL A, #11000000b
	CJNE A, #0, greaterThan2
	
	MOV A, #0
	RET
greaterThan2:
	MOV A, #1
	RET
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
 	CLR c			; safety first
	LCALL checkZnRe
	LCALL checkZnIm
	MOV A, 0x50
	ADD A, 0x51
	CJNE A, #1, NewZnImPositiv
	MOV 0x52, #1
NewZnImPositiv:
	; ZnRe * ZnIm * 2 = new ZnIm
	MOV MD0, R0
	MOV MD4, R2
	MOV MD1, R1
	MOV MD5, R3
	; Execution Time
	NOP
	NOP
	NOP
	NOP
	; Get results, because of *2 there is only one RRC to reduce to 16 bit
	MOV R4, MD0		; has to be first read
	MOV R5, MD1
	MOV R6, MD2
	MOV R7, MD3
	; reduce to 16 Bit with rotation
	MOV A, R7
	RRC A
	MOV R7, A
	MOV A, R6
	RRC A
	MOV R6, A
	MOV A, R5
	RRC A
	MOV R5, A
	CLR C
	; new ZnImPositiv in R6|R5
	MOV A, 0x52
	MOV 0x52, #0 	; reset 0x52
	JNB ACC.0, NewZnRe
	; if ZnIm should be negativ
	MOV A, R5
	XRL A, #11111111b
	ADD A, #1				; to generate overflow in carry bit
	MOV R5, A
	MOV A, R6
	XRL A, #11111111b
	ADDC A, #0
	MOV R6, A
NewZnRe:
	; move new ZnIm in R7|R6 to create space
	MOV A, R6
	MOV R7, A
	MOV A, R5
	MOV R6, A
	; calc NewZnRe = ZnReSquare- ZnImSquare
	; ZnRe and ZnIm are already positiv, so there are no problems
	; start with ZnImSquare, result in R5|R4|R3|R2
	MOV MD0, R2
	MOV MD4, R2
	MOV MD1, R3
	MOV MD5, R3
	; Execution Time
	NOP
	NOP
	NOP
	NOP
	; 
	MOV R2, MD0
	MOV R3, MD1
	MOV R4, MD2
	MOV R5, MD3
	; calc ZnReSquare
	MOV MD0, R0
	MOV MD4, R0
	MOV MD1, R1
	MOV MD5, R1
	; Execution Time
	NOP
	NOP
	NOP
	NOP
	; ZnReSquare-ZnImSquare
	CLR C
	MOV A, MD0
	SUBB A, R2
	MOV R0, A
	MOV A, MD1
	SUBB A, R3
	MOV R1, A
	MOV A, MD2
	SUBB A, R4
	MOV R2, A
	MOV A, MD3
	SUBB A, R5
	MOV R3, A
	; reduce to 16 bit
	CLR C
	MOV A, R3
	RRC A
	MOV R3, A
	MOV A, R2
	RRC A
	MOV R2, A
	MOV A, R1
	RRC A
	MOV R1, A
	CLR C
	MOV A, R3
	RRC A
	MOV R3, A
	MOV A, R2
	RRC A
	MOV R2, A
	MOV A, R1
	RRC A
	MOV R1, A
	CLR C			; clean up
	; Structure output (at the moment ZnIm: R7|R6 and ZnRe: R2|R1)
	MOV A, R1
	MOV R0, A
	MOV A, R2
	MOV R1, A
	MOV A, R6
	MOV R2, A
	MOV A, R7
	MOV R3, A
	RET

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
	ANL A, #111b ; value of the fourth and higher bits are devidable by 8, so they dont ADD up to modulo
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
; use:    None
; output: None
count:
	; increase column counter
	INC 60h
	MOV A, 60h
	; check if end of row is reached
	CJNE A, #PX, count_finshed
	; reset column count
	MOV 60h, #0
	; increse row counter
	INC 61h
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
	; ADD deltaC to C (Re)
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
	; sub deltaC from C (Im)
	CLR C
	MOV A, 72h
	SUBB A, 40h 
	MOV 72h, A
	MOV A, 73h
	SUBB A, 41h
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
	
END