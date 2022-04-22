Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 1



1                                  COMMENT *
2      
3                          This file is used to generate DSP code for the PCI interface
4                                  board using a DSP56301 as its main processor.
5      
6                          08Mar04 set AUX1 to 1 for gen1/2 switchable boards
7                          20Aug04 last change MPL
8      
9                          ARC, Inc. comments below....
10     
11                         Version 1.7 -   Replies to commands with polling only, no interrupts
12                                         Number of 16-bit pixels returned to host during image readout
13     
14                         Some Rules -
15                                 Commands executed only by the PCI board end with a jump to FINISH,
16                                         FINISH1 or ERROR, since these will assert the reply flags
17                                         and return from interrupt.
18                                 Commands passed along to the timing board end only with RTI since
19                                         the reply from the timing board will generate its own call
20                                         to FINISH1 or ERROR.
21                                 PCI -> commands are received as 24-bit words, with
22                                 Communication of commands and replies over the PCI bus is all at
23                                         24 bits per word. PCI address that need to be passed are
24                                         split into two 16-bit words.
25     
26                         CHANGES, February to March 2001
27                                 - Get rid of Number of Bytes per pixel in images. Assume 2.
28                                 - Get rid of $80A7 = read image command.
29                                 - Process 'RDA' timing board command to start the readout
30                                 - Jump to error if receiver FIFO is empty on vector commands
31                                 - Replace GET_FO mess with calls to RD_FO
32                                 - Implement a timeout on fiber optic words, called RD_FO_TIMEOUT
33                                 - Number of bytes per image replaces NCOLS x NROWS
34                                 - Interrupt levels set as folllows -
35                                         New vector command locations for more order
36                                         NMI for read PCI image address, reset PCI, abort readout
37                                         IPL = 2 for reset button, FIFO HF, enabled during readout
38                                         IPL = 1 for all host commands
39                                         Host commands disabled during image readout
40                                 - Host flags = 5 if reading out image
41                                 - Commands from the PCI host follow the fiber optic protocol,
42                                         header, command, arg1 - arg4
43                                     with command words written to $10020 and then vector $B1
44                                 - A BUSY host flag was introduced =6 for the case where a command
45                                         takes longer than the voodoo TIMEOUT to execute
46                                 - The non-maskable reboot from EEPROM command = $807B is implemented
47                                 - RDM and WRM were changed to abide by the timing board convention
48                                         of embedding the memory type in the address' most significant
49                                         nibble. This limits memory accesses to 64k on this board.
50                                 - Eliminate Scatter/Gather image processing in favor of direct
51                                         FIFO to PCI bus transfers.
52                         April 25 - Change PCI write handshaking to MARQ and MDT, eliminating the
53                                         special writing of 8 pixels at the beginning of each image.
54     
55                         Version 1.7 as follows:
56                                 - Slaved READ IMAGE to the controller for the number of pixels
57                                         to be read, not just the starting time.
58                                 - Introduced the 'IIA' = Initialize Image Address command sent by
59                                         the timing board as a reply to the 'SEX' command to set
60                                         PCI_ADDR = BASE_ADDR at the start of an image instead of
61                                         having the host computer issue it.
62                                 - Took out the WRITE_NUMBER_OF_BYTES_IN_IMAGE and
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 2



63                                         INITIALIZE_NUMBER_OF_PIXELS command because the
64                                         timing board now does this.
65                                 - Introduced the local variable X:<HOST_FLAG that is set to
66                                         the value of the DCTR register bits 5,4,3 to inform
67                                         this program what state the controller is in.
68                                 - Separately process commands from the controller to the PCI board,
69                                         distinguished by Destination = 1. Host commands or replies
70                                         have Destination = 0.
71                                 - Introduced RDI = 'Reading Image ON' and RDO = 'Reading Image Off'
72                                         commands from the timing board to set host flags indicating
73                                         that the controller is readout out.
74                                 *
75                                   PAGE    132                               ; Printronix page width - 132 columns
76     
77                         ; Equates to define the X: memory tables
78        000000           VAR_TBL   EQU     0                                 ; Variables and constants table
79        000030           ARG_TBL   EQU     $30                               ; Command arguments and addresses
80     
81                         ; Various addressing control registers
82        FFFFFB           BCR       EQU     $FFFFFB                           ; Bus Control Register
83        FFFFFA           DCR       EQU     $FFFFFA                           ; DRAM Control Register
84        FFFFF9           AAR0      EQU     $FFFFF9                           ; Address Attribute Register, channel 0
85        FFFFF8           AAR1      EQU     $FFFFF8                           ; Address Attribute Register, channel 1
86        FFFFF7           AAR2      EQU     $FFFFF7                           ; Address Attribute Register, channel 2
87        FFFFF6           AAR3      EQU     $FFFFF6                           ; Address Attribute Register, channel 3
88        FFFFFD           PCTL      EQU     $FFFFFD                           ; PLL control register
89        FFFFFE           IPRP      EQU     $FFFFFE                           ; Interrupt Priority register - Peripheral
90        FFFFFF           IPRC      EQU     $FFFFFF                           ; Interrupt Priority register - Core
91     
92                         ; PCI control register
93        FFFFCD           DTXS      EQU     $FFFFCD                           ; DSP Slave transmit data FIFO
94        FFFFCC           DTXM      EQU     $FFFFCC                           ; DSP Master transmit data FIFO
95        FFFFCB           DRXR      EQU     $FFFFCB                           ; DSP Receive data FIFO
96        FFFFCA           DPSR      EQU     $FFFFCA                           ; DSP PCI Status Register
97        FFFFC9           DSR       EQU     $FFFFC9                           ; DSP Status Register
98        FFFFC8           DPAR      EQU     $FFFFC8                           ; DSP PCI Address Register
99        FFFFC7           DPMC      EQU     $FFFFC7                           ; DSP PCI Master Control Register
100       FFFFC6           DPCR      EQU     $FFFFC6                           ; DSP PCI Control Register
101       FFFFC5           DCTR      EQU     $FFFFC5                           ; DSP Control Register
102    
103                        ; Port E is the Synchronous Communications Interface (SCI) port
104       FFFF9F           PCRE      EQU     $FFFF9F                           ; Port Control Register
105       FFFF9E           PRRE      EQU     $FFFF9E                           ; Port Direction Register
106       FFFF9D           PDRE      EQU     $FFFF9D                           ; Port Data Register
107    
108                        ; Various PCI register bit equates
109       000001           STRQ      EQU     1                                 ; Slave transmit data request (DSR)
110       000002           SRRQ      EQU     2                                 ; Slave receive data request (DSR)
111       000017           HACT      EQU     23                                ; Host active, low true (DSR)
112       000001           MTRQ      EQU     1                                 ; Set whem master transmitter is not full (DPSR)
113       000004           MARQ      EQU     4                                 ; Master address request (DPSR)
114       00000A           TRTY      EQU     10                                ; PCI Target Retry (DPSR)
115       000000           HCIE      EQU     0                                 ; Host command interrupt enable (DCTR)
116    
117                        ; DPCR bit definitions
118       00000E           CLRT      EQU     14                                ; Clear the master transmitter DTXM
119       000012           MACE      EQU     18                                ; Master access counter enable
120       000015           IAE       EQU     21                                ; Insert Address Enable
121    
122                        ; Addresses of ESSI port
123       FFFFBC           TX00      EQU     $FFFFBC                           ; Transmit Data Register 0
124       FFFFB7           SSISR0    EQU     $FFFFB7                           ; Status Register
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 3



125       FFFFB6           CRB0      EQU     $FFFFB6                           ; Control Register B
126       FFFFB5           CRA0      EQU     $FFFFB5                           ; Control Register A
127    
128                        ; SSI Control Register A Bit Flags
129       000006           TDE       EQU     6                                 ; Set when transmitter data register is empty
130    
131                        ; Miscellaneous addresses
132       FFFFFF           RDFIFO    EQU     $FFFFFF                           ; Read the FIFO for incoming fiber optic data
133       FFFF8F           TCSR0     EQU     $FFFF8F                           ; Triple timer control and status register 0
134       FFFF8B           TCSR1     EQU     $FFFF8B                           ; Triple timer control and status register 1
135       FFFF87           TCSR2     EQU     $FFFF87                           ; Triple timer control and status register 2
136    
137                        ; Phase Locked Loop initialization
138       750012           PLL_INIT  EQU     $750012                           ; PLL = 33 MHz x 19 / 8 = 78.4 MHz
139    
140                        ; Port C is Enhanced Synchronous Serial Port 0
141       FFFFBF           PCRC      EQU     $FFFFBF                           ; Port C Control Register
142       FFFFBE           PRRC      EQU     $FFFFBE                           ; Port C Data direction Register
143       FFFFBD           PDRC      EQU     $FFFFBD                           ; Port C GPIO Data Register
144    
145                        ; Port D is Enhanced Synchronous Serial Port 1
146       FFFFAF           PCRD      EQU     $FFFFAF                           ; Port D Control Register
147       FFFFAE           PRRD      EQU     $FFFFAE                           ; Port D Data direction Register
148       FFFFAD           PDRD      EQU     $FFFFAD                           ; Port D GPIO Data Register
149    
150                        ; Bit number definitions of GPIO pins on Port D
151       000000           EF        EQU     0                                 ; FIFO Empty flag, low true
152       000001           HF        EQU     1                                 ; FIFO Half Full flag, low true
153       000004           MODE      EQU     4                                 ; 1 for 32-bit reply data, 0 for 16-bit image
154    
155                        ; STATUS bit definition
156       000000           ODD       EQU     0                                 ; Set if odd number of pixels are in the image
157    
158                        ; MPL added 10/13/03
159       000006           INTA      EQU     6                                 ; Request PCI interrupt
160    
161    
162                        ; Special address for two words for the DSP to bootstrap code from the EEPROM
163                                  IF      @SCP("HOST","ROM")                ; Boot from ROM on power-on
170                                  ENDIF
171    
172                                  IF      @SCP("HOST","HOST")               ; Download via host computer
173       P:000000 P:000000                   ORG     P:0,P:0
174       P:000000 P:000000                   DC      END_ADR-INIT                      ; Number of boot words
175       P:000001 P:000001                   DC      INIT                              ; Starting address
176       P:000000 P:000000                   ORG     P:0,P:0
177       P:000000 P:000000 0C00B2  INIT      JMP     <START
178       P:000001 P:000001 000000            NOP
179                                           ENDIF
180    
181                                           IF      @SCP("HOST","ONCE")               ; Download via ONCE debugger
185                                           ENDIF
186    
187                                 ; Vectored interrupt table, addresses at the beginning are reserved
188       P:000002 P:000002                   DC      0,0,0,0,0,0,0,0,0,0,0,0,0,0       ; $02-$0f Reserved
189       P:000010 P:000010                   DC      0,0                               ; $11 - IRQA* = FIFO EF*
190       P:000012 P:000012                   DC      0,0                               ; $13 - IRQB* = FIFO HF*
191       P:000014 P:000014 0BF080            JSR     CLEAN_UP_PCI                      ; $15 - Software reset switch
                            000230
192       P:000016 P:000016                   DC      0,0,0,0,0,0,0,0,0,0,0,0           ; Reserved for DMA and Timer
193       P:000022 P:000022                   DC      0,0,0,0,0,0,0,0,0,0,0,0           ;   interrupts
194       P:00002E P:00002E 0BF080            JSR     DOWNLOAD_PCI_DSP_CODE             ; $2F
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 4



                            000045
195    
196                                 ; Now we're at P:$30, where some unused vector addresses are located
197    
198                                 ; This is ROM only code that is only executed once on power-up when the
199                                 ;   ROM code is downloaded. It is skipped over on OnCE or PCI downloads.
200                                 ; Initialize the PLL - phase locked loop
201                                 INIT_PCI
202       P:000030 P:000030 08F4BD            MOVEP             #PLL_INIT,X:PCTL        ; Initialize PLL
                            750012
203       P:000032 P:000032 000000            NOP
204    
205                                 ; Program the PCI self-configuration registers
206       P:000033 P:000033 240000            MOVE              #0,X0
207       P:000034 P:000034 08F485            MOVEP             #$500000,X:DCTR         ; Set self-configuration mode
                            500000
208       P:000036 P:000036 0604A0            REP     #4
209       P:000037 P:000037 08C408            MOVEP             X0,X:DPAR               ; Dummy writes to configuration space
210       P:000038 P:000038 08F487            MOVEP             #>$0000,X:DPMC          ; Subsystem ID
                            000000
211       P:00003A P:00003A 08F488            MOVEP             #>$0000,X:DPAR          ; Subsystem Vendor ID
                            000000
212    
213                                 ; PCI Personal reset
214       P:00003C P:00003C 08C405            MOVEP             X0,X:DCTR               ; Personal software reset
215       P:00003D P:00003D 000000            NOP
216       P:00003E P:00003E 000000            NOP
217       P:00003F P:00003F 0A89B7            JSET    #HACT,X:DSR,*                     ; Test for personal reset completion
                            00003F
