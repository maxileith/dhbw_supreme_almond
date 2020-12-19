$NOMOD51
#include <Reg517a.inc>

; Zuordnung:
; R0 - ZnRe Low-Byte
; R1 - ZnRe High-Byte
; R2 - ZnIm Low-Byte
; R3 - ZnIm High-Byte
; R5 - n für Modulo
; R6 - k für Spalte
; R7 - Auszugebendes Zeichen

pointAReH EQU 245 ; #111101$01b
pointAReL EQU 0
	
pointAImH EQU 250 ; #111110$10b
pointAImL EQU 0   ; #00000000b

pointBReH EQU 3 ; #000000$11b
pointBReL EQU 0 ; #00000000b
	
pointBImH EQU 6   ; #000001$10b
pointBImL EQU 0   ; #00000000b

PX EQU 20
NMax EQU 20
	
;ORG 00h
;	JMP init	; jump to start of program
	
;ORG 1000h

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
	
	; LJMP calcDeltaC
	
	MOV R7, #11010110


; input:  R7 = n
; use:    
; output: R7 = char
calcChar:
	CJNE R7, #NMax, calcCharMod8 ; Jump to calcCharMod8 if n != NMax
	MOV R7, #32d ; if n = NMax -> char = ' '
	LJMP output
calcCharMod8:
	MOV A, R7
	ANL A, #111b ; value of the fourth and higher bits are devidable by 8, so they dont add up to modulo
	;ADD A, @PC
	;JMP @A
	LJMP calcCharMod8eq0
	LJMP calcCharMod8eq1
	LJMP calcCharMod8eq2
	LJMP calcCharMod8eq3
	LJMP calcCharMod8eq4
	LJMP calcCharMod8eq5
	LJMP calcCharMod8eq6
	LJMP calcCharMod8eq7
calcCharMod8eq0:
	MOV R7, #164d
	LJMP output
calcCharMod8eq1:
	MOV R7, #43d
	LJMP output
calcCharMod8eq2:
	MOV R7, #169d
	LJMP output
calcCharMod8eq3:
	MOV R7, #45d
	LJMP output
calcCharMod8eq4:
	MOV R7, #42d
	LJMP output
calcCharMod8eq5:
	MOV R7, #64d
	LJMP output
calcCharMod8eq6:
	MOV R7, #183d
	LJMP output
calcCharMod8eq7:
	MOV R7, #174d
	LJMP output


; input:  R7 = char
; use:    None
; output: None
output:
	; output of R7 via COM 0
	MOV S0BUF, R7
output_wait:
	; check if sent
	MOV A, S0CON
	JNB ACC.1, output_wait
	ANL S0CON, #0FDh
	LJMP output
	

	
; calc delta C
calcDeltaC:
	mov A, pointBReL
	subb A, pointAReL
	mov R0, A
	mov A, pointBReH
	subb A, pointAReH
	mov R1, A
	clr C		; Clear carry f�r n�chste Berechnung
	mov A, PX	; Da PX maximal 111 betr�gt, gen�gen 8Bit und es wird keine weitere Logik ben�tigt
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
	
; input:  Zn in R0 = ZnReL
;         R1 = ZnReH
;         R2 = ZnImL
;         R3 = ZnImH
; use:    R0-7
; output: None
checkZnQuadrat:
	; calc TnImQuadrat
	mov MD0, R2
	mov MD4, R2
	mov MD1, R3
	mov MD5, R3
	;Execution Time
	nop
	nop
	nop
	nop
	; safe ZnImQuadrat
	mov R4, MD0
	mov R5, MD1
	mov R6, MD2
	mov R7, MD3
	; calc ZnReQuadrat
	mov MD0, R0
	mov MD4, R0
	mov MD1, R1
	mov MD5, R1
	; Execution Time
	nop
	nop
	nop
	nop
	; calc ZnQuadrat
	mov A, MD0
	subb A, R4
	mov R0, A
	mov A, MD1
	subb A, R5
	mov R1, A
	mov A, MD2
	subb A, R6
	mov R2, A
	mov A, MD3
	subb A, R7
	mov R3, A
	; result in R0 (low) - R3 (high)
;	jb ACC.0, ; negativ result
;	cjne A, #0, endCalc ; result > 4
;	mov A, R2
;	clr C
;	subb A, #4
;	jnb C, endCalc ; result >= 4
;	jmp nextCalc
	
	
	
	






end
