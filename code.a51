$NOMOD51
#include <Reg517a.inc>

; Zuordnung:
; R0 - Delta c Low-Byte
; R1 - Delta c High-Byte
; R7 - Auszugebendes Zeichen
pointAReH EQU #111101$01b
pointAReL EQU #00000000b
	
pointAImH EQU #111110$10b
pointAImL EQU #00000000b

pointBReH EQU #000000$11b
pointBReL EQU #00000000b
	
pointBImH EQU #000001$10b
pointBImL EQU #00000000b

PX EQU #20
NMax EQU #20
	
ORG 00h
	JMP init	; Sprung zum Programmanfang 
	
ORG 23h
	JMP maxiMachtDas

ORG 1000h
	
init:			; Programmbeginn
	; SMOD = 1
	; PCON --> 10000000b
	; doubles the baud rate
	MOV PCON, #10000000b
	
	; COM1
	; SM0 = 0
	; SM1 = 1
	; S0CON --> 01000000b f�r Mode 1
	MOV S0CON, #01000000b ;
	; BD (Baudrate generator enabled) = 1
	; ADCON0 --> 10000000b
	MOV ADCON0, #10000000b
	; 28800 Baudrate --> SMOD = 1 & S0RELH|S0RELL = 3E6h
	MOV S0RELH, #03h
	MOV S0RELL, #0E6h
	
	MOV A, #10010000b ; Serial Port 0 Interrupt erlauben
	MOV 0A8h, A
	
output:
	










berechneDeltaC:
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
	

end
