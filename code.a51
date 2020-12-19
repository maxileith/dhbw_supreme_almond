$NOMOD51
#include <Reg517a.inc>

pointAReH EQU #111101$10b
pointAReL EQU #00000000b
	
pointAImH EQU #111110$01b
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
	; S0CON --> 01000000b für Mode 1
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
	mov A, pointBRe
	subb A, pointARe
	

end
