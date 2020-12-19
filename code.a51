#
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










berechneDeltaC:
	mov A, pointBReL
	subb A, pointAReL
	mov R0, A
	mov A, pointBReH
	subb A, pointAReH
	mov R1, A
	clr C		; Clear carry für nächste Berechnung
	mov A, PX	; Da PX maximal 111 beträgt, genügen 8Bit und es wird keine weitere Logik benötigt
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
