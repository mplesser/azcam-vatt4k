; *******************************************************************
; tim2.asm for Gen 2

; DSP source code for reading out a CCD
; This is AzCam code, a combination of ARC V1.7 code combined the ICE readout routines.
; last change 22Feb04 MPL

	PAGE    132     ; Printronix page width - 132 columns

; Define a section name so it doesn't conflict with other application programs
	SECTION	TIM

; Include a header file that defines common application and boot code parameters
	INCLUDE "tim2_hdr.asm"

; Define the application number and controller configuration bits
APL_NUM	EQU	0	; Application number from 0 to 3
CC	EQU	CCDVIDREV3B+TIMREV4+UTILREV3

; *******************************************************************
; Put code in external SRAM, starting at P:$200.
	IF	@SCP("DOWNLOAD","HOST")
	ORG	P:$200,P:$200	; Download address
	ELSE
	ORG	P:$200,P:APL_NUM*N_W_APL+APL_LEN ; EEPROM address
	ENDIF

; *******************************************************************
; Fast clear of CCD, executed as a command
CLEAR	JSR	<CLR_CCD
	JMP     <FINISH

CLR_CCD						; this block is ICE version
	MOVE	Y:<ACLEAR0,R0
	JSR	<CLOCK
	MOVE	Y:<AFPXFER0,R0
	JSR	<CLOCK
      MOVE    #<NPCLEAR,R0			; flush all rows
      JSR     <PQSKIP
	MOVE	Y:<AFPXFER2,R0
	JSR	<CLOCK
      MOVE    #<NSCLEAR,R0			; flush serial register
	JSR	<FSSKIP
	MOVE	Y:<ACLEAR2,R0
	JSR	<CLOCK

	MOVE	#TST_RCV,X0				; Wait for commands during exposure
	MOVE	X0,X:<IDL_ADR			; instead of idling
	RTS

; *******************************************************************
; Keep the CCD idling when not reading out
IDLE
	MOVE	Y:<AFPXFER0,R0			; setup for fast par flush
	JSR	<CLOCK
	MOVE    #<IDLEONE,R0			; shift one line
      JSR     <PQSKIP
	JCS     <CHK_SSI				; Go process header and command
	MOVE	Y:<AFPXFER2,R0			; end fast par flush
	JSR	<CLOCK
      MOVE    #<NSCLEAR,R0			; flush serial register
	JSR	<FSSKIP

	JMP     <IDLE				; repeat this loop

; Include generic routines
	INCLUDE "tim2_common.asm"

;************************************************************************
;												*
;    Permanent address register assignments					*
;	 R1 - Address of SSI receiver contents					*
;	 R2 - Address of SCI receiver contents					*
;      R3 - Pointer to current top of command buffer                    *
;      R4 - Pointer to processed contents of command buffer			*
;      R5 - Temporary register for processing SSI and SCI contents	*
;      R6 - CCD clock driver address for CCD #0 = $FF80			*
;           It is also the A/D address of analog board #0			*
;												*
;    Other registers									*
;      R0, R7 - Temporary registers used all over the place			*
;      R5 - Can be used as a temporary register but is circular,		*
;           modulo 32									*
;************************************************************************

; Specify execution and load addresses (internal RAM MPL)
	IF	@SCP("DOWNLOAD","HOST")
	ORG	P:APL_ADR,P:APL_ADR			; Download address
	ELSE
	ORG     P:APL_ADR,P:APL_NUM*N_W_APL		; EEPROM address
	ENDIF

; ***********************************************************************
; Include CCD readout routines
	INCLUDE "tim2_rdccd.asm"

; Check for program overflow
        IF	@CVS(N,*)>$200
        WARN    'Application P: program is too large!'	; Make sure program
	  ENDIF								; will not overflow

; ***********  DATA AREAS - READOUT PARAMETERS AND WAVEFORMS  ************

; Command table - make sure there are exactly 32 entries in it
	IF	@SCP("DOWNLOAD","HOST")
	ORG	X:COM_TBL,X:COM_TBL			; Download address
	ELSE			
        ORG     P:COM_TBL,P:APL_NUM*N_W_APL+APL_LEN+MISC_LEN ; EEPROM address
	ENDIF

	DC	'IDL',IDL				; Put CCD in IDLE mode    
	DC	'STP',STP				; Exit IDLE mode
	DC	'SBV',SETBIAS 			; Set DC bias supply voltages  
	DC	'RDC',RDCCD 			; Begin CCD readout    
	DC	'CLR',CLEAR  			; Fast clear the CCD   
	DC	'SGN',ST_GAIN  			; Set video processor gain     
	DC	'SDC',SET_DC			; Set DC coupled diagnostic mode
	DC	'SBN',SET_BIAS_NUMBER		; Set bias number
	DC	'SMX',SET_MUX			; Set clock driver MUX outputs
	DC	'CSW',CLR_SWS			; Clear analog switches to reduce power drain
	DC	'RCC',READ_CONTROLLER_CONFIGURATION	; Read controller configuration
;	DC	'SOS',SEL_OS			; Select Output Source
;	DC	'SSS',SET_SUBARRAY_SIZES	; Set ROI sizes
;	DC	'SSP',SET_SUBARRAY_POSITIONS	; Set ROI positions

	DC	'OSH',OPEN_SHUTTER		; Open shutter
	DC	'CSH',CLOSE_SHUTTER		; Close shutter

	DC    'PON',PWR_ON			; Turn on all camera biases and clocks
	DC    'POF',PWR_OFF			; Turn +/- 15V power supplies off

	DC	'SET',SET_EXP_TIME 		; Set exposure time
	DC	'RET',RD_EXP_TIME 		; Read elapsed exposure time

	DC	'SEX',START_EXPOSURE		; Start exposure, immediate return
	DC	0,START				; unused
	DC	'PEX',PAUSE_EXPOSURE		; Pause exposure
	DC	'REX',RESUME_EXPOSURE		; Resume a paused exposure
	DC	'AEX',ABORT_EXPOSURE		; Abort a paused exposure

	DC	'FPX',FOR_PSHIFT		; Forward parallel shift
	DC	'RPX',REV_PSHIFT		; Reverse parallel shift

	DC	'DON',START				; Nothing special
	DC	0,START,0,START			; unused
	DC	0,START				; unused

; Include the waveform table at Y:0

	IF	@SCP("DOWNLOAD","HOST")
	ORG	Y:0,Y:0		; Download address
	ELSE
	ORG     Y:0,P:		; EEPROM address continues from P: above
	ENDIF

; ***********************************************************************
; Include waveform files
	INCLUDE "waveforms.asm"	; readout waveforms

	ENDSEC			; End of section TIM

;  End of program
	END
