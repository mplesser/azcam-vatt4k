; This table is sent by the SETBIAS command to update clock board values.
; The format is BBBB DDDD DDMM VVVV VVVV VVVV (board, DAC, Mode, Value)

DACS	DC	EDACS-DACS-GENCNT
	DC    (CLK2<<8)+(0<<14)+@CVI((RG_HI+10.0)/20.0*4095)	; RG High 
	DC    (CLK2<<8)+(1<<14)+@CVI((RG_LO+10.0)/20.0*4095)	; RG Low  
	DC    (CLK2<<8)+(2<<14)+@CVI((P1_HI+10.0)/20.0*4095)	; P1 High -- storage
	DC    (CLK2<<8)+(3<<14)+@CVI((P1_LO+10.0)/20.0*4095)	; P1 Low
	DC    (CLK2<<8)+(4<<14)+@CVI((P2_HI+10.0)/20.0*4095)	; P2 High
	DC    (CLK2<<8)+(5<<14)+@CVI((P2_LO+10.0)/20.0*4095)	; P2 Low
	DC    (CLK2<<8)+(6<<14)+@CVI((P3_HI+10.0)/20.0*4095)	; P3 High
	DC    (CLK2<<8)+(7<<14)+@CVI((P3_LO+10.0)/20.0*4095)	; P3 Low
	DC    (CLK2<<8)+(8<<14)+@CVI((S1_HI+10.0)/20.0*4095)	; S1 High -- serials
	DC    (CLK2<<8)+(9<<14)+@CVI((S1_LO+10.0)/20.0*4095)	; S1 Low         
	DC    (CLK2<<8)+(10<<14)+@CVI((S3_HI+10.0)/20.0*4095)	; S3 High       
	DC    (CLK2<<8)+(11<<14)+@CVI((S3_LO+10.0)/20.0*4095)	; S3 Low        
	DC    (CLK2<<8)+(12<<14)+@CVI((S2_HI+10.0)/20.0*4095)	; S2 High      
	DC    (CLK2<<8)+(13<<14)+@CVI((S2_LO+10.0)/20.0*4095)	; S2 Low       
	DC    (CLK2<<8)+(14<<14)+@CVI((Q3_HI+10.0)/20.0*4095)	; Q3 High -- image
	DC    (CLK2<<8)+(15<<14)+@CVI((Q3_LO+10.0)/20.0*4095)	; Q3 Low
	DC    (CLK2<<8)+(16<<14)+@CVI((Q2_HI+10.0)/20.0*4095)	; Q2 High
	DC    (CLK2<<8)+(17<<14)+@CVI((Q2_LO+10.0)/20.0*4095)	; Q2 Low
	DC    (CLK2<<8)+(18<<14)+@CVI((Q1_HI+10.0)/20.0*4095)	; Q1 High
	DC    (CLK2<<8)+(19<<14)+@CVI((Q1_LO+10.0)/20.0*4095)	; Q1 Low
	DC    (CLK2<<8)+(20<<14)+@CVI((SW_HI+10.0)/20.0*4095)	; SW High
	DC    (CLK2<<8)+(21<<14)+@CVI((SW_LO+10.0)/20.0*4095)	; SW Low
	DC    (CLK2<<8)+(22<<14)+@CVI((TG_HI+10.0)/20.0*4095)	; TG High
	DC    (CLK2<<8)+(23<<14)+@CVI((TG_LO+10.0)/20.0*4095)	; TG Low

; Set gain and integrator speed [$board-c3-speed-gain]
;  speed: f => fast, c => slow
;  gain: 77, bb, dd, ee => 1x,2x,5x,10x; [ChanB+ChanA]

; *** not used ***
SPD		EQU	$c00		; slow video proc
GAN		EQU	$ee		; gain 10 video proc

	DC	$0c3000+SPD+GAN
;	DC	$0c3cdd			; x5 Gain, slow integrate, board #0

; Output offset voltages to get around 1000 DN A/D units on a dark frame

	DC	$0c4000+OFFSET0+OFFSET	; Output video offset, Output #0
	DC	$0cc000+OFFSET1+OFFSET	; Output video offset, Output #1

; DC bias voltages

	DC	$0d0000+@CVI((VOD-7.5)/22.5*4095)	; Vod (7.5-30),	pin #1,  VID0
	DC	$0d4000+@CVI((VOD-7.5)/22.5*4095)	; Vod (7.5-30), pin #2,  VID0
	DC	$0d8000+@CVI((VRD-5.0)/15.0*4095)	; Vrd (5-20),	pin #3,  VID0
	DC	$0e0000+@CVI((B5-5.0)/15.0*4095)	; B5  (5-20),	pin #5,  VID0
	DC	$0f0000+@CVI((B7+5.0)/10.0*4095)	; B7  (-5-+5),	pin #9,  VID0
	DC	$0f8000+@CVI((VOG+10.0)/20.0*4095)	; Vog (-10-+10),pin #11, VID0
	DC	$0fc000+@CVI((VOG+10.0)/20.0*4095)	; Vog (-10-+10),pin #12, VID0
EDACS