; *** DSP Y memory parameter table - downloaded by AzCamTool ***
	INCLUDE "Ypars.asm"

; *** clock state bits ***
	INCLUDE "SwitchStates.asm"

; *** bias voltage table ***
	INCLUDE "DACS.asm"

; *** shorthand for waveforms ***
S_DELAY	EQU	@CVI((S_DEL2-80)/20)<<16
V_DELAY	EQU	@CVI((V_DEL2-80)/20)<<16
P_DELAY	EQU	(1<<23)+(@CVI((P_DEL2-80)/160)<<16)
DWELL		EQU	(1<<23)+(@CVI((DWEL-80)/160)<<16)

; *** timing NOP ***
TNOP		DC	ETNOP-TNOP-GENCNT
		DC	$00E000
		DC	$00E000
ETNOP