218       P:000041 P:000041 07F084            MOVE              P:(*+3),X0              ; Trick to write "JMP <START" to P:0
                            000044
219       P:000043 P:000043 070004            MOVE              X0,P:(0)
220       P:000044 P:000044 0C00B2            JMP     <START
221    
222                                 DOWNLOAD_PCI_DSP_CODE
223       P:000045 P:000045 0A8615            BCLR    #IAE,X:DPCR                       ; Do not insert PCI address with data
224       P:000046 P:000046 0A8982  DNL0      JCLR    #SRRQ,X:DSR,*                     ; Wait for a receiver word
                            000046
225       P:000048 P:000048 084E0B            MOVEP             X:DRXR,A                ; Read it
226       P:000049 P:000049 0140C5            CMP     #$555AAA,A                        ; Check for sanity header word
                            555AAA
227       P:00004B P:00004B 0E2046            JNE     <DNL0
228       P:00004C P:00004C 044EBA            MOVE              OMR,A
229       P:00004D P:00004D 0140C6            AND     #$FFFFF0,A
                            FFFFF0
230       P:00004F P:00004F 014C82            OR      #$00000C,A
231       P:000050 P:000050 000000            NOP
232       P:000051 P:000051 04CEBA            MOVE              A,OMR                   ; Set boot mode to $C = PCI
233       P:000052 P:000052 0AF080            JMP     $FF0000                           ; Jump to boot code internal to DSP
                            FF0000
234    
235       P:000054 P:000054                   DC      0,0,0,0,0,0,0,0,0,0,0,0           ; Filler
236       P:000060 P:000060                   DC      0,0                               ; $60 - PCI Transaction Termination
237       P:000062 P:000062                   DC      0,0,0,0,0,0,0,0,0                 ; $62-$71 Reserved PCI
238       P:00006B P:00006B                   DC      0,0,0,0,0,0,0
239    
240                                 ; These interrupts are non-maskable, called from the host with $80xx
241    
242                                 ; MPL added 12/19/03
243       P:000072 P:000072 0A8506            BCLR    #INTA,X:DCTR                      ; $8073 - Clear PCI interrupt
244       P:000073 P:000073                   DC      0
245    
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 5



246       P:000074 P:000074 0BF080            JSR     READ_NUMBER_OF_PIXELS_READ        ; $8075
                            0001D4
247       P:000076 P:000076 0BF080            JSR     CLEAN_UP_PCI                      ; $8077
                            000230
248       P:000078 P:000078 0BF080            JSR     ABORT_READOUT                     ; $8079
                            00021C
249       P:00007A P:00007A 0BF080            JSR     BOOT_EEPROM                       ; $807B
                            000183
250       P:00007C P:00007C                   DC      0,0,0,0                           ; Available
251    
252                                 ; These vector interrupts are masked at IPL = 1
253       P:000080 P:000080 0BF080            JSR     READ_REPLY_HEADER                 ; $81
                            000371
254       P:000082 P:000082 0BF080            JSR     READ_REPLY_VALUE                  ; $83
                            00036E
255       P:000084 P:000084 0BF080            JSR     CLEAR_HOST_FLAG                   ; $85
                            000373
256       P:000086 P:000086 0BF080            JSR     RESET_CONTROLLER                  ; $87
                            0001DA
257       P:000088 P:000088 0BF080            JSR     READ_IMAGE                        ; $89
                            00023A
258       P:00008A P:00008A                   DC      0,0                               ; Available
259       P:00008C P:00008C 0BF080            JSR     WRITE_BASE_PCI_ADDRESS            ; $8D
                            000206
260    
261       P:00008E P:00008E                   DC      0,0,0,0                           ; Available
262       P:000092 P:000092                   DC      0,0,0,0,0,0,0,0,0,0,0,0,0,0
263       P:0000A0 P:0000A0                   DC      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
264    
265                                 ; New manual command for Version 1.6
266       P:0000B0 P:0000B0 0BF080            JSR     WRITE_COMMAND                     ; $B1
                            00018E
267    
268       P:0000B2 P:0000B2 08F487  START     MOVEP             #>$00001,X:DPMC         ; 32-bit PCI <-> 24-bit DSP data
                            000001
269       P:0000B4 P:0000B4 0A8534            BSET    #20,X:DCTR                        ; HI32 mode = 1 => PCI
270       P:0000B5 P:0000B5 0A8515            BCLR    #21,X:DCTR
271       P:0000B6 P:0000B6 0A8516            BCLR    #22,X:DCTR
272       P:0000B7 P:0000B7 000000            NOP
273       P:0000B8 P:0000B8 0A8AAC            JSET    #12,X:DPSR,*                      ; Host data transfer not in progress
                            0000B8
274       P:0000BA P:0000BA 000000            NOP
275       P:0000BB P:0000BB 0A8632            BSET    #MACE,X:DPCR                      ; Master access counter enable
276       P:0000BC P:0000BC 000000            NOP                                       ; End of PCI programming
277    
278                                 ; Set operation mode register OMR to normal expanded
279       P:0000BD P:0000BD 0500BA            MOVEC             #$0000,OMR              ; Operating Mode Register = Normal Expanded
280       P:0000BE P:0000BE 0500BB            MOVEC             #0,SP                   ; Reset the Stack Pointer SP
281    
282                                 ; Move the table of constants from P: space to X: space
283       P:0000BF P:0000BF 61F400            MOVE              #CONSTANTS_TBL_START,R1 ; Start of table of constants
                            000426
284       P:0000C1 P:0000C1 300200            MOVE              #2,R0                   ; Leave X:0 for STATUS
285       P:0000C2 P:0000C2 060F80            DO      #CONSTANTS_TBL_LENGTH,L_WRITE
                            0000C5
286       P:0000C4 P:0000C4 07D984            MOVE              P:(R1)+,X0
287       P:0000C5 P:0000C5 445800            MOVE              X0,X:(R0)+              ; Write the constants to X:
288                                 L_WRITE
289    
290                                 ; Program the serial port ESSI0 = Port C for serial transmission to
291                                 ;   the timing board
292       P:0000C6 P:0000C6 07F43F            MOVEP             #>0,X:PCRC              ; Software reset of ESSI0
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 6



                            000000
293       P:0000C8 P:0000C8 07F435            MOVEP             #$000809,X:CRA0         ; Divide 78.4 MHz by 20 to get 3.92 MHz
                            000809
294                                                                                     ; DC0-CD4 = 0 for non-network operation
295                                                                                     ; WL0-WL2 = ALC = 0 for 8-bit data words
296                                                                                     ; SSC1 = 0 for SC1 not used
297       P:0000CA P:0000CA 07F436            MOVEP             #$010120,X:CRB0         ; SCKD = 1 for internally generated clock
                            010120
298                                                                                     ; SHFD = 0 for MSB shifted first
299                                                                                     ; CKP = 0 for rising clock edge transitions
300                                                                                     ; TE0 = 1 to enable transmitter #0
301                                                                                     ; MOD = 0 for normal, non-networked mode
302                                                                                     ; FSL1 = 1, FSL0 = 0 for no reason
303       P:0000CC P:0000CC 07F43F            MOVEP             #%101000,X:PCRC         ; Control Register (0 for GPIO, 1 for ESSI)
                            000028
304                                                                                     ; Set SCK0 = P3, STD0 = P5 to ESSI0
305       P:0000CE P:0000CE 07F43E            MOVEP             #%010111,X:PRRC         ; Data Direction Register (0 for In, 1 for O
ut)
                            000017
306       P:0000D0 P:0000D0 07F43D            MOVEP             #%010101,X:PDRC         ; Data Register - ROM/FIFO* = 0, SC02 = 0,
                            000015
307                                                                                     ;   AUX1 = 1, AUX2 = AUX3 = 1 (MPL for Gen2)
308    
309                                 ; Conversion from software bits to schematic labels for Port C and D
310                                 ;       PC0 = SC00 = AUX3               PD0 = SC10 = EF*
311                                 ;       PC1 = SC01 = ROM/FIFO*          PD1 = SC11 = HF*
312                                 ;       PC2 = SC02 = AUX2               PD2 = SC12 = RS*
313                                 ;       PC3 = SCK0 = Serial clock       PD3 = SCK1 = FSYNC*
314                                 ;       PC4 = SRD0 = AUX1               PD4 = SRD1 = MODE
315                                 ;       PC5 = STD0 = Serial data        PD5 = STD1 = WRFIFO*
316    
317                                 ; Program the serial port ESSI1 = Port D for general purpose I/O (GPIO)
318       P:0000D2 P:0000D2 07F42F            MOVEP             #%000000,X:PCRD         ; Control Register (0 for GPIO, 1 for ESSI)
                            000000
319       P:0000D4 P:0000D4 07F42E            MOVEP             #%010100,X:PRRD         ; Data Direction Register (0 for In, 1 for O
ut)
                            000014
320       P:0000D6 P:0000D6 07F42D            MOVEP             #%010000,X:PDRD         ; Data Register - Pulse RS* low, MODE = 1
                            000010
321       P:0000D8 P:0000D8 060AA0            REP     #10
322       P:0000D9 P:0000D9 000000            NOP
323       P:0000DA P:0000DA 07F42D            MOVEP             #%010100,X:PDRD
                            000014
324    
325                                 ; Program the SCI port to benign values
326       P:0000DC P:0000DC 07F41F            MOVEP             #%000,X:PCRE            ; Port Control Register = GPIO
                            000000
327       P:0000DE P:0000DE 07F41E            MOVEP             #%110,X:PRRE            ; Port Direction Register (0 = Input)
                            000006
328       P:0000E0 P:0000E0 07F41D            MOVEP             #%110,X:PDRE            ; Port Data Register
                            000006
329                                 ;       PE0 = RXD
330                                 ;       PE1 = TXD
331                                 ;       PE2 = SCLK
332    
333                                 ; Program the triple timer to assert TCI0 as a GPIO output = 1
334       P:0000E2 P:0000E2 07F40F            MOVEP             #$2800,X:TCSR0
                            002800
335       P:0000E4 P:0000E4 07F40B            MOVEP             #$2800,X:TCSR1
                            002800
336       P:0000E6 P:0000E6 07F407            MOVEP             #$2800,X:TCSR2
                            002800
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 7



337    
338                                 ; Program the AA1 pin to read the FIFO memory for incoming timing board data
339       P:0000E8 P:0000E8 08F4B8            MOVEP             #$FFFC21,X:AAR1         ; Y = $FFF000 to $FFFFFF asserts AA1 low tru
e
                            FFFC21
340    
341                                 ; Program the DRAM memory access and addressing
342       P:0000EA P:0000EA 08F4BB            MOVEP             #$000020,X:BCR          ; Bus Control Register
                            000020
343       P:0000EC P:0000EC 08F4BA            MOVEP             #$893A05,X:DCR          ; DRAM Control Register
                            893A05
344       P:0000EE P:0000EE 08F4B7            MOVEP             #$000122,X:AAR2         ; Y: $000000 to $7FFFFF asserts AA2
                            000122
345       P:0000F0 P:0000F0 08F4B9            MOVEP             #$800122,X:AAR0         ; Y: $800000 to $FFFFFF asserts AA0
                            800122
346       P:0000F2 P:0000F2 08F4B6            MOVEP             #$000112,X:AAR3         ; X: $000000 to $7FFFFF asserts AA3
                            000112
347    
348                                 ; Clear all PCI error conditions
349       P:0000F4 P:0000F4 084E0A            MOVEP             X:DPSR,A
350       P:0000F5 P:0000F5 0140C2            OR      #$1FE,A
                            0001FE
351       P:0000F7 P:0000F7 000000            NOP
352       P:0000F8 P:0000F8 08CE0A            MOVEP             A,X:DPSR
353    
354                                 ; Establish interrupt priority levels IPL
355       P:0000F9 P:0000F9 08F4BF            MOVEP             #$0001C0,X:IPRC         ; IRQC priority IPL = 2 (reset switch, edge)
                            0001C0
356                                                                                     ; IRQB priority IPL = 2 or 0
357                                                                                     ;     (FIFO half full - HF*, level)
358       P:0000FB P:0000FB 08F4BE            MOVEP             #>2,X:IPRP              ; Enable PCI Host interrupts, IPL = 1
                            000002
359       P:0000FD P:0000FD 0A8520            BSET    #HCIE,X:DCTR                      ; Enable host command interrupts
360       P:0000FE P:0000FE 0500B9            MOVE              #0,SR                   ; Don't mask any interrupts
361    
362                                 ; Initialize the fiber optic serial transmitter to zero
363       P:0000FF P:0000FF 01B786            JCLR    #TDE,X:SSISR0,*
                            0000FF
364       P:000101 P:000101 07F43C            MOVEP             #$000000,X:TX00
                            000000
365    
366                                 ; Clear out the PCI receiver and transmitter FIFOs
367       P:000103 P:000103 0A862E            BSET    #CLRT,X:DPCR                      ; Clear the master transmitter
368       P:000104 P:000104 0A86AE            JSET    #CLRT,X:DPCR,*                    ; Wait for the clearing to be complete
                            000104
