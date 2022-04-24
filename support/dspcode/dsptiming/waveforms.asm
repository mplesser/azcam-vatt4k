; waveforms.asm for Vatt4k - STA0500a - Gen2
; 16Aug17 MPL last change

; video proc gain=2 (~1.75 e/DN)

; *** boards ***
VIDEO		EQU	$000000	; Video processor board (all are addressed together)
CLK2		EQU	$002000	; Clock driver board select = board 2 low bank 
CLK3		EQU	$003000	; Clock driver board select = board 2 high bank

;***  timing ***
P_DEL2		EQU	6000		; P clock delay nsec (80-20,400 ns inc 160)
S_DEL2		EQU	200		; S clock delay nsec (80-2,620 ns inc 20)	200
V_DEL2		EQU	400		; VP delay nsec (80-2620 ns inc 20)		600
DWEL		EQU	1500		; 1500 sample time  (80-20400 ns inc 160)		3000
PARMULT		EQU	40		; P_DELAY multiplier
GENCNT		EQU	2		; Gen clock counter (2 for gen1/2, 1 for gen3)

; *** not used ***
SPD		EQU	$c00		; slow video proc
GAN		EQU	$ee		; gain 10 video proc

; *** video channels ***
;  split serial read
SXMIT	EQU     $00F020	; Series transmit A/D channels #0 to #1

; *** clock rails ***
RG_HI		EQU	 +8.0	; Reset Gate
RG_LO		EQU	 -2.0
S_HI		EQU	 +5.0	; Serial clocks
S_LO		EQU	 -5.0
SW_HI		EQU	 +4.0	; Summing well
SW_LO		EQU	 -4.0
P_HI		EQU	 +3.0	; Parallel clocks  3
P_LO		EQU	 -7.0
P3_HI		EQU	 +4.5	; 1.5 Parallel 3 clock
P3_LO		EQU	 -7.5
TG_HI		EQU	 +2.0	; 1.5 transfer gate
TG_LO		EQU	 -2.0

; *** bias voltages ***
VOD		EQU	+25.0	; Output Drains - 25.0
VRD		EQU	+15.0	; Reset Drain - 15.0
VOG		EQU	 -1.0	; Output Gate - -1.0
B5		EQU	  0.0	; not used
B7		EQU	  0.0	; not used

; *** video output offset ***
; higher value here lowers output value (~4.8 DN change/unit change here)
; for gain 2
OFFSET	EQU	2100	; global offset to all channels
OFFSET0	EQU	0	; offsets for channel 0
OFFSET1	EQU	26	; offsets for channel 1

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

; *** include files and routines ***
	INCLUDE "includes.asm"

; *** default clock states ***
SDEF		EQU	S1L+S2H+S3L+RGL	        ; during parallel shifting
PDEF		EQU	P1H+P2H+P3L		; during serial shifting
QDEF		EQU	Q1H+Q2H+Q3L		; not used
PQDEF		EQU	PDEF+QDEF		; during serial shifting

; *** parallel shifting of storage only ***
PXFER		DC	EPXFER-PXFER-GENCNT
	INCLUDE "parallels.asm"
EPXFER

; *** parallel shifting of entire device ***
PQXFER	EQU	PXFER
RXFER       EQU   PXFER ; not used

; *** serial shifting ***
	INCLUDE "s_2_231w.asm"
;	INCLUDE "s_2_321w.asm"

; ******** END OF WAVEFORM.ASM **********
