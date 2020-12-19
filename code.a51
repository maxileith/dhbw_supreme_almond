#
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










berechneDeltaC:
	mov A, pointBRe
	subb A, pointARe
	

end