369       P:000106 P:000106 0A8982  CLR0      JCLR    #SRRQ,X:DSR,CLR1                  ; Wait for the receiver to be empty
                            00010B
370       P:000108 P:000108 08440B            MOVEP             X:DRXR,X0               ; Read receiver to empty it
371       P:000109 P:000109 000000            NOP
372       P:00010A P:00010A 0C0106            JMP     <CLR0
373                                 CLR1
374    
375                                 ; Repy = DONE host flags
376       P:00010B P:00010B 448600            MOVE              X:<FLAG_DONE,X0         ; Flag = 1 => Normal execution
377       P:00010C P:00010C 441D00            MOVE              X0,X:<HOST_FLAG
378       P:00010D P:00010D 0D016E            JSR     <FO_WRITE_HOST_FLAG
379    
380                                 ; ********************************************************************
381                                 ;
382                                 ;                       REGISTER  USAGE
383                                 ;
384                                 ;       X0, X1, Y0, Y1, A and B are used freely in READ_IMAGE. Interrups
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 8



385                                 ;               during readout will clobber these registers, as a result
386                                 ;               of which only catastrophic commands such as ABORT_READOUT
387                                 ;               and BOOT_EEPROM are allowed during readout.
388                                 ;
389                                 ;       X0, X1 and A are used for all interrupt handling routines, such
390                                 ;               as CLEAR_HOST-FLAGS, command processing and so on.
391                                 ;
392                                 ;       Y0, Y1 and B are used for all fiber optic processing routines,
393                                 ;               which are not in interrupt service routines.
394                                 ;
395                                 ; *********************************************************************
396    
397    
398    
399                                 ; ************  Start of command interpreting code  ******************
400    
401                                 ; Test for fiber optic data on the FIFO. Discard the header for now
402    
403                                 ; Check for the header $AC in the first byte = Y0. Wait a little while and
404                                 ;  clear the FIFO if its not $AC - there was probably noise on the line.
405                                 ; We assume only two word replies here - Header = (S,D,#words)  Reply
406    
407       P:00010E P:00010E 01AD80  GET_FO    JCLR    #EF,X:PDRD,GET_FO                 ; Test for new fiber optic data
                            00010E
408       P:000110 P:000110 0D03A5            JSR     <RD_FO_TIMEOUT                    ; Move the FIFO reply into A1
409       P:000111 P:000111 0E8179            JCS     <FO_ERR
410    
411                                 ; Check the header bytes for self-consistency
412       P:000112 P:000112 21A600            MOVE              B1,Y0
413       P:000113 P:000113 57F400            MOVE              #$FCFCF8,B              ; Test for S.LE.3 and D.LE.3 and N.LE.7
                            FCFCF8
414       P:000115 P:000115 20005E            AND     Y0,B
415       P:000116 P:000116 0E2179            JNE     <FO_ERR                           ; Test failed
416       P:000117 P:000117 57F400            MOVE              #$030300,B              ; Test for either S.NE.0 or D.NE.0
                            030300
417       P:000119 P:000119 20005E            AND     Y0,B
418       P:00011A P:00011A 0EA179            JEQ     <FO_ERR                           ; Test failed
419       P:00011B P:00011B 57F400            MOVE              #>7,B
                            000007
420       P:00011D P:00011D 20005E            AND     Y0,B                              ; Extract NWORDS, must be >= 2
421       P:00011E P:00011E 01418D            CMP     #1,B
422       P:00011F P:00011F 0EF179            JLE     <FO_ERR
423       P:000120 P:000120 20CF00            MOVE              Y0,B
424       P:000121 P:000121 0C1891            EXTRACTU #$008020,B,B                     ; Extract bits 15-8 = destination byte
                            008020
425       P:000123 P:000123 000000            NOP
426       P:000124 P:000124 511E00            MOVE              B0,X:<FO_DEST
427    
428                                 ; Read the reply or command from the fiber optics FIFO
429       P:000125 P:000125 0D03A5            JSR     <RD_FO_TIMEOUT                    ; Move the FIFO reply into A1
430       P:000126 P:000126 0E8179            JCS     <FO_ERR
431       P:000127 P:000127 551F00            MOVE              B1,X:<FO_CMD
432    
433                                 ; Check for commands from the controller to the PCI board, FO_DEST = 1
434       P:000128 P:000128 579E00            MOVE              X:<FO_DEST,B
435       P:000129 P:000129 01418D            CMP     #1,B
436       P:00012A P:00012A 0E2139            JNE     <HOSTCMD
437       P:00012B P:00012B 579F00            MOVE              X:<FO_CMD,B
438       P:00012C P:00012C 0140CD            CMP     #'RDA',B                          ; Read the image
                            524441
439       P:00012E P:00012E 0EA23A            JEQ     <READ_IMAGE
440       P:00012F P:00012F 0140CD            CMP     #'IIA',B
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 9



                            494941
441       P:000131 P:000131 0EA212            JEQ     <INITIALIZE_NUMBER_OF_PIXELS      ; IPXLS = 0
442       P:000132 P:000132 0140CD            CMP     #'RDI',B
                            524449
443       P:000134 P:000134 0EA15E            JEQ     <READING_IMAGE                    ; Controller is reading an image
444       P:000135 P:000135 0140CD            CMP     #'RDO',B
                            52444F
445       P:000137 P:000137 0EA169            JEQ     <READING_IMAGE_OFF                ; Controller no longer reading an image
446       P:000138 P:000138 0C010E            JMP     <GET_FO                           ; Not on the list -> just ignore it
447    
448                                 ; Check if the command or reply is for the host. If not just ignore it.
449       P:000139 P:000139 579E00  HOSTCMD   MOVE              X:<FO_DEST,B
450       P:00013A P:00013A 01408D            CMP     #0,B
451       P:00013B P:00013B 0E210E            JNE     <GET_FO
452       P:00013C P:00013C 579F00            MOVE              X:<FO_CMD,B
453       P:00013D P:00013D 0140CD            CMP     #'DON',B
                            444F4E
454       P:00013F P:00013F 0EA14E            JEQ     <CONTROLLER_DONE                  ; Normal DONE reply
455       P:000140 P:000140 0140CD            CMP     #'ERR',B
                            455252
456       P:000142 P:000142 0EA152            JEQ     <CONTROLLER_ERROR                 ; Error reply
457       P:000143 P:000143 0140CD            CMP     #'BSY',B
                            425359
458       P:000145 P:000145 0EA15A            JEQ     <CONTROLLER_BUSY                  ; Controller is busy executing a command
459       P:000146 P:000146 0140CD            CMP     #'SYR',B
                            535952
460       P:000148 P:000148 0EA156            JEQ     <CONTROLLER_RESET                 ; Controller system reset
461    
462                                 ; The controller reply is none of the above so return it as a reply
463       P:000149 P:000149 551C00            MOVE              B1,X:<REPLY             ; Report value
464       P:00014A P:00014A 468700            MOVE              X:<FLAG_REPLY,Y0        ; Flag = 2 => Reply with a value
465       P:00014B P:00014B 461D00            MOVE              Y0,X:<HOST_FLAG
466       P:00014C P:00014C 0D016E            JSR     <FO_WRITE_HOST_FLAG
467       P:00014D P:00014D 0C010E            JMP     <GET_FO
468    
469                                 CONTROLLER_DONE
470       P:00014E P:00014E 468600            MOVE              X:<FLAG_DONE,Y0         ; Flag = 1 => Normal execution
471       P:00014F P:00014F 461D00            MOVE              Y0,X:<HOST_FLAG
472       P:000150 P:000150 0D016E            JSR     <FO_WRITE_HOST_FLAG
473       P:000151 P:000151 0C010E            JMP     <GET_FO                           ; Keep looping for fiber optic commands
474    
475                                 CONTROLLER_ERROR
476       P:000152 P:000152 468800            MOVE              X:<FLAG_ERR,Y0          ; Flag = 3 => controller error
477       P:000153 P:000153 461D00            MOVE              Y0,X:<HOST_FLAG
478       P:000154 P:000154 0D016E            JSR     <FO_WRITE_HOST_FLAG
479       P:000155 P:000155 0C010E            JMP     <GET_FO                           ; Keep looping for fiber optic commands
480    
481                                 CONTROLLER_RESET
482       P:000156 P:000156 468900            MOVE              X:<FLAG_SYR,Y0          ; Flag = 4 => controller reset
483       P:000157 P:000157 461D00            MOVE              Y0,X:<HOST_FLAG
484       P:000158 P:000158 0D016E            JSR     <FO_WRITE_HOST_FLAG
485       P:000159 P:000159 0C010E            JMP     <GET_FO                           ; Keep looping for fiber optic commands
486    
487                                 CONTROLLER_BUSY
488       P:00015A P:00015A 468B00            MOVE              X:<FLAG_BUSY,Y0         ; Flag = 6 => controller busy
489       P:00015B P:00015B 461D00            MOVE              Y0,X:<HOST_FLAG
490       P:00015C P:00015C 0D016E            JSR     <FO_WRITE_HOST_FLAG
491       P:00015D P:00015D 0C010E            JMP     <GET_FO                           ; Keep looping for fiber optic commands
492    
493                                 ; A special handshaking here ensures that the host computer has read the 'DON'
494                                 ;   reply to the start_exposure command before the reading_image state is
495                                 ;   set in the host flags. Reading_image occurs only after a start_exposure
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 10



496                                 READING_IMAGE
497       P:00015E P:00015E 579D00            MOVE              X:<HOST_FLAG,B          ; Retrieve current host flag value
498       P:00015F P:00015F 448A00            MOVE              X:<FLAG_RDI,X0
499       P:000160 P:000160 20004D            CMP     X0,B                              ; If we're already in read_image
500       P:000161 P:000161 0EA10E            JEQ     <GET_FO                           ;   mode then do nothing
501       P:000162 P:000162 20000B            TST     B                                 ; Wait for flag to be cleared, which
502       P:000163 P:000163 0E215E            JNE     <READING_IMAGE                    ;  the host does when it gets the DONE
503    
504       P:000164 P:000164 0A8500            BCLR    #HCIE,X:DCTR                      ; Disable host command interrupts
505       P:000165 P:000165 468A00            MOVE              X:<FLAG_RDI,Y0
506       P:000166 P:000166 461D00            MOVE              Y0,X:<HOST_FLAG
507       P:000167 P:000167 0D016E            JSR     <FO_WRITE_HOST_FLAG               ; Set Host Flag to "reading out"
508       P:000168 P:000168 0C010E            JMP     <GET_FO                           ; Keep looping for fiber optic commands
509    
510                                 READING_IMAGE_OFF                                   ; Controller is no longer reading out
511       P:000169 P:000169 468500            MOVE              X:<FLAG_ZERO,Y0
512       P:00016A P:00016A 461D00            MOVE              Y0,X:<HOST_FLAG
513       P:00016B P:00016B 0D016E            JSR     <FO_WRITE_HOST_FLAG
514       P:00016C P:00016C 0A8520            BSET    #HCIE,X:DCTR                      ; Enable host command interrupts
515       P:00016D P:00016D 0C010E            JMP     <GET_FO                           ; Keep looping for fiber optic commands
516    
517                                 ; Write X:<HOST_FLAG to the DCTR flag bits 5,4,3, as a subroutine
518                                 FO_WRITE_HOST_FLAG
519       P:00016E P:00016E 57F000            MOVE              X:DCTR,B
                            FFFFC5
520       P:000170 P:000170 469D00            MOVE              X:<HOST_FLAG,Y0
521       P:000171 P:000171 0140CE            AND     #$FFFFC7,B                        ; Clear bits 5,4,3
                            FFFFC7
522       P:000173 P:000173 000000            NOP
523       P:000174 P:000174 20005A            OR      Y0,B                              ; Set flags appropriately
524       P:000175 P:000175 000000            NOP
525       P:000176 P:000176 577000            MOVE              B,X:DCTR
                            FFFFC5
526       P:000178 P:000178 00000C            RTS
527    
528                                 ; There was an erroneous word on the fiber optic line -> clear the FIFO
529       P:000179 P:000179 07F42D  FO_ERR    MOVEP             #%010000,X:PDRD         ; Clear FIFO RESET* for 2 milliseconds
                            000010
530       P:00017B P:00017B 46F400            MOVE              #200000,Y0
                            030D40
531       P:00017D P:00017D 06C600            DO      Y0,*+3
                            00017F
532       P:00017F P:00017F 000000            NOP
533       P:000180 P:000180 07F42D            MOVEP             #%010100,X:PDRD         ; Data Register - Set RS* high
                            000014
534       P:000182 P:000182 0C010E            JMP     <GET_FO
535    
536                                 ; **************  Boot from byte-wide on-board EEPROM  *******************
537    
538                                 BOOT_EEPROM
539       P:000183 P:000183 08F4BB            MOVEP             #$0002A0,X:BCR          ; Bus Control Register for slow EEPROM
                            0002A0
540       P:000185 P:000185 013D21            BSET    #1,X:PDRC                         ; ROM/FIFO* = 1 to select ROM
541       P:000186 P:000186 044EBA            MOVE              OMR,A
542       P:000187 P:000187 0140C6            AND     #$FFFFF0,A
                            FFFFF0
543       P:000189 P:000189 014982            OR      #$000009,A                        ; Boot mode = $9 = byte-wide EEPROM
544       P:00018A P:00018A 000000            NOP
545       P:00018B P:00018B 04CEBA            MOVE              A,OMR
546       P:00018C P:00018C 0AF080            JMP     $FF0000                           ; Jump to boot code internal to DSP
                            FF0000
547    
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 11



548                                 ; ***************  Command processing  ****************
549    
550                                 WRITE_COMMAND
551       P:00018E P:00018E 0A8982            JCLR    #SRRQ,X:DSR,ERROR                 ; Error if receiver FIFO has no data
                            00035A
552       P:000190 P:000190 084E0B            MOVEP             X:DRXR,A                ; Get the header
553       P:000191 P:000191 000000            NOP                                       ; Pipeline restriction
554       P:000192 P:000192 543000            MOVE              A1,X:<HEADER
555    
556                                 ; Check the header bytes for self-consistency
557       P:000193 P:000193 218400            MOVE              A1,X0
558       P:000194 P:000194 56F400            MOVE              #$FCFCF8,A              ; Test for S.LE.3 and D.LE.3 and N.LE.7
                            FCFCF8
559       P:000196 P:000196 200046            AND     X0,A
560       P:000197 P:000197 0E235A            JNE     <ERROR                            ; Test failed
561       P:000198 P:000198 56F400            MOVE              #$030300,A              ; Test for either S.NE.0 or D.NE.0
                            030300
562       P:00019A P:00019A 200046            AND     X0,A
563       P:00019B P:00019B 0EA35A            JEQ     <ERROR                            ; Test failed
564       P:00019C P:00019C 56F400            MOVE              #>7,A
                            000007
565       P:00019E P:00019E 200046            AND     X0,A                              ; Extract NUM_ARG, must be >= 0
566       P:00019F P:00019F 000000            NOP                                       ; Pipeline restriction
567       P:0001A0 P:0001A0 014284            SUB     #2,A
568       P:0001A1 P:0001A1 0E935A            JLT     <ERROR                            ; Number of arguments >= 0
569       P:0001A2 P:0001A2 543500            MOVE              A1,X:<NUM_ARG           ; Store number of arguments in command
570       P:0001A3 P:0001A3 014685            CMP     #6,A                              ; Number of arguemnts <= 6
571       P:0001A4 P:0001A4 0E735A            JGT     <ERROR
572    
573                                 ; Get the DESTINATION number (1 = PCI, 2 = timing, 3 = utility)
574       P:0001A5 P:0001A5 208E00            MOVE              X0,A                    ; Still the header
575       P:0001A6 P:0001A6 0C1ED0            LSR     #8,A
576       P:0001A7 P:0001A7 0140C6            AND     #>3,A                             ; Extract just three bits of
                            000003
577       P:0001A9 P:0001A9 543400            MOVE              A1,X:<DESTINATION       ;   the destination byte
578       P:0001AA P:0001AA 0EA35A            JEQ     <ERROR                            ; Destination of zero = host not allowed
579       P:0001AB P:0001AB 014185            CMP     #1,A                              ; Destination byte for PCI board
580       P:0001AC P:0001AC 0EA1BA            JEQ     <PCI
581    
582                                 ; Write the controller command and its arguments to the fiber optics
583       P:0001AD P:0001AD 56B000            MOVE              X:<HEADER,A
584       P:0001AE P:0001AE 0BF080            JSR     XMT_WRD                           ; Write the word to the fiber optics
                            000383
585       P:0001B0 P:0001B0 0A8982            JCLR    #SRRQ,X:DSR,ERROR                 ; Error if receiver FIFO has no data
                            00035A
586       P:0001B2 P:0001B2 084E0B            MOVEP             X:DRXR,A                ; Write the command
587       P:0001B3 P:0001B3 0D0383            JSR     <XMT_WRD                          ; Write the command to the fiber optics
588       P:0001B4 P:0001B4 063500            DO      X:<NUM_ARG,L_ARGS1                ; Do loop won't execute if NUM_ARG = 0
                            0001B8
589       P:0001B6 P:0001B6 084E0B            MOVEP             X:DRXR,A                ; Get the arguments
590       P:0001B7 P:0001B7 0D0383            JSR     <XMT_WRD                          ; Write the argument to the fiber optics
591       P:0001B8 P:0001B8 000000            NOP                                       ; DO loop restriction
592       P:0001B9 P:0001B9 000004  L_ARGS1   RTI                                       ; The controller will generate the reply
593    
594                                 ; Since it's a PCI command store the command and its arguments in X: memory
595       P:0001BA P:0001BA 0A8982  PCI       JCLR    #SRRQ,X:DSR,ERROR                 ; Error if receiver FIFO has no data
                            00035A
596       P:0001BC P:0001BC 08708B            MOVEP             X:DRXR,X:COMMAND        ; Get the command
                            000031
597       P:0001BE P:0001BE 56B500            MOVE              X:<NUM_ARG,A            ; Get number of arguments in command
598       P:0001BF P:0001BF 60F400            MOVE              #ARG1,R0                ; Starting address of argument list
                            000032
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 12



599       P:0001C1 P:0001C1 06CE00            DO      A,L_ARGS2                         ; DO loop won't execute if A = 0
                            0001C5
600       P:0001C3 P:0001C3 0A8982            JCLR    #SRRQ,X:DSR,ERROR                 ; Error if receiver FIFO has no data
                            00035A
601       P:0001C5 P:0001C5 08588B            MOVEP             X:DRXR,X:(R0)+          ; Get arguments
602                                 L_ARGS2
603    
604                                 ; Process a PCI board non-vector command
605                                 PCI_COMMAND
606       P:0001C6 P:0001C6 56B100            MOVE              X:<COMMAND,A            ; Get the command
607       P:0001C7 P:0001C7 0140C5            CMP     #'TRM',A                          ; Is it the test DRAM command?
                            54524D
608       P:0001C9 P:0001C9 0EA3D7            JEQ     <TEST_DRAM
609       P:0001CA P:0001CA 0140C5            CMP     #'TDL',A                          ; Is it the test data link command?
                            54444C
610       P:0001CC P:0001CC 0EA2F6            JEQ     <TEST_DATA_LINK
611       P:0001CD P:0001CD 0140C5            CMP     #'RDM',A
                            52444D
612       P:0001CF P:0001CF 0EA2F8            JEQ     <READ_MEMORY                      ; Is it the read memory command?
613       P:0001D0 P:0001D0 0140C5            CMP     #'WRM',A
                            57524D
614       P:0001D2 P:0001D2 0EA323            JEQ     <WRITE_MEMORY                     ; Is it the write memory command?
615       P:0001D3 P:0001D3 0C035A            JMP     <ERROR                            ; Its not a recognized command
616    
617                                 ; ********************  Vector commands  *******************
618    
619                                 READ_NUMBER_OF_PIXELS_READ                          ; Write the reply to the DTXS FIFO
620       P:0001D4 P:0001D4 08F08D            MOVEP             X:R_PXLS_0,X:DTXS       ; DSP-to-host slave transmit
                            000017
621       P:0001D6 P:0001D6 000000            NOP
622       P:0001D7 P:0001D7 08F08D            MOVEP             X:R_PXLS_1,X:DTXS       ; DSP-to-host slave transmit
                            000016
623       P:0001D9 P:0001D9 000004            RTI
624    
625                                 ; Reset the controller by sending a special code for the preamble byte
626                                 RESET_CONTROLLER
627       P:0001DA P:0001DA 01B786            JCLR    #TDE,X:SSISR0,*
                            0001DA
628       P:0001DC P:0001DC 07F43C            MOVEP             #$000000,X:TX00
                            000000
629       P:0001DE P:0001DE 000000            NOP
630       P:0001DF P:0001DF 01B786            JCLR    #TDE,X:SSISR0,*                   ; Start bit
                            0001DF
631       P:0001E1 P:0001E1 07F43C            MOVEP             #$010000,X:TX00
                            010000
632       P:0001E3 P:0001E3 000000            NOP
633       P:0001E4 P:0001E4 01B786            JCLR    #TDE,X:SSISR0,*
                            0001E4
634       P:0001E6 P:0001E6 07F43C            MOVEP             #$530000,X:TX00         ; Preamble byte = reset
                            530000
635       P:0001E8 P:0001E8 000000            NOP
636       P:0001E9 P:0001E9 060380            DO      #3,L_RESET
                            0001EE
637       P:0001EB P:0001EB 01B786            JCLR    #TDE,X:SSISR0,*                   ; Three data bytes = anything
                            0001EB
638       P:0001ED P:0001ED 04CCDC            MOVEP             A1,X:TX00
639       P:0001EE P:0001EE 000000            NOP
640                                 L_RESET
641       P:0001EF P:0001EF 01B786            JCLR    #TDE,X:SSISR0,*                   ; Zeroes to bring TX00 low
                            0001EF
642       P:0001F1 P:0001F1 07F43C            MOVEP             #$000000,X:TX00
                            000000
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 13



643       P:0001F3 P:0001F3 07F42D            MOVEP             #%010000,X:PDRD         ; Reset the receiver FIFO
                            000010
644       P:0001F5 P:0001F5 060AA0            REP     #10
645       P:0001F6 P:0001F6 000000            NOP
646       P:0001F7 P:0001F7 07F42D            MOVEP             #%010100,X:PDRD         ; Stop resetting the FIFO
                            000014
647    
648                                 ; Wait around for the 'SYR' reply from the controller
649       P:0001F9 P:0001F9 0D03A5            JSR     <RD_FO_TIMEOUT                    ; Move the FIFO reply into A1
650       P:0001FA P:0001FA 0E835A            JCS     <ERROR
651       P:0001FB P:0001FB 0140CD            CMP     #$020002,B
                            020002
652       P:0001FD P:0001FD 0E235A            JNE     <ERROR                            ; There was an error
653       P:0001FE P:0001FE 01AD80            JCLR    #EF,X:PDRD,*                      ; Test for new fiber optic data
                            0001FE
654       P:000200 P:000200 0D03A5            JSR     <RD_FO_TIMEOUT                    ; Move the FIFO reply into A1
655       P:000201 P:000201 0E835A            JCS     <ERROR
656       P:000202 P:000202 0140CD            CMP     #'SYR',B
                            535952
657       P:000204 P:000204 0E235A            JNE     <ERROR                            ; There was an error
658       P:000205 P:000205 0C035D            JMP     <SYR                              ; Reply to host, return from interrupt
659    
660                                 ; ****************  Exposure and readout commands  ****************
661    
662                                 WRITE_BASE_PCI_ADDRESS
663       P:000206 P:000206 0A8982            JCLR    #SRRQ,X:DSR,ERROR                 ; Error if receiver FIFO has no data
                            00035A
664       P:000208 P:000208 08480B            MOVEP             X:DRXR,A0
665       P:000209 P:000209 0A8982            JCLR    #SRRQ,X:DSR,ERROR                 ; Error if receiver FIFO has no data
                            00035A
666       P:00020B P:00020B 08440B            MOVEP             X:DRXR,X0               ; Get most significant word
667       P:00020C P:00020C 0C1940            INSERT  #$010010,X0,A
                            010010
668       P:00020E P:00020E 000000            NOP
669       P:00020F P:00020F 501900            MOVE              A0,X:<BASE_ADDR_0       ; BASE_ADDR is 8 + 24 bits
670       P:000210 P:000210 541800            MOVE              A1,X:<BASE_ADDR_1
671       P:000211 P:000211 0C0353            JMP     <FINISH                           ; Write 'DON' reply
672    
673                                 ; Write the base PCI image address to the PCI address
674                                 INITIALIZE_NUMBER_OF_PIXELS
675       P:000212 P:000212 200013            CLR     A
676       P:000213 P:000213 000000            NOP
677       P:000214 P:000214 541600            MOVE              A1,X:<R_PXLS_1          ; Up counter of number of pixels read
678       P:000215 P:000215 501700            MOVE              A0,X:<R_PXLS_0
679    
680       P:000216 P:000216 509900            MOVE              X:<BASE_ADDR_0,A0       ; BASE_ADDR is 2 x 16-bits
681       P:000217 P:000217 549800            MOVE              X:<BASE_ADDR_1,A1
682       P:000218 P:000218 000000            NOP
683       P:000219 P:000219 501B00            MOVE              A0,X:<PCI_ADDR_0        ; PCI_ADDR is 8 + 24 bits
684       P:00021A P:00021A 541A00            MOVE              A1,X:<PCI_ADDR_1
685    
686       P:00021B P:00021B 0C014E            JMP     <CONTROLLER_DONE                  ; Repy = DONE host flags
687    
688                                 ; Send an abort readout command to the controller to stop image transmission
689                                 ABORT_READOUT
690       P:00021C P:00021C 448600            MOVE              X:<FLAG_DONE,X0
691       P:00021D P:00021D 441D00            MOVE              X0,X:<HOST_FLAG
692       P:00021E P:00021E 0D016E            JSR     <FO_WRITE_HOST_FLAG
693    
694       P:00021F P:00021F 568E00            MOVE              X:<C000202,A
695       P:000220 P:000220 0D0383            JSR     <XMT_WRD                          ; Timing board header word
696       P:000221 P:000221 56F400            MOVE              #'ABR',A
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 14



                            414252
697       P:000223 P:000223 0D0383            JSR     <XMT_WRD                          ; Abort Readout
698    
699                                 ; Ensure that image data is no longer being received from the controller
700       P:000224 P:000224 01AD80  ABR0      JCLR    #EF,X:PDRD,ABR2                   ; Test for incoming FIFO data
                            00022A
701       P:000226 P:000226 09443F  ABR1      MOVEP             Y:RDFIFO,X0             ; Read the FIFO until its empty
702       P:000227 P:000227 000000            NOP
703       P:000228 P:000228 01ADA0            JSET    #EF,X:PDRD,ABR1
                            000226
704       P:00022A P:00022A 066089  ABR2      DO      #2400,ABR3                        ; Wait for about 30 microsec in case
                            00022C
705       P:00022C P:00022C 000000            NOP                                       ;   FIFO data is still arriving
706       P:00022D P:00022D 01ADA0  ABR3      JSET    #EF,X:PDRD,ABR1                   ; Keep emptying if more data arrived
                            000226
707       P:00022F P:00022F 012D24            BSET    #MODE,X:PDRD                      ; Put the fiber optics in 32-bit mode
708    
709                                 ; Clean up the PCI board from wherever it was executing
710                                 CLEAN_UP_PCI
711       P:000230 P:000230 08F4BF            MOVEP             #$0001C0,X:IPRC         ; Disable HF* FIFO interrupt
                            0001C0
712       P:000232 P:000232 0A8520            BSET    #HCIE,X:DCTR                      ; Enable host command interrupts
713       P:000233 P:000233 0501BB            MOVEC             #1,SP                   ; Point stack pointer to the top
714       P:000234 P:000234 05F43D            MOVEC             #$000200,SSL            ; SR = zero except for interrupts
                            000200
715       P:000236 P:000236 0500BB            MOVEC             #0,SP                   ; Writing to SSH preincrements the SP
716       P:000237 P:000237 05B2BC            MOVEC             #START,SSH              ; Set PC to for full initialization
717       P:000238 P:000238 000000            NOP
718       P:000239 P:000239 000004            RTI
719    
720                                 ; *************************************************************************
721                                 ;  There are several address register assignements in the Scatter/Gather
722                                 ;    routine that should not be disturbed
723                                 ;
724                                 ;       R1 - DRAM address of pixel being scaterred
725                                 ;       R5 - DRAM address of pixel being gathered
726                                 ;       R0, R3, R6 and R7 are not used in the Scatter/Gather routine
727                                 ;
728                                 ; *************************************************************************
729    
730                                 ; Read the image - change the serial receiver to expect 16-bit (image) data
731                                 READ_IMAGE
732       P:00023A P:00023A 0A8500            BCLR    #HCIE,X:DCTR                      ; Disable host command interrupts
733       P:00023B P:00023B 448A00            MOVE              X:<FLAG_RDI,X0
734       P:00023C P:00023C 441D00            MOVE              X0,X:<HOST_FLAG
735       P:00023D P:00023D 0D016E            JSR     <FO_WRITE_HOST_FLAG               ; Set HCTR bits to "reading out"
736       P:00023E P:00023E 084E0A            MOVEP             X:DPSR,A                ; Clear all PCI error conditions
737       P:00023F P:00023F 0140C2            OR      #$1FE,A
                            0001FE
738       P:000241 P:000241 000000            NOP
739       P:000242 P:000242 08CE0A            MOVEP             A,X:DPSR
740       P:000243 P:000243 0A862E            BSET    #CLRT,X:DPCR                      ; Clear the master transmitter FIFO
741       P:000244 P:000244 0A86AE            JSET    #CLRT,X:DPCR,*                    ; Wait for the clearing to be complete
                            000244
742    
743                                 ; Compute the number of pixels to read from the controller
744       P:000246 P:000246 0D03A5            JSR     <RD_FO_TIMEOUT                    ; Read number of columns
745       P:000247 P:000247 0E8179            JCS     <FO_ERR
746       P:000248 P:000248 21A500            MOVE              B1,X1
747       P:000249 P:000249 0D03A5            JSR     <RD_FO_TIMEOUT                    ; Read number of rows
748       P:00024A P:00024A 0E8179            JCS     <FO_ERR
749       P:00024B P:00024B 012D04            BCLR    #MODE,X:PDRD                      ; Put the fiber optics in 16-bit mode
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 15



750       P:00024C P:00024C 21A700            MOVE              B1,Y1                   ; Number of rows to read is in Y1
751       P:00024D P:00024D 2000F0            MPY     X1,Y1,A
752       P:00024E P:00024E 200022            ASR     A                                 ; Correct for 0 in LS bit after MPY
753       P:00024F P:00024F 20001B            CLR     B
754       P:000250 P:000250 541200            MOVE              A1,X:<NPXLS_1           ; NPXLS set by controller
755       P:000251 P:000251 501300            MOVE              A0,X:<NPXLS_0
756       P:000252 P:000252 551400            MOVE              B1,X:<IPXLS_1           ; IPXLS = 0
757       P:000253 P:000253 511500            MOVE              B0,X:<IPXLS_0
758       P:000254 P:000254 212500            MOVE              B0,X1                   ; 1/2 the FIFO depth
759       P:000255 P:000255 448C00            MOVE              X:<C512,X0
760       P:000256 P:000256 559A00            MOVE              X:<PCI_ADDR_1,B1        ; B = current PCI address
761       P:000257 P:000257 519B00            MOVE              X:<PCI_ADDR_0,B0
762    
763                                 ; There are three separate stages of writing the image to the PCI bus
764                                 ;       a. Write complete 512 pixel FIFO half full blocks
765                                 ;       b. Write the pixels left over from the last complete FIFO block
766                                 ;       c. Write one pixel if the image has an odd number of pixels
767    
768    
769                                 ; Compute the number of pixel pairs from the FIFO --> PCI bus
770       P:000258 P:000258 200013  L_FIFO    CLR     A
771       P:000259 P:000259 549200            MOVE              X:<NPXLS_1,A1           ; Number of pixels to write to PCI
772       P:00025A P:00025A 509300            MOVE              X:<NPXLS_0,A0
773       P:00025B P:00025B 479400            MOVE              X:<IPXLS_1,Y1           ; Compare it to image size
774       P:00025C P:00025C 469500            MOVE              X:<IPXLS_0,Y0
775       P:00025D P:00025D 000000            NOP
776       P:00025E P:00025E 200034            SUB     Y,A                               ; If (Image size - Ipxls)  <= 512
777       P:00025F P:00025F 000000            NOP                                       ;   we're at the end of the image
778       P:000260 P:000260 200024            SUB     X,A
779       P:000261 P:000261 0EF292            JLE     <WRITE_LAST_LITTLE_BIT_OF_IMAGE
780    
781                                 ; (a) Write complete 512 pixel (1/2 FIFO) image blocks to the PCI bus
782       P:000262 P:000262 468400            MOVE              X:<FOUR,Y0              ; Number of bytes per PCI write
783       P:000263 P:000263 270000            MOVE              #0,Y1
784                                 WR_IMAGE
785       P:000264 P:000264 01ADA1            JSET    #HF,X:PDRD,*                      ; Wait for FIFO to be half full + 1
                            000264
786       P:000266 P:000266 000000            NOP
787       P:000267 P:000267 000000            NOP
788       P:000268 P:000268 01ADA1            JSET    #HF,X:PDRD,WR_IMAGE               ; Protection against metastability
                            000264
789       P:00026A P:00026A 060081            DO      #256,WR_BLK1
                            000289
790       P:00026C P:00026C 0C1890            EXTRACTU #$010010,B,A                     ; Get D31-16 bits only. FC = 0 (32-bit)
                            010010
791       P:00026E P:00026E 000000            NOP
792       P:00026F P:00026F 08C807            MOVEP             A0,X:DPMC               ; DSP master control register
793       P:000270 P:000270 000000            NOP                                       ; FC = 0 -> 32-bit PCI writes
794       P:000271 P:000271 0C1890            EXTRACTU #$010000,B,A
                            010000
795       P:000273 P:000273 000000            NOP
796       P:000274 P:000274 210C00            MOVE              A0,A1
797       P:000275 P:000275 0140C2            OR      #$070000,A                        ; A1 gets written to DPAR register
                            070000
798       P:000277 P:000277 000000            NOP
799       P:000278 P:000278 0970BF            MOVEP             Y:RDFIFO,X:DTXM         ; Least significant word to transmit
                            FFFFCC
800       P:00027A P:00027A 0970BF            MOVEP             Y:RDFIFO,X:DTXM         ; Most significant word to transmit
                            FFFFCC
801       P:00027C P:00027C 08CC08  AGAIN1    MOVEP             A1,X:DPAR               ; Write to PCI bus
802       P:00027D P:00027D 000000            NOP                                       ; Pipeline delay
803       P:00027E P:00027E 000000            NOP                                       ; Pipeline delay
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 16



804    
805       P:00027F P:00027F 0A8A84            JCLR    #MARQ,X:DPSR,*                    ; Bit is clear if PCI still in progress
                            00027F
806       P:000281 P:000281 0A8AAE            JSET    #14,X:DPSR,WR_OK1                 ; MDT bit
                            000288
807       P:000283 P:000283 0A8A8A            JCLR    #TRTY,X:DPSR,END_WR               ; Error if its not a retry
                            0002DE
808       P:000285 P:000285 08F48A            MOVEP             #$0400,X:DPSR           ; Clear bit 10 = target retry bit
                            000400
809       P:000287 P:000287 0C027C            JMP     <AGAIN1
810    
811       P:000288 P:000288 200038  WR_OK1    ADD     Y,B                               ; Increment PCI address
812       P:000289 P:000289 000000            NOP
813                                 WR_BLK1
814    
815                                 ; Re-calculate and store the PCI address where image data is being written to
816       P:00028A P:00028A 509500            MOVE              X:<IPXLS_0,A0           ; Number of pixels to write to PCI
817       P:00028B P:00028B 549400            MOVE              X:<IPXLS_1,A1
818       P:00028C P:00028C 200020            ADD     X,A                               ; X = 512 = 1/2 FIFO size
819       P:00028D P:00028D 000000            NOP
820       P:00028E P:00028E 501500            MOVE              A0,X:<IPXLS_0           ; Number of pixels to write to PCI
821       P:00028F P:00028F 541400            MOVE              A1,X:<IPXLS_1
822       P:000290 P:000290 0D02E7            JSR     <C_RPXLS                          ; Calculate number of pixels read
823       P:000291 P:000291 0C0258            JMP     <L_FIFO                           ; Go process the next 1/2 FIFO
824    
825                                 ; (b) Write the pixels left over
826                                 WRITE_LAST_LITTLE_BIT_OF_IMAGE
827       P:000292 P:000292 468400            MOVE              X:<FOUR,Y0              ; Number of bytes per PCI write
828       P:000293 P:000293 270000            MOVE              #0,Y1
829       P:000294 P:000294 0A0000            BCLR    #ODD,X:<STATUS
830       P:000295 P:000295 200020            ADD     X,A
831       P:000296 P:000296 200022            ASR     A                                 ; Two pixels written per loop
832       P:000297 P:000297 0E0299            JCC     *+2
833       P:000298 P:000298 0A0020            BSET    #ODD,X:<STATUS                    ; ODD = 1 if carry bit is set
834       P:000299 P:000299 06C800            DO      A0,WR_BLK2
                            0002BC
835       P:00029B P:00029B 0C1890            EXTRACTU #$010010,B,A                     ; Get D31-16 bits only. FC = 0 (32-bit)
                            010010
836       P:00029D P:00029D 000000            NOP
837       P:00029E P:00029E 08C807            MOVEP             A0,X:DPMC               ; DSP master control register
838       P:00029F P:00029F 000000            NOP                                       ; FC = 0 -> 32-bit PCI writes
839       P:0002A0 P:0002A0 0C1890            EXTRACTU #$010000,B,A
                            010000
840       P:0002A2 P:0002A2 000000            NOP
841       P:0002A3 P:0002A3 210C00            MOVE              A0,A1
842       P:0002A4 P:0002A4 0140C2            OR      #$070000,A                        ; A1 gets written to DPAR register
                            070000
843       P:0002A6 P:0002A6 000000            NOP
844    
845       P:0002A7 P:0002A7 01AD80            JCLR    #EF,X:PDRD,*
                            0002A7
846       P:0002A9 P:0002A9 0970BF            MOVEP             Y:RDFIFO,X:DTXM         ; Least significant word to transmit
                            FFFFCC
847       P:0002AB P:0002AB 01AD80            JCLR    #EF,X:PDRD,*
                            0002AB
848       P:0002AD P:0002AD 0970BF            MOVEP             Y:RDFIFO,X:DTXM         ; Most significant word to transmit
                            FFFFCC
849       P:0002AF P:0002AF 08CC08  AGAIN2    MOVEP             A1,X:DPAR               ; Write to PCI bus
850       P:0002B0 P:0002B0 000000            NOP                                       ; Pipeline delay
851       P:0002B1 P:0002B1 000000            NOP                                       ; Pipeline delay
852    
853       P:0002B2 P:0002B2 0A8A84            JCLR    #MARQ,X:DPSR,*                    ; Bit is clear if PCI still in progress
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 17



                            0002B2
854       P:0002B4 P:0002B4 0A8AAE            JSET    #14,X:DPSR,WR_OK2                 ; MDT bit
                            0002BB
855       P:0002B6 P:0002B6 0A8A8A            JCLR    #TRTY,X:DPSR,END_WR               ; Bit is set if its a retry
                            0002DE
856       P:0002B8 P:0002B8 08F48A            MOVEP             #$0400,X:DPSR           ; Clear bit 10 = target retry bit
                            000400
857       P:0002BA P:0002BA 0C02AF            JMP     <AGAIN2
858    
859       P:0002BB P:0002BB 200038  WR_OK2    ADD     Y,B                               ; Increment PCI address
860       P:0002BC P:0002BC 000000            NOP
861                                 WR_BLK2
862    
863                                 ; (c) Write the very last pixel if there is an odd number of pixels in the image
864       P:0002BD P:0002BD 0A0080            JCLR    #ODD,X:STATUS,END_WR
                            0002DE
865       P:0002BF P:0002BF 0C1890            EXTRACTU #$010010,B,A                     ; Get D31-16 bits only. FC = 0 (32-bit)
                            010010
866       P:0002C1 P:0002C1 000000            NOP
867       P:0002C2 P:0002C2 0AC876            BSET    #22,A0                            ; FC mode = 1
868       P:0002C3 P:0002C3 000000            NOP
869       P:0002C4 P:0002C4 08C807            MOVEP             A0,X:DPMC               ; DSP master control register
870       P:0002C5 P:0002C5 000000            NOP
871       P:0002C6 P:0002C6 0C1890            EXTRACTU #$010000,B,A
                            010000
872       P:0002C8 P:0002C8 0140C8            ADD     #>2,B                             ; Increment PCI address
                            000002
873       P:0002CA P:0002CA 210C00            MOVE              A0,A1
874       P:0002CB P:0002CB 0140C2            OR      #$C70000,A                        ; Write 16 LS bits only
                            C70000
875       P:0002CD P:0002CD 000000            NOP
876       P:0002CE P:0002CE 01AD80            JCLR    #EF,X:PDRD,*
                            0002CE
877       P:0002D0 P:0002D0 0970BF            MOVEP             Y:RDFIFO,X:DTXM         ; Least significant word to transmit
                            FFFFCC
878       P:0002D2 P:0002D2 08CC08  AGAIN3    MOVEP             A1,X:DPAR               ; Write to PCI bus
879       P:0002D3 P:0002D3 000000            NOP                                       ; Pipeline delay
880       P:0002D4 P:0002D4 000000            NOP                                       ; Pipeline delay
881    
882       P:0002D5 P:0002D5 0A8A84            JCLR    #MARQ,X:DPSR,*                    ; Bit is clear if PCI still in progress
                            0002D5
883       P:0002D7 P:0002D7 0A8AAE            JSET    #14,X:DPSR,END_WR                 ; MDT bit
                            0002DE
884       P:0002D9 P:0002D9 0A8A8A            JCLR    #TRTY,X:DPSR,END_WR               ; Bit is set if its a retry
                            0002DE
885       P:0002DB P:0002DB 08F48A            MOVEP             #$0400,X:DPSR           ; Clear bit 10 = target retry bit
                            000400
886       P:0002DD P:0002DD 0C02D2            JMP     <AGAIN3
887    
888                                 ; Calculate and store the PCI address where image data is being written to
889       P:0002DE P:0002DE 0D02E7  END_WR    JSR     <C_RPXLS                          ; Calculate number of pixels read
890       P:0002DF P:0002DF 511B00            MOVE              B0,X:<PCI_ADDR_0        ; Update PCI Address
891       P:0002E0 P:0002E0 551A00            MOVE              B1,X:<PCI_ADDR_1
892    
893       P:0002E1 P:0002E1 012D24            BSET    #MODE,X:PDRD                      ; Put the fiber optics in 32-bit mode
894    
895       P:0002E2 P:0002E2 448600            MOVE              X:<FLAG_DONE,X0
896       P:0002E3 P:0002E3 441D00            MOVE              X0,X:<HOST_FLAG
897       P:0002E4 P:0002E4 0D016E            JSR     <FO_WRITE_HOST_FLAG               ; Clear Host Flag to 'DONE'
898    
899       P:0002E5 P:0002E5 0A8520            BSET    #HCIE,X:DCTR                      ; Enable host command interrupts
900       P:0002E6 P:0002E6 0C010E            JMP     <GET_FO                           ; We're all done, go process FO input
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 18



901    
902                                 ; R_PXLS is the number of pixels read out since the last IIA command
903       P:0002E7 P:0002E7 200013  C_RPXLS   CLR     A
904       P:0002E8 P:0002E8 469900            MOVE              X:<BASE_ADDR_0,Y0       ; BASE_ADDR is 2 x 16-bits
905       P:0002E9 P:0002E9 479800            MOVE              X:<BASE_ADDR_1,Y1
906       P:0002EA P:0002EA 212800            MOVE              B0,A0                   ; B is current PCI address
907       P:0002EB P:0002EB 21AC00            MOVE              B1,A1
908       P:0002EC P:0002EC 000000            NOP
909       P:0002ED P:0002ED 200034            SUB     Y,A                               ; Current PCI address - BASE address
910       P:0002EE P:0002EE 200022            ASR     A                                 ; /2 => convert byte address to pixel
911       P:0002EF P:0002EF 000000            NOP
912    
913       P:0002F0 P:0002F0 501700            MOVE              A0,X:<R_PXLS_0          ; R_PXLS is 2 x 16 bits, number of
914       P:0002F1 P:0002F1 0C1880            EXTRACTU #$010010,A,A                     ;   image pixels read so far
                            010010
915       P:0002F3 P:0002F3 000000            NOP
916       P:0002F4 P:0002F4 501600            MOVE              A0,X:<R_PXLS_1
917       P:0002F5 P:0002F5 00000C            RTS
918    
919                                 ; ***** Test Data Link, Read Memory and Write Memory Commands ******
920    
921                                 ; Test the data link by echoing back ARG1
922                                 TEST_DATA_LINK
923       P:0002F6 P:0002F6 44B200            MOVE              X:<ARG1,X0
924       P:0002F7 P:0002F7 0C0356            JMP     <FINISH1
925    
926                                 ; Read from PCI memory. The address is masked to 16 bits, so only
927                                 ;   the bottom 64k words of DRAM will be accessed.
928                                 READ_MEMORY
929       P:0002F8 P:0002F8 56B200            MOVE              X:<ARG1,A               ; Get the address in an accumulator
930       P:0002F9 P:0002F9 0140C6            AND     #$FFFF,A                          ; Mask off only 16 address bits
                            00FFFF
931       P:0002FB P:0002FB 219000            MOVE              A1,R0                   ; Get the address in an address register
932       P:0002FC P:0002FC 56B200            MOVE              X:<ARG1,A               ; Get the address in an accumulator
933       P:0002FD P:0002FD 000000            NOP
934       P:0002FE P:0002FE 0ACE14            JCLR    #20,A,RDX                         ; Test address bit for Program memory
                            000302
935       P:000300 P:000300 07E084            MOVE              P:(R0),X0               ; Read from Program Memory
936       P:000301 P:000301 0C0356            JMP     <FINISH1                          ; Send out a header with the value
937       P:000302 P:000302 0ACE15  RDX       JCLR    #21,A,RDY                         ; Test address bit for X: memory
                            000306
938       P:000304 P:000304 44E000            MOVE              X:(R0),X0               ; Write to X data memory
939       P:000305 P:000305 0C0356            JMP     <FINISH1                          ; Send out a header with the value
940       P:000306 P:000306 0ACE16  RDY       JCLR    #22,A,RDR                         ; Test address bit for Y: memory
                            00030A
941       P:000308 P:000308 4CE000            MOVE                          Y:(R0),X0   ; Read from Y data memory
942       P:000309 P:000309 0C0356            JMP     <FINISH1                          ; Send out a header with the value
943       P:00030A P:00030A 0ACE17  RDR       JCLR    #23,A,ERROR                       ; Test address bit for read from EEPROM memo
ry
                            00035A
944    
945                                 ; Read the word from the PCI board EEPROM
946       P:00030C P:00030C 013D21            BSET    #1,X:PDRC                         ; ROM/FIFO* = 1 to select ROM
947       P:00030D P:00030D 08F4B8            MOVEP             #$008C29,X:AAR1         ; P: = $008000 to $008777 asserts AA1 low tr
ue
                            008C29
948       P:00030F P:00030F 08F4BB            MOVEP             #$0002A0,X:BCR          ; Bus Control Register for slow EEPROM
                            0002A0
949       P:000311 P:000311 458300            MOVE              X:<THREE,X1             ; Convert to word address to a byte address
950       P:000312 P:000312 220400            MOVE              R0,X0                   ; Get 16-bit address in a data register
951       P:000313 P:000313 2000A0            MPY     X1,X0,A                           ; Multiply
952       P:000314 P:000314 200022            ASR     A                                 ; Eliminate zero fill of fractional multiply
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 19



953       P:000315 P:000315 211000            MOVE              A0,R0                   ; Need to address memory
954       P:000316 P:000316 0AD06F            BSET    #15,R0                            ; Set bit so its in EEPROM space
955       P:000317 P:000317 060380            DO      #3,L1RDR
                            00031B
956       P:000319 P:000319 07D88A            MOVE              P:(R0)+,A2              ; Read each ROM byte
957       P:00031A P:00031A 0C1C10            ASR     #8,A,A                            ; Move right into A1
958       P:00031B P:00031B 000000            NOP
959                                 L1RDR
960       P:00031C P:00031C 218400            MOVE              A1,X0                   ; Prepare for FINISH1
961       P:00031D P:00031D 013D01            BCLR    #1,X:PDRC                         ; ROM/FIFO* = 0 to select FIFO
962       P:00031E P:00031E 08F4B8            MOVEP             #$FFFC21,X:AAR1         ; Restore FIFO addressing
                            FFFC21
963       P:000320 P:000320 08F4BB            MOVEP             #$000020,X:BCR          ; Restore fast FIFO access
                            000020
964       P:000322 P:000322 0C0356            JMP     <FINISH1
965    
966                                 ; Program WRMEM - write to PCI memory, reply = DONE host flags. The address is
967                                 ;  masked to 16 bits, so only the bottom 64k words of DRAM will be accessed.
968                                 WRITE_MEMORY
969       P:000323 P:000323 56B200            MOVE              X:<ARG1,A               ; Get the address in an accumulator
970       P:000324 P:000324 0140C6            AND     #$FFFF,A                          ; Mask off only 16 address bits
                            00FFFF
971       P:000326 P:000326 219000            MOVE              A1,R0                   ; Get the address in an address register
972       P:000327 P:000327 56B200            MOVE              X:<ARG1,A               ; Get the address in an accumulator
973       P:000328 P:000328 44B300            MOVE              X:<ARG2,X0              ; Get the data to be written
974       P:000329 P:000329 0ACE14            JCLR    #20,A,WRX                         ; Test address bit for Program memory
                            00032D
975       P:00032B P:00032B 076084            MOVE              X0,P:(R0)               ; Write to Program memory
976       P:00032C P:00032C 0C0353            JMP     <FINISH
977       P:00032D P:00032D 0ACE15  WRX       JCLR    #21,A,WRY                         ; Test address bit for X: memory
                            000331
978       P:00032F P:00032F 446000            MOVE              X0,X:(R0)               ; Write to X: memory
979       P:000330 P:000330 0C0353            JMP     <FINISH
980       P:000331 P:000331 0ACE16  WRY       JCLR    #22,A,WRR                         ; Test address bit for Y: memory
                            000335
981       P:000333 P:000333 4C6000            MOVE                          X0,Y:(R0)   ; Write to Y: memory
982       P:000334 P:000334 0C0353            JMP     <FINISH
983       P:000335 P:000335 0ACE17  WRR       JCLR    #23,A,ERROR                       ; Test address bit for write to EEPROM
                            00035A
984    
985                                 ; Write the word to the on-board PCI EEPROM
986       P:000337 P:000337 013D21            BSET    #1,X:PDRC                         ; ROM/FIFO* = 1 to select ROM
987       P:000338 P:000338 08F4B8            MOVEP             #$008C29,X:AAR1         ; P: = $008000 to $008777 asserts AA1 low tr
ue
                            008C29
988       P:00033A P:00033A 08F4BB            MOVEP             #$0002A0,X:BCR          ; Bus Control Register for slow EEPROM
                            0002A0
989       P:00033C P:00033C 458300            MOVE              X:<THREE,X1             ; Convert to word address to a byte address
990       P:00033D P:00033D 220400            MOVE              R0,X0                   ; Get 16-bit address in a data register
991       P:00033E P:00033E 2000A0            MPY     X1,X0,A                           ; Multiply
992       P:00033F P:00033F 200022            ASR     A                                 ; Eliminate zero fill of fractional multiply
993       P:000340 P:000340 211000            MOVE              A0,R0                   ; Need to address memory
994       P:000341 P:000341 0AD06F            BSET    #15,R0                            ; Set bit so its in EEPROM space
995       P:000342 P:000342 56B300            MOVE              X:<ARG2,A               ; Get the data to be written, again
996       P:000343 P:000343 060380            DO      #3,L1WRR                          ; Loop over three bytes of the word
                            00034C
997       P:000345 P:000345 07588C            MOVE              A1,P:(R0)+              ; Write each EEPROM byte
998       P:000346 P:000346 0C1C10            ASR     #8,A,A                            ; Move right one byte
999       P:000347 P:000347 44F400            MOVE              #400000,X0
                            061A80
1000      P:000349 P:000349 06C400            DO      X0,L2WRR                          ; Delay by 5 millisec for EEPROM write
                            00034B
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 20



1001      P:00034B P:00034B 000000            NOP
1002                                L2WRR
1003      P:00034C P:00034C 000000            NOP                                       ; DO loop nesting restriction
1004                                L1WRR
1005      P:00034D P:00034D 013D01            BCLR    #1,X:PDRC                         ; ROM/FIFO* = 0 to select FIFO
1006      P:00034E P:00034E 08F4B8            MOVEP             #$FFFC21,X:AAR1         ; Restore FIFO addressing
                            FFFC21
1007      P:000350 P:000350 08F4BB            MOVEP             #$000020,X:BCR          ; Restore fast FIFO access
                            000020
1008      P:000352 P:000352 0C0353            JMP     <FINISH
1009   
1010                                ;  ***** Subroutines for generating replies to command execution ******
1011                                ; Return from the interrupt with a reply = DONE host flags
1012      P:000353 P:000353 448600  FINISH    MOVE              X:<FLAG_DONE,X0         ; Flag = 1 => Normal execution
1013      P:000354 P:000354 441D00            MOVE              X0,X:<HOST_FLAG
1014      P:000355 P:000355 0C0363            JMP     <RTI_WRITE_HOST_FLAG
1015   
1016                                ; Return from the interrupt with value in (X1,X0)
1017      P:000356 P:000356 441C00  FINISH1   MOVE              X0,X:<REPLY             ; Report value
1018      P:000357 P:000357 448700            MOVE              X:<FLAG_REPLY,X0        ; Flag = 2 => Reply with a value
1019      P:000358 P:000358 441D00            MOVE              X0,X:<HOST_FLAG
1020      P:000359 P:000359 0C0363            JMP     <RTI_WRITE_HOST_FLAG
1021   
1022                                ; Routine for returning from the interrupt on an error
1023      P:00035A P:00035A 448800  ERROR     MOVE              X:<FLAG_ERR,X0          ; Flag = 3 => Error value
1024      P:00035B P:00035B 441D00            MOVE              X0,X:<HOST_FLAG
1025      P:00035C P:00035C 0C0363            JMP     <RTI_WRITE_HOST_FLAG
1026   
1027                                ; Routine for returning from the interrupt with a system reset
1028      P:00035D P:00035D 448900  SYR       MOVE              X:<FLAG_SYR,X0          ; Flag = 4 => System reset
1029      P:00035E P:00035E 441D00            MOVE              X0,X:<HOST_FLAG
1030      P:00035F P:00035F 0C0363            JMP     <RTI_WRITE_HOST_FLAG
1031   
1032                                ; Routine for returning a BUSY status from the controller
1033      P:000360 P:000360 448B00  BUSY      MOVE              X:<FLAG_BUSY,X0         ; Flag = 6 => Controller is busy
1034      P:000361 P:000361 441D00            MOVE              X0,X:<HOST_FLAG
1035      P:000362 P:000362 0C0363            JMP     <RTI_WRITE_HOST_FLAG
1036   
1037                                ; Write X:<HOST_FLAG to the DCTR flag bits 5,4,3, as an interrupt
1038                                RTI_WRITE_HOST_FLAG
1039      P:000363 P:000363 56F000            MOVE              X:DCTR,A
                            FFFFC5
1040      P:000365 P:000365 449D00            MOVE              X:<HOST_FLAG,X0
1041      P:000366 P:000366 0140C6            AND     #$FFFFC7,A                        ; Clear bits 5,4,3
                            FFFFC7
1042      P:000368 P:000368 000000            NOP
1043      P:000369 P:000369 200042            OR      X0,A                              ; Set flags appropriately
1044      P:00036A P:00036A 000000            NOP
1045      P:00036B P:00036B 567000            MOVE              A,X:DCTR
                            FFFFC5
1046      P:00036D P:00036D 000004            RTI
1047   
1048                                ; Put the reply value into the transmitter FIFO
1049                                READ_REPLY_VALUE
1050      P:00036E P:00036E 08F08D            MOVEP             X:REPLY,X:DTXS          ; DSP-to-host slave transmit
                            00001C
1051      P:000370 P:000370 000004            RTI
1052   
1053                                READ_REPLY_HEADER
1054      P:000371 P:000371 44B000            MOVE              X:<HEADER,X0
1055      P:000372 P:000372 0C0356            JMP     <FINISH1
1056   
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 21



1057                                ; Clear the reply flags and receiver FIFO after a successful reply transaction,
1058                                ;   but leave the Read Image flags set if the controller is reading out.
1059                                CLEAR_HOST_FLAG
1060      P:000373 P:000373 448500            MOVE              X:<FLAG_ZERO,X0
1061      P:000374 P:000374 441D00            MOVE              X0,X:<HOST_FLAG
1062      P:000375 P:000375 44F400            MOVE              #$FFFFC7,X0
                            FFFFC7
1063      P:000377 P:000377 56F000            MOVE              X:DCTR,A
                            FFFFC5
1064      P:000379 P:000379 200046            AND     X0,A
1065      P:00037A P:00037A 000000            NOP
1066      P:00037B P:00037B 547000            MOVE              A1,X:DCTR
                            FFFFC5
1067   
1068      P:00037D P:00037D 0A8982  CLR_RCV   JCLR    #SRRQ,X:DSR,CLR_RTS               ; Wait for the receiver to be empty
                            000382
1069      P:00037F P:00037F 08440B            MOVEP             X:DRXR,X0               ; Read receiver to empty it
1070      P:000380 P:000380 000000            NOP                                       ; Wait for flag to change
1071      P:000381 P:000381 0C037D            JMP     <CLR_RCV
1072                                CLR_RTS
1073      P:000382 P:000382 000004            RTI
1074   
1075                                ; *************  Miscellaneous subroutines used everywhere  *************
1076   
1077                                ; Transmit contents of Accumulator A1 to the timing board
1078      P:000383 P:000383 567000  XMT_WRD   MOVE              A,X:SV_A
                            000011
1079      P:000385 P:000385 01B786            JCLR    #TDE,X:SSISR0,*
                            000385
1080      P:000387 P:000387 07F43C            MOVEP             #$000000,X:TX00
                            000000
1081      P:000389 P:000389 0D03A3            JSR     <XMT_DLY
1082      P:00038A P:00038A 01B786            JCLR    #TDE,X:SSISR0,*                   ; Start bit
                            00038A
1083      P:00038C P:00038C 07F43C            MOVEP             #$010000,X:TX00
                            010000
1084      P:00038E P:00038E 0D03A3            JSR     <XMT_DLY
1085      P:00038F P:00038F 01B786            JCLR    #TDE,X:SSISR0,*
                            00038F
1086      P:000391 P:000391 07F43C            MOVEP             #$AC0000,X:TX00         ; Preamble byte
                            AC0000
1087      P:000393 P:000393 0D03A3            JSR     <XMT_DLY
1088      P:000394 P:000394 060380            DO      #3,L_XMIT
                            00039A
1089      P:000396 P:000396 01B786            JCLR    #TDE,X:SSISR0,*                   ; Three data bytes
                            000396
1090      P:000398 P:000398 04CCDC            MOVEP             A1,X:TX00
1091      P:000399 P:000399 0D03A3            JSR     <XMT_DLY
1092      P:00039A P:00039A 0C1E90            LSL     #8,A
1093                                L_XMIT
1094      P:00039B P:00039B 01B786            JCLR    #TDE,X:SSISR0,*                   ; Zeroes to bring TX00 low
                            00039B
1095      P:00039D P:00039D 07F43C            MOVEP             #$000000,X:TX00
                            000000
1096      P:00039F P:00039F 0D03A3            JSR     <XMT_DLY
1097      P:0003A0 P:0003A0 56F000            MOVE              X:SV_A,A
                            000011
1098      P:0003A2 P:0003A2 00000C            RTS
1099   
1100                                ; Short delay for reliability
1101      P:0003A3 P:0003A3 000000  XMT_DLY   NOP
1102      P:0003A4 P:0003A4 00000C            RTS
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 22



1103   
1104                                ; Read one word of the fiber optic FIFO into B1 with a timeout
1105                                RD_FO_TIMEOUT
1106      P:0003A5 P:0003A5 46F400            MOVE              #1000000,Y0             ; 13 millisecond timeout
                            0F4240
1107      P:0003A7 P:0003A7 06C600            DO      Y0,LP_TIM
                            0003B1
1108      P:0003A9 P:0003A9 01AD80            JCLR    #EF,X:PDRD,NOT_YET                ; Test for new fiber optic data
                            0003B1
1109      P:0003AB P:0003AB 000000            NOP
1110      P:0003AC P:0003AC 000000            NOP
1111      P:0003AD P:0003AD 01AD80            JCLR    #EF,X:PDRD,NOT_YET                ; For metastability, check it twice
                            0003B1
1112      P:0003AF P:0003AF 00008C            ENDDO
1113      P:0003B0 P:0003B0 0C03B6            JMP     <RD_FIFO                          ; Go read the FIFO word
1114      P:0003B1 P:0003B1 000000  NOT_YET   NOP
1115      P:0003B2 P:0003B2 000000  LP_TIM    NOP
1116      P:0003B3 P:0003B3 0AF960            BSET    #0,SR                             ; Timeout reached, error return
1117      P:0003B4 P:0003B4 000000            NOP
1118      P:0003B5 P:0003B5 00000C            RTS
1119   
1120                                ; Read one word from the fiber optics FIFO, check it and put it in B1
1121      P:0003B6 P:0003B6 09463F  RD_FIFO   MOVEP             Y:RDFIFO,Y0             ; Read the FIFO word
1122      P:0003B7 P:0003B7 578D00            MOVE              X:<C00FF00,B            ; DMASK = $00FF00
1123      P:0003B8 P:0003B8 20005E            AND     Y0,B
1124      P:0003B9 P:0003B9 0140CD            CMP     #$00AC00,B
                            00AC00
1125      P:0003BB P:0003BB 0EA3C8            JEQ     <GT_RPLY                          ; If byte equalS $AC then continue
1126      P:0003BC P:0003BC 07F42D            MOVEP             #%010000,X:PDRD         ; Clear RS* low for 2 milliseconds
                            000010
1127      P:0003BE P:0003BE 47F400            MOVE              #200000,Y1
                            030D40
1128      P:0003C0 P:0003C0 06C700            DO      Y1,*+3
                            0003C2
1129      P:0003C2 P:0003C2 000000            NOP
1130      P:0003C3 P:0003C3 07F42D            MOVEP             #%010100,X:PDRD         ; Data Register - Set RS* high
                            000014
1131      P:0003C5 P:0003C5 0AF960            BSET    #0,SR                             ; Set carry bit => error
1132      P:0003C6 P:0003C6 000000            NOP
1133      P:0003C7 P:0003C7 00000C            RTS
1134   
1135      P:0003C8 P:0003C8 20CF00  GT_RPLY   MOVE              Y0,B
1136      P:0003C9 P:0003C9 0C1EA1            LSL     #16,B                             ; Shift byte in D7-D0 to D23-D16
1137      P:0003CA P:0003CA 000000            NOP
1138      P:0003CB P:0003CB 21A700            MOVE              B1,Y1
1139      P:0003CC P:0003CC 4EF000            MOVE                          Y:RDFIFO,Y0 ; Read the FIFO word
                            FFFFFF
1140      P:0003CE P:0003CE 57F400            MOVE              #$00FFFF,B
                            00FFFF
1141      P:0003D0 P:0003D0 20005E            AND     Y0,B                              ; Select out D15-D0
1142      P:0003D1 P:0003D1 20007A            OR      Y1,B                              ; Add D23-D16 to D15-D0
1143      P:0003D2 P:0003D2 000000            NOP
1144      P:0003D3 P:0003D3 000000            NOP
1145      P:0003D4 P:0003D4 0AF940            BCLR    #0,SR                             ; Clear carry bit => no error
1146      P:0003D5 P:0003D5 000000            NOP
1147      P:0003D6 P:0003D6 00000C            RTS
1148   
1149   
1150                                ; This might work with some effort
1151                                ;GT_RPLY        MOVE    Y:RDFIFO,B              ; Read the FIFO word
1152                                ;       EXTRACTU #$010018,B,B
1153                                ;       INSERT  #$008000,Y0,B           ; Add MSB to D23-D16
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 23



1154                                ;       NOP
1155                                ;       MOVE    B0,B1
1156                                ;       NOP
1157                                ;       NOP
1158                                ;       BCLR    #0,SR                   ; Clear carry bit => no error
1159                                ;       NOP
1160                                ;       RTS
1161   
1162                                ; ************************  Test on board DRAM  ***********************
1163                                ; Test Y: memory mapped to AA0 and AA2 from $000000 to $FFFFFF (16 megapixels)
1164                                ; DRAM definitions
1165   
1166                                TEST_DRAM
1167   
1168                                ; Test Y: memory mapped to AA0 and AA2 from $000000 to $FFFFFF (16 megapixels)
1169      P:0003D7 P:0003D7 200013            CLR     A
1170      P:0003D8 P:0003D8 240100            MOVE              #$10000,X0              ; Y:$000000 to Y:$FEFFFF
1171      P:0003D9 P:0003D9 21D000            MOVE              A,R0
1172      P:0003DA P:0003DA 06FF80            DO      #$FF,L_WRITE_RAM1
                            0003E2
1173      P:0003DC P:0003DC 06C400            DO      X0,L_WRITE_RAM0
                            0003E0
1174      P:0003DE P:0003DE 5C5800            MOVE                          A1,Y:(R0)+
1175      P:0003DF P:0003DF 014180            ADD     #1,A
1176      P:0003E0 P:0003E0 000000            NOP
1177                                L_WRITE_RAM0
1178      P:0003E1 P:0003E1 0D0420            JSR     <TRM_BUSY                         ; 'TRM' is still busy
1179      P:0003E2 P:0003E2 000000            NOP
1180                                L_WRITE_RAM1
1181   
1182      P:0003E3 P:0003E3 200013            CLR     A
1183      P:0003E4 P:0003E4 240100            MOVE              #$10000,X0
1184      P:0003E5 P:0003E5 21D000            MOVE              A,R0
1185      P:0003E6 P:0003E6 06FF80            DO      #$FF,L_CHECK_RAM1
                            0003F3
1186      P:0003E8 P:0003E8 06C400            DO      X0,L_CHECK_RAM0
                            0003F1
1187      P:0003EA P:0003EA 4DD800            MOVE                          Y:(R0)+,X1
1188      P:0003EB P:0003EB 0C1FFC            CMPU    X1,A
1189      P:0003EC P:0003EC 0EA3F0            JEQ     <L_RAM4
1190      P:0003ED P:0003ED 00008C            ENDDO
1191      P:0003EE P:0003EE 00008C            ENDDO
1192      P:0003EF P:0003EF 0C0416            JMP     <ERROR_Y
1193      P:0003F0 P:0003F0 014180  L_RAM4    ADD     #1,A
1194      P:0003F1 P:0003F1 000000            NOP
1195                                L_CHECK_RAM0
1196      P:0003F2 P:0003F2 0D0420            JSR     <TRM_BUSY                         ; 'TRM' is still busy
1197      P:0003F3 P:0003F3 000000            NOP
1198                                L_CHECK_RAM1
1199   
1200                                ; Test X: memory mapped to AA3 from $1000 to $7FFFFF (8 megapixels)
1201      P:0003F4 P:0003F4 200013            CLR     A
1202      P:0003F5 P:0003F5 60F400            MOVE              #$1000,R0               ; Skip over internal X: memory
                            001000
1203      P:0003F7 P:0003F7 44F400            MOVE              #$1000,X0               ; X:$001000 to X:$7FFFF
                            001000
1204      P:0003F9 P:0003F9 06FF87            DO      #$7FF,L_WRITE_RAM3
                            000401
1205      P:0003FB P:0003FB 06C400            DO      X0,L_WRITE_RAM4
                            0003FF
1206      P:0003FD P:0003FD 565800            MOVE              A,X:(R0)+
1207      P:0003FE P:0003FE 014180            ADD     #1,A
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 24



1208      P:0003FF P:0003FF 000000            NOP
1209                                L_WRITE_RAM4
1210      P:000400 P:000400 0D0420            JSR     <TRM_BUSY                         ; 'TRM' is still busy
1211      P:000401 P:000401 000000            NOP
1212                                L_WRITE_RAM3
1213   
1214      P:000402 P:000402 200013            CLR     A
1215      P:000403 P:000403 60F400            MOVE              #$1000,R0
                            001000
1216      P:000405 P:000405 44F400            MOVE              #$1000,X0
                            001000
1217      P:000407 P:000407 06FF87            DO      #$7FF,L_CHECK_RAM5
                            000414
1218      P:000409 P:000409 06C400            DO      X0,L_CHECK_RAM6
                            000412
1219      P:00040B P:00040B 45D800            MOVE              X:(R0)+,X1
1220      P:00040C P:00040C 0C1FFC            CMPU    X1,A
1221      P:00040D P:00040D 0EA411            JEQ     <L_RAM5
1222      P:00040E P:00040E 00008C            ENDDO
1223      P:00040F P:00040F 00008C            ENDDO
1224      P:000410 P:000410 0C041B            JMP     <ERROR_X
1225      P:000411 P:000411 014180  L_RAM5    ADD     #1,A
1226      P:000412 P:000412 000000            NOP
1227                                L_CHECK_RAM6
1228      P:000413 P:000413 0D0420            JSR     <TRM_BUSY                         ; 'TRM' is still busy
1229      P:000414 P:000414 000000            NOP
1230                                L_CHECK_RAM5
1231   
1232      P:000415 P:000415 0C0353            JMP     <FINISH                           ; Successful memory test
1233   
1234      P:000416 P:000416 44F400  ERROR_Y   MOVE              #'__Y',X0
                            5F5F59
1235      P:000418 P:000418 450F00            MOVE              X1,X:<TRM_MEM
1236      P:000419 P:000419 601000            MOVE              R0,X:<TRM_ADR
1237      P:00041A P:00041A 0C035A            JMP     <ERROR
1238      P:00041B P:00041B 44F400  ERROR_X   MOVE              #'__X',X0
                            5F5F58
1239      P:00041D P:00041D 450F00            MOVE              X1,X:<TRM_MEM
1240      P:00041E P:00041E 601000            MOVE              R0,X:<TRM_ADR
1241      P:00041F P:00041F 0C035A            JMP     <ERROR
1242   
1243                                TRM_BUSY
1244      P:000420 P:000420 478B00            MOVE              X:<FLAG_BUSY,Y1         ; Flag = 6 => controller busy
1245      P:000421 P:000421 471D00            MOVE              Y1,X:<HOST_FLAG
1246      P:000422 P:000422 0D016E            JSR     <FO_WRITE_HOST_FLAG
1247      P:000423 P:000423 00000C            RTS
1248   
1249                                ;  ****************  Setup memory tables in X: space ********************
1250   
1251                                ; Define the address in P: space where the table of constants begins
1252   
1253      X:000000 P:000424                   ORG     X:VAR_TBL,P:
1254   
1255                                ; Parameters
1256      X:000000 P:000424         STATUS    DC      0                                 ; Execution status bits
1257      X:000001 P:000425                   DC      0                                 ; Reserved
1258   
1259                                          IF      @SCP("HOST","HOST")               ; Download via host computer
1260                                 CONSTANTS_TBL_START
1261      000426                              EQU     @LCV(L)
1262                                          ENDIF
1263   
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 25



1264                                          IF      @SCP("HOST","ROM")                ; Boot ROM code
1266                                          ENDIF
1267   
1268                                          IF      @SCP("HOST","ONCE")               ; Download via ONCE debugger
1270                                          ENDIF
1271   
1272                                ; Parameter table in P: space to be copied into X: space during
1273                                ;   initialization, and must be copied from ROM in the boot process
1274      X:000002 P:000426         ONE       DC      1                                 ; One
1275      X:000003 P:000427         THREE     DC      3                                 ; Three
1276      X:000004 P:000428         FOUR      DC      4                                 ; Four
1277   
1278                                ; Host flags are bits 5,4,3 of the HSTR
1279      X:000005 P:000429         FLAG_ZERO DC      0                                 ; Flag = 0 => command executing
1280      X:000006 P:00042A         FLAG_DONE DC      $000008                           ; Flag = 1 => DONE
1281      X:000007 P:00042B         FLAG_REPLY DC     $000010                           ; Flag = 2 => reply value available
1282      X:000008 P:00042C         FLAG_ERR  DC      $000018                           ; Flag = 3 => error
1283      X:000009 P:00042D         FLAG_SYR  DC      $000020                           ; Flag = 4 => controller reset
1284      X:00000A P:00042E         FLAG_RDI  DC      $000028                           ; Flag = 5 => reading out image
1285      X:00000B P:00042F         FLAG_BUSY DC      $000030                           ; Flag = 6 => controller is busy
1286      X:00000C P:000430         C512      DC      512                               ; 1/2 the FIFO size
1287      X:00000D P:000431         C00FF00   DC      $00FF00
1288      X:00000E P:000432         C000202   DC      $000202                           ; Timing board header
1289      X:00000F P:000433         TRM_MEM   DC      0                                 ; Test DRAM, memory type of failure
1290      X:000010 P:000434         TRM_ADR   DC      0                                 ; Test DRAM, address of failure
1291   
1292                                ; Tack the length of the variable table onto the length of code to be booted
1293                                 CONSTANTS_TBL_LENGTH
1294      00000F                              EQU     @CVS(P,*-ONE)                     ; Length of variable table
1295   
1296                                ; Ending address of program so its length can be calculated for bootstrapping
1297                                ; The constants defined after this are NOT initialized, so need not be
1298                                ;    downloaded.
1299   
1300      000435                    END_ADR   EQU     @LCV(L)                           ; End address of P: code written to ROM
1301   
1302                                ; Miscellaneous variables
1303      X:000011 P:000435         SV_A      DC      0                                 ; Place for saving accumulator A
1304      X:000012 P:000436         NPXLS_1   DC      0                                 ; # of pxls in current READ_IMAGE call, MS b
yte
1305      X:000013 P:000437         NPXLS_0   DC      0                                 ; # of pxls in current READ_IMAGE, LS 24-bit
s
1306      X:000014 P:000438         IPXLS_1   DC      0                                 ; Down pixel counter in READ_IMAGE, MS byte
1307      X:000015 P:000439         IPXLS_0   DC      0                                 ; Down pixel counter in READ_IMAGE, 24-bits
1308      X:000016 P:00043A         R_PXLS_1  DC      0                                 ; Up Counter of # of pixels read, MS 16-bits
1309      X:000017 P:00043B         R_PXLS_0  DC      0                                 ; Up Counter of # of pixels read, LS 16-bits
1310                                 BASE_ADDR_1
1311      X:000018 P:00043C                   DC      0                                 ; Starting PCI address of image, MS byte
1312                                 BASE_ADDR_0
1313      X:000019 P:00043D                   DC      0                                 ; Starting PCI address of image, LS 24-bits
1314      X:00001A P:00043E         PCI_ADDR_1 DC     0                                 ; Current PCI address of image, MS byte
1315      X:00001B P:00043F         PCI_ADDR_0 DC     0                                 ; Current PCI address of image, LS 24-bits
1316      X:00001C P:000440         REPLY     DC      0                                 ; Reply value
1317      X:00001D P:000441         HOST_FLAG DC      0                                 ; Value of host flags written to X:DCTR
1318      X:00001E P:000442         FO_DEST   DC      0                                 ; Whether host or PCI board receives command
1319      X:00001F P:000443         FO_CMD    DC      0                                 ; Fiber optic command or reply
1320   
1321                                ; Check that the parameter table is not too big
1322                                          IF      @CVS(N,*)>=ARG_TBL
1324                                          ENDIF
1325   
1326      X:000030 P:000444                   ORG     X:ARG_TBL,P:
Motorola DSP56300 Assembler  Version 6.3.4   08-09-30  10:55:09  pci2boot.asm  Page 26



1327   
1328                                ; Table that contains the header, command and its arguments
1329      X:000030 P:000444         HEADER    DC      0                                 ; (Source, Destination, Number of words)
1330      X:000031 P:000445         COMMAND   DC      0                                 ; Manual command
1331      X:000032 P:000446         ARG1      DC      0                                 ; First command argument
1332      X:000033 P:000447         ARG2      DC      0                                 ; Second command argument
1333                                 DESTINATION
1334      X:000034 P:000448                   DC      0                                 ; Derived from header
1335      X:000035 P:000449         NUM_ARG   DC      0                                 ; Derived from header
1336   
1337                                ; End of program
1338                                          END

0    Errors
0    Warnings


