$NOMOD51
#include <Reg517a.inc>

; Zuordnung:
; R0 - ZnRe Low-Byte
; R1 - ZnRe High-Byte
; R2 - ZnIm Low-Byte
; R3 - ZnIm High-Byte
; R7 - Auszugebendes Zeichen
pointAReH EQU 245 ; #111101$01b
pointAReL EQU 0
	
pointAImH EQU 250; #111110$10b
pointAImL EQU 0; #00000000b

pointBReH EQU 5 ; #000000$11b
pointBReL EQU 0 ; #00000000b
	
pointBImH EQU 6; #000001$10b
pointBImL EQU 0 ; #00000000b

PX EQU 20
NMax EQU 20
	
ORG 00h
	JMP init	; jump to start of program
	
ORG 1000h

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
	
	; MOV A, #10010000b ; allow serial interrupt 0
	; MOV 0A8h, A
	
	MOV R7, #164d

; serial output
output:
	; output of R7 via COM 0
	MOV S0BUF, R7
output_wait:
	; check if sent
	MOV A, S0CON
	JNB ACC.1, output_wait
	ANL S0CON, #0FDh
	LJMP calc
	
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
	;Berechnung von Delta c mit MDU
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
	
	
	
checkZnQuadrat:
	mov MD0, R0
	mov MD4, R0
	mov MD1, R1
	mov MD5, R1
	;Execution Time
	nop
	nop
	nop
	nop
	;
	






end
