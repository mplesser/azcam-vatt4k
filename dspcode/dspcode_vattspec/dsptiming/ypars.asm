; Values in this block start at Y:0 and are overwritten by AzCamTool 
; with WRM commands.  They are not overwritten by waveform tables.
; All values are unbinned pixels unless noted.

CAMSTAT		DC	0	; not used
NSDATA		DC	1	; number BINNED serial columns in ROI
NPDATA		DC	1	; number of BINNED parallel rows in ROI
NSBIN		DC	1	; Serial binning parameter (>= 1)
NPBIN		DC	1	; Parallel binning parameter (>= 1)

NSAMPS		DC	0	; 0 => 1 amp, 1 => split serials
NPAMPS		DC	0	; 0 => 1 amp, 1 => split parallels
NSCLEAR		DC	1	; number of columns to clear during flush				
NPCLEAR		DC	1	; number of rows to clear during flush

NSPRESKIP	DC	0	; number of cols to skip before underscan
NSUNDERSCAN	DC	0	; number of BINNED columns in underscan
NSSKIP		DC	0	; number of cols to skip between underscan and data
NSPOSTSKIP	DC	0	; number of cols to skip between data and overscan
NSOVERSCAN	DC	0	; number of BINNED columns in overscan

NPPRESKIP	DC	0	; number of rows to skip before underscan
NPUNDERSCAN	DC	0	; number of BINNED rows in underscan
NPSKIP		DC	0	; number of rows to skip between underscan and data
NPPOSTSKIP	DC	0	; number of rows to skip between data and overscan
NPOVERSCAN	DC	0	; number of BINNED rows in overscan

NPXSHIFT	DC	0	; number of rows to parallel shift
TESTDATA	DC	0	; 0 => normal, 1 => send incremented fake data
FRAMET		DC	0	; number of storage rows for frame transfer shift
PREFLASH	DC	0	; not used 
GAIN		DC	0	; Video proc gain and integrator speed stored here
TST_DAT		DC	0	; Place for synthetic test image pixel data
SH_DEL		DC	100	; Delay (msecs) between shutter closing and image readout
CONFIG		DC	CC	; Controller configuration
NSIMAGE		DC	1	; total number of columns in image
NPIMAGE		DC	1	; total number of rows in image
PAD3		DC	0	; unused
PAD4		DC	0	; unused
IDLEONE		DC	2	; lines to shift in IDLE (really 1)

; Values in this block start at Y:20 and are overwritten if waveform table
; is downloaded
PMULT		DC	PARMULT	; parallel clock multiplier
ACLEAR0		DC	TNOP	; Clear prologue - NOT USED
ACLEAR2		DC	TNOP	; Clear epilogue - NOT USED
AREAD0		DC	TNOP	; Read prologue - NOT USED
AREAD8		DC	TNOP	; Read epilogue - NOT USED
AFPXFER0	DC	FPXFER0	; Fast parallel transfer prologue
AFPXFER2	DC	FPXFER2	; Fast parallel transfer epilogue
APXFER		DC	PXFER	; Parallel transfer - storage only
APDXFER		DC	PXFER	; Parallel transfer (data) - storage only
APQXFER		DC	PQXFER	; Parallel transfer - storage and image
ARXFER		DC	RXFER	; Reverse parallel transfer (for focus)
AFSXFER		DC	FSXFER	; Fast serial transfer
ASXFER0		DC	SXFER0	; Serial transfer prologue
ASXFER1		DC	SXFER1	; Serial transfer ( * colbin-1 )
ASXFER2		DC	SXFER2	; Serial transfer epilogue - no data
ASXFER2D	DC	SXFER2D	; Serial transfer epilogue - data
ADACS		DC	DACS
