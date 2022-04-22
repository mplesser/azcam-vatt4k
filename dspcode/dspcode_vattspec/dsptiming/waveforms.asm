; waveforms.asm for vattspec
; STA0520A CCD
; Gen2 controller
; 08Sep10 MPL last change

; *** boards ***
VIDEO		EQU	$000000	; Video processor board (all are addressed together)
CLK2		EQU	$002000	; Clock driver board select = board 2 low bank 
CLK3		EQU	$003000	; Clock driver board select = board 2 high bank

;***  timing ***
P_DEL2		EQU	5000		; P clock delay nsec (80-20,400 ns inc 160)
S_DEL2		EQU	120		; S clock delay nsec (80-2,620 ns inc 20)
V_DEL2		EQU	80		; VP delay nsec (80-2620 ns inc 20)
DWEL		EQU	2000		; sample time  (80-20400 ns inc 160)
PARMULT		EQU	5		; P_DELAY multiplier
GENCNT		EQU	2		; Gen clock counter (2 for gen1/2, 1 for gen3)


; *** clock rails ***
RG_HI		EQU	 +8.0	; Reset Gate
RG_LO		EQU	 -2.0
S_HI		EQU	 +4.0	; Serial clocks
S_LO		EQU	 -4.0
SW_HI		EQU	 +4.0	; Summing well
SW_LO		EQU	 -4.0
P_HI		EQU	 +1.0	; Parallel clocks 
P_LO		EQU	 -8.0
P3_HI		EQU	 +2.0	; Parallel 3 clock
P3_LO		EQU	 -6.0
TG_HI		EQU	 +0.0	; not used
TG_LO		EQU	 +0.0	; not used

; *** bias voltages ***
VOD		EQU	+25.0	; Output Drains
VRD		EQU	+15.0	; Reset Drain
VOG		EQU	 -1.0	; Output Gate
B5		EQU	  0.0	; not used
B7		EQU	  0.0	; not used

; *** video output offset ***
; higher value here lowers output value (~4.8 DN change/unit change here)
OFFSET	EQU	2300	; global offset to all channels
OFFSET0	EQU	0	; offsets for channel 0
OFFSET1	EQU	0	; offsets for channel 1

; *** aliases ***
S1_HI		EQU	S_HI
S1_LO		EQU	S_LO
S2_HI		EQU	S_HI
S2_LO		EQU	S_LO
S3_HI		EQU	S_HI
S3_LO		EQU	S_LO
P1_HI		EQU	P_HI
P1_LO		EQU	P_LO	
P2_HI		EQU	P_HI
P2_LO		EQU	P_LO	
Q1_HI		EQU	P_HI
Q1_LO		EQU	P_LO	
Q2_HI		EQU	P_HI
Q2_LO		EQU	P_LO
Q3_HI		EQU	P3_HI
Q3_LO		EQU	P3_LO

; video channel 0 direction has some par-ser issues which cause columner structure
; *** video channels ***
;SXMIT	EQU	$00F000	; Transmit A/D = 0
SXMIT	EQU	$00F021	; Transmit A/D = 1

;SXMIT		EQU	$00F020	; Transmit A/D channels #0 to #1

; *** include files and routines ***
	INCLUDE "includes.asm"

; *** default clock states ***
SDEF		EQU	S1L+S2H+S3L+RGL
PQDEF		EQU	P1H+P2H+P3L+Q1H+Q2H+Q3L
;PQDEF		EQU	P1L+P2H+P3L+Q1L+Q2H+Q3L

; parallels_for with chan 0
; parallels_rev with chan 1

; *** parallel shifting  ***
PXFER		DC	EPXFER-PXFER-GENCNT
	INCLUDE "parallels_rev.asm"
;	INCLUDE "parallels_for.asm"
EPXFER

PQXFER	EQU	PXFER
RXFER	EQU	PXFER 

; *** serial shifting ***
	INCLUDE "s_2_321w.asm"

; ******** END OF WAVEFORM.ASM **********
