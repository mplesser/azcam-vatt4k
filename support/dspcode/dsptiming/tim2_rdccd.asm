; *******************************************************************
; rdccd.asm for Gen 2
; Readout routines for CCD clocking
; last change 09Sep07 MPL

; *******************************************************************

; Main loop, transfer and read rows
RDCCD
	BSET	#ST_RDC,X:<STATUS 	; Set status to reading out
	JSR	<PCI_READ_IMAGE		; Get the PCI board reading the image

	BSET	#WW,X:PBD			; Set WW = 1 for 16-bit image data
	JSET	#TST_IMG,X:STATUS,SYNTHETIC_IMAGE

; comment next lines to save P: memory
;	MOVE	Y:<AREAD0,R0		; read mode setup
;	JSR	<CLOCK

	MOVE	Y:<AFPXFER0,R0		; fast par transfer setup
	JSR	<CLOCK

	MOVE  #<FRAMET,R0		; frame transfer
	JSR   <PQSKIP
	JCS	<START

	MOVE  #<NPPRESKIP,R0		; skip to underscan
	JSR   <PSKIP
	JCS	<START
	MOVE	Y:<AFPXFER2,R0		; end fast par transfer
	JSR	<CLOCK
	MOVE  #<NSCLEAR,R0		; flush
	JSR	<FSSKIP

	MOVE  #<NPUNDERSCAN,R0		; read underscan
	JSR   <PDATA
	JCS	<START

	MOVE	Y:<AFPXFER0,R0		; fast par transfer setup
	JSR	<CLOCK
	MOVE  #<NPSKIP,R0		; skip to ROI
	JSR   <PSKIP
	JCS	<START
	MOVE	Y:<AFPXFER2,R0		; end fast par transfer
	JSR	<CLOCK
	MOVE  #<NSCLEAR,R0		; flush
	JSR	<FSSKIP

	MOVE  #<NPDATA,R0		; read ROI
	JSR   <PDATA
	JCS	<START

; 13jul06 MPL added to finish if no overscan rows
;	MOVE  #<NPOVERSCAN,A
;	TST	A
;	JLE	<RDC_END

;	MOVE	Y:<AFPXFER0,R0		; fast par transfer setup
;	JSR	<CLOCK
;	MOVE  #<NPPOSTSKIP,R0		; skip to overscan
;	JSR   <PSKIP
;	JCS	<START
;	MOVE	Y:<AFPXFER2,R0		; end fast par transfer
;	JSR	<CLOCK
;	MOVE  #<NSCLEAR,R0		; flush
;	JSR	<FSSKIP

;	MOVE  #<NPOVERSCAN,R0		; read overscan
;	JSR   <PDATA
;	JCS	<START

;	MOVE	Y:<AREAD8,R0		; end read mode
;	JSR	<CLOCK

RDC_END
	JCLR	#IDLMODE,X:<STATUS,RDC_E ; Don't idle after readout
	MOVE	#IDLE,X0
	MOVE	X0,X:<IDL_ADR
RDC_E
	BCLR  #WW,X:PBD			; Clear WW to 0 for 24-bit commands
	BCLR  #ST_RDC,X:<STATUS		; Set status to not reading out
	JMP   <START			; Wait for a new command

; *******************************************************************
PDATA
	JSR	<CNPAMPS			; compensate for split register
	JLE	<PDATA0
	DO	A,PDATA0			; loop through # of binned rows into each serial register
	MOVE	#<NPBIN,R0			; shift NPBIN rows into serial register
	JSR	<PDSKIP
	JCC	<PDATA1
	ENDDO
	JMP	<PDATA0
PDATA1
	MOVE	#<NSPRESKIP,R0		; skip to serial underscan
	JSR	<SSKIP
	MOVE	#<NSUNDERSCAN,R0		; read underscan
	JSR	<SDATA
	MOVE	#<NSSKIP,R0			; skip to ROI
	JSR	<SSKIP
	MOVE	#<NSDATA,R0			; read ROI
	JSR	<SDATA
	MOVE	#<NSPOSTSKIP,R0		; skip to serial overscan
	JSR	<SSKIP
	MOVE	#<NSOVERSCAN,R0		; read overscan 
	JSR	<SDATA
	BCLR	#0,SR				; set CC
	NOP
	NOP
	NOP
PDATA0
	RTS

; *******************************************************************
PDSKIP
	MOVE	Y:(R0),A			; shift data lines into serial reg
	TST	A
	JLE	<PDSKIP0
	DO	Y:(R0),PDSKIP0
	MOVE	Y:<APDXFER,R0
	JSR	<PCLOCK
	JSR	<GET_RCV
	JCC	<PDSKIP1
	ENDDO
PDSKIP1
	NOP
PDSKIP0
	RTS

; *******************************************************************
PSKIP
	JSR	<CNPAMPS
	JLE	<PSKIP0
	DO	A,PSKIP0
	MOVE	Y:<APXFER,R0
	JSR	<PCLOCK
	JSR	<GET_RCV
	JCC	<PSKIP1
	ENDDO
PSKIP1
	NOP
PSKIP0
	RTS

; *******************************************************************
PQSKIP
	JSR	<CNPAMPS
	JLE	<PQSKIP0
	DO	A,PQSKIP0
	MOVE	Y:<APQXFER,R0
	JSR	<PCLOCK
	JSR	<GET_RCV
	JCC	<PQSKIP1
	ENDDO
PQSKIP1
	NOP
PQSKIP0
	RTS

; *******************************************************************
RSKIP
	JSR	<CNPAMPS
	JLE	<RSKIP0
	DO	A,RSKIP0
	MOVE	Y:<ARXFER,R0
	JSR	<PCLOCK
	JSR	<GET_RCV
	JCC	<RSKIP1
	ENDDO
RSKIP1
	NOP
RSKIP0
	RTS

; *******************************************************************
FSSKIP
	JSR	<CNSAMPS
	JLE	<FSSKIP0
	DO	A,FSSKIP0
	MOVE	Y:<AFSXFER,R0
	JSR	<CLOCK
	NOP
FSSKIP0
	RTS

; *******************************************************************
SSKIP
	JSR	<CNSAMPS
	JLE	<SSKIP0
	DO	A,SSKIP0
	MOVE	Y:<ASXFER0,R0
	JSR	<CLOCK
	MOVE	Y:<ASXFER2,R0
	JSR	<CLOCK
	NOP
SSKIP0
	RTS

; *******************************************************************
SDATA
	JSR	<CNSAMPS
	JLE	<SDATA0
	DO	A,SDATA0
	MOVE	Y:<ASXFER0,R0
	JSR	<CLOCK
	MOVE	X:<ONE,X0				; Get bin-1
	MOVE	Y:<NSBIN,A
	SUB	X0,A
	JLE	<SDATA1
	DO	A,SDATA1
	MOVE	Y:<ASXFER1,R0
	JSR	<CLOCK
	NOP
SDATA1
	MOVE	Y:<ASXFER2D,R0	; clock the data
	JSR	<CLOCK

;	CLR	A
;	MOVEP	A,Y:WRFO		; MPL special test	

;	MOVE Y:$FFA0,A		; read ADC 0/0
;	MOVEP	A,Y:WRFO		; write to fiber	

SDATA0T
	NOP
SDATA0
	RTS

; *******************************************************************
FOR_PSHIFT
	MOVE	#<NPXSHIFT,R0
	JSR	<PSKIP
	JMP	<FINISH

; *******************************************************************
REV_PSHIFT
	MOVE	#<NPXSHIFT,R0
	JSR	<RSKIP
	JMP	<FINISH

; *******************************************************************
; Compensate for split serial
CNSAMPS	MOVE	Y:(R0),A			; get num pixels to read
	JCLR	#0,Y:<NSAMPS,CNSAMP1		; split register?
	ASR	A					; yes, divide by 2
CNSAMP1	TST	A
	RTS

; *******************************************************************
; Compensate for split parallel
CNPAMPS	MOVE	Y:(R0),A			; get num rows to shift
	JCLR	#0,Y:<NPAMPS,CNPAMP1		; split parallels?
	ASR	A					; yes, divide by 2
CNPAMP1	TST	A				
	BCLR	#0,SR					; clear carry ???
	RTS

; *******************************************************************
; Core subroutine for clocking out CCD charge
CLOCK   MOVE    Y:(R0)+,X0			; # of waveform entries 
        MOVE    Y:(R0)+,A			; Start the pipeline
        DO      X0,CLK1				; Repeat X0 times
        MOVE    A,X:(R6) Y:(R0)+,A		; Send out the waveform
CLK1
        MOVE    A,X:(R6)			; Flush out the pipeline
        RTS						; Return from subroutine

; *******************************************************************
;  Slow clock for parallel shifts
PCLOCK
	MOVE	Y:(R0)+,A	; # of waveform entries
	MOVE	X:<ONE,X0	; Add 1 - no pipeline prime
	ADD	X0,A
	DO	A,PCLK1
	MOVE	Y:(R0)+,A	; Get the waveform
	DO	Y:<PMULT,PCLK2
	MOVE	A,X:(R6)	; Send out the waveform
PCLK2
	NOP
PCLK1
        RTS                     ; Return from subroutine

