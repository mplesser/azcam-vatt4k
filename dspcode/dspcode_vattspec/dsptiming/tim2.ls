Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2.asm  Page 1



1                        ; *******************************************************************
2                        ; tim2.asm for Gen 2
3      
4                        ; DSP source code for reading out a CCD
5                        ; This is AzCam code, a combination of ARC V1.7 code combined the ICE readout routines.
6                        ; last change 22Feb04 MPL
7      
8                                  PAGE    132                               ; Printronix page width - 132 columns
9      
10                       ; Define a section name so it doesn't conflict with other application programs
11                                 SECTION TIM
12     
13                       ; Include a header file that defines common application and boot code parameters
14                                 INCLUDE "tim2_hdr.asm"
15                       ; timhdr.asm for Gen2
16     
17                               COMMENT *
18     
19                       This is a header file that is shared between the fiber optic timing board
20                       boot and application code files
21     
22                       20Aug04 last change MPL
23                               *
24     
25                                 PAGE    132                               ; Printronix page width - 132 columns
26     
27                       ; Some basic structural definitions
28        000130         APL_ADR   EQU     $130                              ; P: memory location where application code begins
29        0000D0         APL_LEN   EQU     $200-APL_ADR                      ; Maximum length of application program
30        000280         MISC_LEN  EQU     $280                              ; Maximum length of "miscellanous" code
31        000040         COM_LEN   EQU     $40                               ; Length of memory for application commands
32        00003C         TIM_ISR   EQU     $3C                               ; DSP timer interrupt service routine address
33        00003E         PGM_CON   EQU     $3E                               ; Program continues on here
34        000080         COM_TBL   EQU     $80                               ; Starting address of command table in X: memory
35        000500         N_W_APL   EQU     $500                              ; Number of words in each application
36        000028         NUM_COM   EQU     40                                ; Number of entries in command table
37     
38        000000         RST_ISR   EQU     $00                               ; Hardware reset interrupt
39        000006         ROM_ID    EQU     $06                               ; Location of program Identification = SWI interrupt
40        000008         START     EQU     $08                               ; Starting address of program
41        000060         RCV_BUF   EQU     $60                               ; Starting address of receiver buffer in X:
42        00000F         TBL_ADR   EQU     $0F                               ; (IR) Waveform tables starting address
43     
44        004000         ROM_OFF   EQU     $4000                             ; Boot program offset address in EEPROM
45        004200         LD_X      EQU     $4200                             ; Assembler loads X: starting at this EEPROM address
46        00C600         RD_X      EQU     $C600                             ; DSP reads X: from this EEPROM address
47     
48                       ; Define DSP port addresses
49        00FF80         WRSS      EQU     $FF80                             ; Write clock driver and VP switch states
50        00FFC0         RDFO      EQU     $FFC0                             ; Read serial receiver fiber optic contents
51        00FFC0         WRFO      EQU     $FFC0                             ; Write to fiber optic serial transmitter
52        00FFA0         RDAD      EQU     $FFA0                             ; Read A/D datum into DSP
53        00FFA0         RDAD0     EQU     $FFA0                             ; Address for reading A/D #0
54        00FFA1         RDAD1     EQU     $FFA1                             ; Address for reading A/D #1
55        00FFC1         WRLATCH   EQU     $FFC1                             ; Write to timing board latch
56        006000         RSTWDT    EQU     $6000                             ; Address to reset the timing board watchdog timer
57        00FFFE         BCR       EQU     $FFFE                             ; Bus (=Port A) Control Register -> Wait States
58        00FFE0         PBC       EQU     $FFE0                             ; Port B Control Register
59        00FFE2         PBDDR     EQU     $FFE2                             ; Port B Data Direction Register
60        00FFE4         PBD       EQU     $FFE4                             ; Port B Data Register
61        00FFE1         PCC       EQU     $FFE1                             ; Port C Control Register
62        00FFE3         PCDDR     EQU     $FFE3                             ; PortC Data Direction Register
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_hdr.asm  Page 2



63        00FFE5         PCD       EQU     $FFE5                             ; Port C Data Register
64        00FFFF         IPR       EQU     $FFFF                             ; Interrupt Priority Register
65        00FFEF         SSITX     EQU     $FFEF                             ; SSI Transmit and Receive data register
66        00FFEF         SSIRX     EQU     $FFEF                             ; SSI Transmit and Receive data register
67        00FFEE         SSISR     EQU     $FFEE                             ; SSI Status Register
68        00FFEC         CRA       EQU     $FFEC                             ; SSI Control Register A
69        00FFED         CRB       EQU     $FFED                             ; SSI Control Regsiter B
70        00FFDE         TCSR      EQU     $FFDE                             ; Timer control and status register
71        00FFDF         TCR       EQU     $FFDF                             ; Timer count register
72     
73                       ; Hardware bit definitions all over the place
74        000006         SSI_TDE   EQU     6                                 ; SSI Transmitter data register empty
75        000007         SSI_RDF   EQU     7                                 ; SSI Receiver data register full
76        000002         LVEN      EQU     2                                 ; Low voltage enable (+/-15 volt nominal)
77        000003         HVEN      EQU     3                                 ; Enable high voltage (+32V nominal)
78        000005         TIM_U_RST EQU     5                                 ; Timing to utility board reset bit number in U25
79        00000D         PWRST     EQU     13                                ; Power control board reset
80        000007         RST_FIFO  EQU     7                                 ; Reset FIFO bit number in control latch U25
81        000009         EF        EQU     9                                 ; FIFO empty flag, low true
82        000000         TIM_BIT   EQU     0                                 ; Timer status bit
83        000001         WW        EQU     1                                 ; Word width = 1 for 16-bit image data, 0 for 24-bit
84        000000         CDAC      EQU     0                                 ; Bit number in U25 for clearing DACs
85        000002         ENCK      EQU     2                                 ; Bit number in U25 for enabling analog switches
86        000001         DUALCLK   EQU     1                                 ; Set to clock two halves of clock driver board togethe
r
87     
88                       ; Software status bits, defined at X:<STATUS = X:0
89        000000         ST_RCV    EQU     0                                 ; Set if FO, cleared if SSI
90        000002         IDLMODE   EQU     2                                 ; Set if need to idle after readout
91        000003         ST_SHUT   EQU     3                                 ; Set to indicate shutter is closed, clear for open
92        000004         ST_RDC    EQU     4                                 ; Set if executing 'RDC' command - reading out
93        000005         SPLIT_S   EQU     5                                 ; Set if split serial
94        000006         SPLIT_P   EQU     6                                 ; Set if split parallel
95        000007         MPP       EQU     7                                 ; Set if parallels are in MPP mode
96        00000A         TST_IMG   EQU     10                                ; Set if controller is to generate a test image
97        00000B         SHUT      EQU     11                                ; Set if opening shutter at beginning of exposure
98        00000D         NOREAD    EQU     13                                ; Set if not to readout after exposure
99     
100                      ; Specify controller configuration bits of the X:STATUS word
101                      ;  to describe the software capabilities of this application file
102                      ; The bit is set (=1) if the capability is supported by the controller
103    
104                              COMMENT *
105    
106                      BIT #'s         FUNCTION
107                      2,1,0           Video Processor
108                                              000     CCD Rev. 3
109                                              001     CCD Gen I
110                                              010     IR Rev. 4
111                                              011     IR Coadder
112    
113                      4,3             Timing Board
114                                              00      Rev. 4, Gen II
115                                              01      Gen I
116    
117                      6,5             Utility Board
118                                              00      No utility board
119                                              01      Utility Rev. 3
120    
121                      7               Shutter
122                                              0       No shutter support
123                                              1       Yes shutter support
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_hdr.asm  Page 3



124    
125                      9,8             Temperature readout
126                                              00      No temperature readout
127                                              01      Polynomial Diode calibration
128                                              10      Linear temperature sensor calibration
129    
130                      10              Subarray readout
131                                              0       Not supported
132                                              1       Yes supported
133    
134                      11              Binning
135                                              0       Not supported
136                                              1       Yes supported
137    
138                      12              Split-Serial readout
139                                              0       Not supported
140                                              1       Yes supported
141    
142                      13              Split-Parallel readout
143                                              0       Not supported
144                                              1       Yes supported
145    
146                      14              MPP = Inverted parallel clocks
147                                              0       Not supported
148                                              1       Yes supported
149    
150                      16,15           Clock Driver Board
151                                              00      Rev. 3
152                                              11      No clock driver board (Gen I)
153    
154                      19,18,17                Special implementations
155                                              000     Somewhere else
156                                              001     Mount Laguna Observatory
157                                              010     NGST Aladdin
158                                              xxx     Other
159                              *
160    
161                      CCDVIDREV3B
162       000000                   EQU     $000000                           ; CCD Video Processor Rev. 3
163       000001         VIDGENI   EQU     $000001                           ; CCD Video Processor Gen I
164       000002         IRREV4    EQU     $000002                           ; IR Video Processor Rev. 4
165       000003         COADDER   EQU     $000003                           ; IR Coadder
166       000000         TIMREV4   EQU     $000000                           ; Timing Rev. 4
167       000008         TIMGENI   EQU     $000008                           ; Timing Gen I
168       000020         UTILREV3  EQU     $000020                           ; Utility Rev. 3 supported
169       000080         SHUTTER_CC EQU    $000080                           ; Shutter supported
170       000100         TEMP_POLY EQU     $000100                           ; Polynomial calibration
171                      TEMP_LINEAR
172       000200                   EQU     $000200                           ; Linear calibration
173       000400         SUBARRAY  EQU     $000400                           ; Subarray readout supported
174       000800         BINNING   EQU     $000800                           ; Binning supported
175                      SPLIT_SERIAL
176       001000                   EQU     $001000                           ; Split serial supported
177                      SPLIT_PARALLEL
178       002000                   EQU     $002000                           ; Split parallel supported
179       004000         MPP_CC    EQU     $004000                           ; Inverted clocks supported
180       018000         CLKDRVGENI EQU    $018000                           ; No clock driver board - Gen I
181       020000         MLO       EQU     $020000                           ; Set if Mount Laguna Observatory
182       040000         NGST      EQU     $040000                           ; NGST Aladdin implementation
183    
184                      ; Define the application number and controller configuration bits
185       000000         APL_NUM   EQU     0                                 ; Application number from 0 to 3
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2.asm  Page 4



186       000020         CC        EQU     CCDVIDREV3B+TIMREV4+UTILREV3
187    
188                      ; *******************************************************************
189                      ; Put code in external SRAM, starting at P:$200.
190                                IF      @SCP("HOST","HOST")
191       P:0200 P:0200                   ORG     P:$200,P:$200                     ; Download address
192                                       ELSE
194                                       ENDIF
195    
196                             ; *******************************************************************
197                             ; Fast clear of CCD, executed as a command
198       P:0200 P:0200 0D0202  CLEAR     JSR     <CLR_CCD
199       P:0201 P:0201 0C0000            JMP     <FINISH
200    
201                             CLR_CCD                                             ; this block is ICE version
202       P:0202 P:0202 68A100            MOVE                          Y:<ACLEAR0,R0
203       P:0203 P:0203 0D01D7            JSR     <CLOCK
204       P:0204 P:0204 68A500            MOVE                          Y:<AFPXFER0,R0
205       P:0205 P:0205 0D01D7            JSR     <CLOCK
206       P:0206 P:0206 300800            MOVE              #<NPCLEAR,R0            ; flush all rows
207       P:0207 P:0207 0D0189            JSR     <PQSKIP
208       P:0208 P:0208 68A600            MOVE                          Y:<AFPXFER2,R0
209       P:0209 P:0209 0D01D7            JSR     <CLOCK
210       P:020A P:020A 300700            MOVE              #<NSCLEAR,R0            ; flush serial register
211       P:020B P:020B 0D019F            JSR     <FSSKIP
212       P:020C P:020C 68A200            MOVE                          Y:<ACLEAR2,R0
213       P:020D P:020D 0D01D7            JSR     <CLOCK
214    
215       P:020E P:020E 44F400            MOVE              #TST_RCV,X0             ; Wait for commands during exposure
                        000000
216       P:0210 P:0210 440000            MOVE              X0,X:<IDL_ADR           ; instead of idling
217       P:0211 P:0211 00000C            RTS
218    
219                             ; *******************************************************************
220                             ; Keep the CCD idling when not reading out
221                             IDLE
222       P:0212 P:0212 68A500            MOVE                          Y:<AFPXFER0,R0 ; setup for fast par flush
223       P:0213 P:0213 0D01D7            JSR     <CLOCK
224       P:0214 P:0214 301F00            MOVE              #<IDLEONE,R0            ; shift one line
225       P:0215 P:0215 0D0189            JSR     <PQSKIP
226       P:0216 P:0216 0E8000            JCS     <CHK_SSI                          ; Go process header and command
227       P:0217 P:0217 68A600            MOVE                          Y:<AFPXFER2,R0 ; end fast par flush
228       P:0218 P:0218 0D01D7            JSR     <CLOCK
229       P:0219 P:0219 300700            MOVE              #<NSCLEAR,R0            ; flush serial register
230       P:021A P:021A 0D019F            JSR     <FSSKIP
231    
232       P:021B P:021B 0C0212            JMP     <IDLE                             ; repeat this loop
233    
234                             ; Include generic routines
235                                       INCLUDE "tim2_common.asm"
236                             ; timcommon.asm for Gen 2
237    
238                             ; This file is for utilities that are in common to all the timing board
239                             ; programs, located in external SRAM.
240                             ; Include this file so that it continues to be written in the P:$200
241                             ; address space.
242    
243                             ; 28Feb08 last change MPL
244    
245                                     COMMENT *
246    
247                             The following commands are supported in this file...
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_common.asm  Page 5



248    
249                             PAL_DLY                 Subroutine to delay by about 8 microseconds
250                             SET_DAC                 Transfer DAC values in (R0) table to the DACs
251                             FASTSKP                 Compute number of waveform table entries in a readout
252                                                              for fast clocking
253                             SYNTHETIC_IMAGE         Generate a synthetic image for system testing
254                             OSHUT                           Subroutine call for opening the shutter
255                             CSHUT                           Subroutine call for closing the shutter
256                             OPEN_SHUTTER            Command for opening the shutter
257                             CLOSE_SHUTTER           Command for closing the shutter
258                             SET_EXP_TIME            Write desired exposure time to timing board variable
259                             RD_EXP_TIME                     Read elapsed exposure time
260                             START_EXPOSURE          Start an exposure - 'DON' reply, open
261                                                              shutter, expose, close shutter, delay Y:SH_DLY
262                             START_EXPOSURE1         Start an exposure - open shutter, expose,
263                                                             close shutter, delay Y:SH_DLY, then 'DON' reply
264                             PAUSE_EXPOSURE          Close shutter, stop exposure timer
265                             RESUME_EXPOSURE         Open shutter if necessary, resume exposure timer
266                             ABORT_EXPOSURE          Close shutter, stop exposure timer
267                             IDL                             Put FPA to clocking when not processing commands or
268                                                              reading out
269                             STP                             Put FPA to not clocking when not processing commands or
270                                                              reading out
271                             READ_CONTROLLER_CONFIGURATION
272                             PWR_OFF                 Turn off ananlog power supply voltages to backplane
273                             PWR_ON                  Turn on analog power supply voltages to backplane
274                             SETBIAS                 Command to call SET_BIASES and reply 'DON'
275                             SET_BIASES                      Subroutine to turn on all bias and clock voltages
276                                                              by reading them from the waveform tables and writing
277                                                              them to the DACs
278                             SER_ANA                 Direct the timing board DSP's synchronous serial
279                                                              transmitter to the analog boards (clock driver, video)
280                             SER_UTL                 Direct the timing board DSP's synchronous serial
281                                                              transmitter to the utility board
282                             CLR_SWS                 Clear the analog switches in the clock driver and
283                                                              video boards to lower their power consumption, as a
284                                                              command with a 'DON' reply
285                             CLEAR_SWITCHES          Subroutine call for CLR_WSW
286                             ST_GAIN                 Set the video processor gain to one of four values
287                             WR_CNTRL
288                             SET_DC
289                             SET_BIAS_NUMBER
290                             SET_MUX
291                             PCI_READ_IMAGE
292                             XMT_FO
293    
294                                     *
295    
296                             ; Hardware control bit definitions
297       000004                SHUTTER   EQU     4                                 ; Shutter control bit = TIM-LATCH0, A30
298    
299                             ; *******************************************************************
300                             ; Delay for serial writes to the PALs and DACs by 8 microsec
301       P:021C P:021C 06FA80  PAL_DLY   DO      #250,DLY                          ; Wait 8 usec for serial data transmission
                        00021E
302       P:021E P:021E 000000            NOP
303       P:021F P:021F 000000  DLY       NOP
304       P:0220 P:0220 00000C            RTS
305    
306                             ; *******************************************************************
307                             ;  Update the DACs
308       P:0221 P:0221 4CD800  SET_DAC   MOVE                          Y:(R0)+,X0  ; Get the number of table entries
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_common.asm  Page 6



309       P:0222 P:0222 06C400            DO      X0,SET_L0                         ; Repeat X0 times
                        000226
310       P:0224 P:0224 08D8EF            MOVEP             Y:(R0)+,X:SSITX         ; Send out the waveform
311       P:0225 P:0225 0D021C            JSR     <PAL_DLY                          ; Wait for SSI and PAL to be empty
312       P:0226 P:0226 000000            NOP                                       ; Do loop restriction
313                             SET_L0
314       P:0227 P:0227 00000C            RTS                                       ; Return from subroutine
315    
316                             ; *******************************************************************
317                             ; Subroutine for computing number of fast clocks needed
318       P:0228 P:0228 2000A8  FASTSKP   MPY     X0,X1,B                           ; X1 = number of pixels to skip,
319                                                                                 ; X0 = number of waveform table entries
320       P:0229 P:0229 20002A            ASR     B                                 ; Correct for multiplication left shift
321       P:022A P:022A 212E00            MOVE              B0,A                    ; Get only least significant 24 bits
322       P:022B P:022B 458000            MOVE              X:<ONE,X1
323       P:022C P:022C 200064            SUB     X1,A                              ; Subtract 1
324       P:022D P:022D 21C500            MOVE              A,X1                    ; X1 = X0 * X1 - 1
325       P:022E P:022E 00000C            RTS
326    
327                             ; *******************************************************************
328                             ; Generate a synthetic image by simply incrementing the pixel counts
329                             SYNTHETIC_IMAGE
330       P:022F P:022F 200013            CLR     A
331       P:0230 P:0230 5E1800            MOVE                          A,Y:<TST_DAT
332                             ;       DO      Y:<NPR,LPR_TST          ; Loop over each line readout
333                             ;       DO      Y:<NSR,LSR_TST          ; Loop over number of pixels per line
334       P:0231 P:0231 060240            DO      Y:<NPDATA,LPR_TST                 ; Loop over each line readout
                        00023C
335       P:0233 P:0233 060140            DO      Y:<NSDATA,LSR_TST                 ; Loop over number of pixels per line
                        00023B
336       P:0235 P:0235 0614A0            REP     #20                               ; #20 => 1.0 microsec per pixel
337       P:0236 P:0236 000000            NOP
338    
339                             ; Increment pixel counts by one
340       P:0237 P:0237 458000            MOVE              X:<ONE,X1
341       P:0238 P:0238 5E9800            MOVE                          Y:<TST_DAT,A
342       P:0239 P:0239 200060            ADD     X1,A                              ; Pixel data = Y:TST_DAT = Y:TST_DAT + 1
343       P:023A P:023A 5E1800            MOVE                          A,Y:<TST_DAT
344       P:023B P:023B 09CE00            MOVEP             A,Y:WRFO                ; Transmit to fiber optic
345                             LSR_TST
346       P:023C P:023C 000000            NOP
347                             LPR_TST
348       P:023D P:023D 0C0150            JMP     <RDC_END                          ; Normal exit
349    
350                             ; *******************************************************************
351                             ; Open the shutter by setting the backplane bit TIM-LATCH0
352       P:023E P:023E 0A0023  OSHUT     BSET    #ST_SHUT,X:<STATUS                ; Set status bit to mean shutter open
353                             ;       BCLR    #SHUTTER,X:<LATCH       ; Clear hardware shutter bit to open
354       P:023F P:023F 0A0024            BSET    #SHUTTER,X:<LATCH                 ; MPL Clear hardware shutter bit to open
355       P:0240 P:0240 09F081            MOVEP             X:LATCH,Y:WRLATCH       ; Write it to the hardware
                        000000
356       P:0242 P:0242 00000C            RTS
357    
358                             ; *******************************************************************
359                             ; Close the shutter by clearing the backplane bit TIM-LATCH0
360       P:0243 P:0243 0A0003  CSHUT     BCLR    #ST_SHUT,X:<STATUS                ; Clear status to mean shutter closed
361                             ;       BSET    #SHUTTER,X:<LATCH       ; Set hardware shutter bit to close
362       P:0244 P:0244 0A0004            BCLR    #SHUTTER,X:<LATCH                 ; MPL Set hardware shutter bit to close
363       P:0245 P:0245 09F081            MOVEP             X:LATCH,Y:WRLATCH       ; Write it to the hardware
                        000000
364       P:0247 P:0247 00000C            RTS
365    
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_common.asm  Page 7



366                             ; *******************************************************************
367                             ; Open the shutter from the timing board, executed as a command
368                             OPEN_SHUTTER
369       P:0248 P:0248 0D023E            JSR     <OSHUT
370       P:0249 P:0249 0C0000            JMP     <FINISH
371    
372                             ; *******************************************************************
373                             ; Close the shutter from the timing board, executed as a command
374                             CLOSE_SHUTTER
375       P:024A P:024A 0D0243            JSR     <CSHUT
376       P:024B P:024B 0C0000            JMP     <FINISH
377    
378                             ; *******************************************************************
379                             ; Set the desired exposure time
380                             SET_EXP_TIME
381       P:024C P:024C 44DC00            MOVE              X:(R4)+,X0
382       P:024D P:024D 440000            MOVE              X0,X:<EXP_TIM           ; Write to magic address
383       P:024E P:024E 440000            MOVE              X0,X:<TGT_TIM
384       P:024F P:024F 0C0000            JMP     <FINISH
385    
386                             ; *******************************************************************
387                             ; Read the time remaining until the exposure ends
388                             RD_EXP_TIME
389       P:0250 P:0250 448000            MOVE              X:<EL_TIM,X0            ; Read elapsed exposure time
390       P:0251 P:0251 0C0000            JMP     <FINISH1
391    
392                             ; *******************************************************************
393                             ; Start the exposure, return DON, then operate and time the shutter
394                             START_EXPOSURE
395       P:0252 P:0252 44F400            MOVE              #$020102,X0
                        020102
396       P:0254 P:0254 0D03B1            JSR     <XMT_FO
397       P:0255 P:0255 44F400            MOVE              #'IIA',X0               ; this replies to host with DON in
                        494941
398       P:0257 P:0257 0D03B1            JSR     <XMT_FO                           ; response to SEX
399    
400       P:0258 P:0258 0A008B            JCLR    #SHUT,X:STATUS,L_SEX0
                        00025B
401       P:025A P:025A 0D023E            JSR     <OSHUT                            ; Open the shutter
402       P:025B P:025B 67F400  L_SEX0    MOVE              #L_SEX1,R7              ; Set return address
                        00025E
403       P:025D P:025D 0C0000            JMP     <EXPOSE                           ; Delay for specified exposure time
404    
405                             L_SEX1
406       P:025E P:025E 0A008B            JCLR    #SHUT,X:STATUS,S_DEL0             ; No need to close shutter
                        00026C
407       P:0260 P:0260 0D0243            JSR     <CSHUT                            ; Close the shutter
408    
409       P:0261 P:0261 5E9900            MOVE                          Y:<SH_DEL,A ; Delay loop after shutter close
410       P:0262 P:0262 200003            TST     A
411       P:0263 P:0263 0EF26C            JLE     <S_DEL0
412       P:0264 P:0264 44F400            MOVE              #25000,X0
                        0061A8
413       P:0266 P:0266 06CE00            DO      A,S_DEL0                          ; Delay by Y:SH_DEL milliseconds
                        00026B
414       P:0268 P:0268 06C400            DO      X0,S_DEL1
                        00026A
415       P:026A P:026A 000000            NOP
416       P:026B P:026B 000000  S_DEL1    NOP
417       P:026C P:026C 000000  S_DEL0    NOP
418    
419       P:026D P:026D 0C0000            JMP     <PRC_RCV                          ; finish
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_common.asm  Page 8



420    
421                             ; *******************************************************************
422                             ; Pause the exposure - close the shutter, and stop the timer
423                             PAUSE_EXPOSURE
424       P:026E P:026E 0A9E00            BCLR    #TIM_BIT,X:TCSR                   ; Disable the DSP exposure timer
425       P:026F P:026F 0D0243            JSR     <CSHUT                            ; Close the shutter
426       P:0270 P:0270 0C0000            JMP     <FINISH
427    
428                             ; *******************************************************************
429                             ; Resume the exposure - open the shutter if needed and restart the timer
430                             RESUME_EXPOSURE
431       P:0271 P:0271 0A9E20            BSET    #TIM_BIT,X:TCSR                   ; Re-enable the DSP exposure timer
432       P:0272 P:0272 0A008B            JCLR    #SHUT,X:STATUS,L_RES
                        000275
433       P:0274 P:0274 0D023E            JSR     <OSHUT                            ; Open the shutter ir necessary
434       P:0275 P:0275 0C0000  L_RES     JMP     <FINISH
435    
436                             ; *******************************************************************
437                             ; Abort exposure - close the shutter, stop the timer and resume idle mode
438                             ABORT_EXPOSURE
439       P:0276 P:0276 0A9E00            BCLR    #TIM_BIT,X:TCSR                   ; Disable the DSP exposure timer
440       P:0277 P:0277 0D0243            JSR     <CSHUT                            ; Close the shutter
441       P:0278 P:0278 0A0082            JCLR    #IDLMODE,X:<STATUS,FINISH         ; Check whether to idle after readout
                        000000
442       P:027A P:027A 44F400            MOVE              #IDLE,X0                ; Idle after readout
                        000212
443       P:027C P:027C 440000            MOVE              X0,X:<IDL_ADR
444       P:027D P:027D 0C0000            JMP     <FINISH
445    
446                             ; *******************************************************************
447                             ; Set software to IDLE mode
448       P:027E P:027E 44F400  IDL       MOVE              #IDLE,X0                ; Exercise clocks when idling
                        000212
449       P:0280 P:0280 440000            MOVE              X0,X:<IDL_ADR
450       P:0281 P:0281 0A0022            BSET    #IDLMODE,X:<STATUS                ; Idle after readout
451       P:0282 P:0282 0C0000            JMP     <FINISH                           ; Need to send header and 'DON'
452    
453                             ; *******************************************************************
454                             ; Come to here on a 'STP' command so 'DON' can be sent
455       P:0283 P:0283 44F400  STP       MOVE              #TST_RCV,X0             ; Wait for commands during exposure
                        000000
456       P:0285 P:0285 440000            MOVE              X0,X:<IDL_ADR           ;  instead of exercising clocks
457       P:0286 P:0286 0A0002            BCLR    #IDLMODE,X:<STATUS                ; Don't idle after readout
458       P:0287 P:0287 0C0000            JMP     <FINISH
459    
460                             ; *******************************************************************
461                             ; Let the host computer read the controller configuration
462                             READ_CONTROLLER_CONFIGURATION
463       P:0288 P:0288 4C9A00            MOVE                          Y:<CONFIG,X0 ; Just transmit the configuration
464       P:0289 P:0289 0C0000            JMP     <FINISH1
465    
466                             ; *******************************************************************
467                             ; Power off
468       P:028A P:028A 0D02D8  PWR_OFF   JSR     <CLEAR_SWITCHES                   ; Clear all analog switches
469       P:028B P:028B 0AA202            BCLR    #LVEN,X:PBDDR                     ; Set these signals to DSP inputs
470       P:028C P:028C 0AA20D            BCLR    #PWRST,X:PBDDR
471       P:028D P:028D 0AA203            BCLR    #HVEN,X:PBDDR
472       P:028E P:028E 0AA422            BSET    #LVEN,X:PBD                       ; LVEN = HVEN = 1 => Power reset
473       P:028F P:028F 0AA42D            BSET    #PWRST,X:PBD
474       P:0290 P:0290 0AA423            BSET    #HVEN,X:PBD
475       P:0291 P:0291 0C0000            JMP     <FINISH
476    
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_common.asm  Page 9



477                             ; *******************************************************************
478                             ; Start power-on cycle
479       P:0292 P:0292 0AA222  PWR_ON    BSET    #LVEN,X:PBDDR                     ; Set these signals to DSP outputs
480       P:0293 P:0293 0AA22D            BSET    #PWRST,X:PBDDR
481       P:0294 P:0294 0AA223            BSET    #HVEN,X:PBDDR
482       P:0295 P:0295 0D02D8            JSR     <CLEAR_SWITCHES                   ; Clear all analog switches
483    
484                             ; Ramp up the low voltages (+/- 6.5V, 16.5V) and then delay
485       P:0296 P:0296 0AA402            BCLR    #LVEN,X:PBD                       ; LVEN = Low => Turn on +/- 6.5V,
486       P:0297 P:0297 0AA40D            BCLR    #PWRST,X:PBD
487       P:0298 P:0298 44F400            MOVE              #60000,X0
                        00EA60
488       P:029A P:029A 06C400            DO      X0,WT_PON1                        ; Wait 10 millisec or so for settling
                        00029F
489       P:029C P:029C 07708E            MOVE              A,P:RSTWDT              ; Reset watchdog timer
                        006000
490       P:029E P:029E 07708E            MOVE              A,P:RSTWDT
                        006000
491                             WT_PON1
492    
493                             ; Ramp up the high +36 volt power line and then delay
494       P:02A0 P:02A0 0AA403            BCLR    #HVEN,X:PBD                       ; HVEN = Low => Turn on +36V
495       P:02A1 P:02A1 44F400            MOVE              #60000,X0
                        00EA60
496       P:02A3 P:02A3 06C400            DO      X0,WT_PON2                        ; Wait 10 millisec or so for settling
                        0002A8
497       P:02A5 P:02A5 07708E            MOVE              A,P:RSTWDT              ; Reset watchdog timer
                        006000
498       P:02A7 P:02A7 07708E            MOVE              A,P:RSTWDT
                        006000
499                             WT_PON2
500       P:02A9 P:02A9 0D02B0            JSR     <SET_BIASES                       ; Turn on the DC bias supplies
501       P:02AA P:02AA 44F400            MOVE              #IDLE,X0
                        000212
502       P:02AC P:02AC 440000            MOVE              X0,X:<IDL_ADR
503       P:02AD P:02AD 0C0000            JMP     <FINISH                           ; All done with 'DON'
504    
505                             ; *******************************************************************
506       P:02AE P:02AE 0D02B0  SETBIAS   JSR     <SET_BIASES
507       P:02AF P:02AF 0C0000            JMP     <FINISH
508    
509                             ; *******************************************************************
510                             ; Set all the DC bias voltages and video processor offset values, reading
511                             ;   them from the table labeled DACS in this file
512                             SET_BIASES
513       P:02B0 P:02B0 0D02C8            JSR     <SER_ANA
514       P:02B1 P:02B1 0A0020            BSET    #CDAC,X:<LATCH                    ; Disable clearing of DACs
515       P:02B2 P:02B2 0A0022            BSET    #ENCK,X:<LATCH                    ; Enable clock and DAC output switches
516       P:02B3 P:02B3 09F081            MOVEP             X:LATCH,Y:WRLATCH       ; Disable clear of DAC and enable clocks
                        000000
517       P:02B5 P:02B5 0D021C            JSR     <PAL_DLY                          ; Delay for all this to happen
518       P:02B6 P:02B6 0D021C            JSR     <PAL_DLY                          ; Delay for all this to happen
519    
520                             ; Disable simultaneous update of clock driver boards
521       P:02B7 P:02B7 0A0001            BCLR    #1,X:<LATCH
522       P:02B8 P:02B8 09F081            MOVEP             X:LATCH,Y:WRLATCH
                        000000
523    
524                             ; Read DAC values from a table, and set DACs
525       P:02BA P:02BA 68B000            MOVE                          Y:<ADACS,R0 ; MPL Get starting address of DAC values
526       P:02BB P:02BB 0D0221            JSR     <SET_DAC
527    
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_common.asm  Page 10



528                             ; Set all video processor analog switches to open to disable them (1 => OFF)
529       P:02BC P:02BC 56F400            MOVE              #$000FFF,A
                        000FFF
530       P:02BE P:02BE 566600            MOVE              A,X:(R6)                ; Send out the waveform
531       P:02BF P:02BF 000000            NOP
532    
533                             ; Let the DAC voltages all ramp up before exiting
534       P:02C0 P:02C0 56F400            MOVE              #400,A                  ; Delay 4 millisec
                        000190
535       P:02C2 P:02C2 06CE00            DO      A,L_SBI1
                        0002C5
536       P:02C4 P:02C4 0D021C            JSR     <PAL_DLY                          ; Delay for all this to happen
537       P:02C5 P:02C5 000000            NOP
538                             L_SBI1
539       P:02C6 P:02C6 0D02CF            JSR     <SER_UTL                          ; SSI -> utility board communication
540       P:02C7 P:02C7 00000C            RTS
541    
542                             ; *******************************************************************
543                             ; Enable serial communication to the analog boards
544       P:02C8 P:02C8 0AA420  SER_ANA   BSET    #0,X:PBD                          ; Set H0 for analog boards SSI
545       P:02C9 P:02C9 08F4A1            MOVEP             #$0000,X:PCC            ; Software reset of SSI
                        000000
546       P:02CB P:02CB 0AAD0A            BCLR    #10,X:CRB                         ; SSI -> continuous clock for analog
547       P:02CC P:02CC 08F4A1            MOVEP             #$0160,X:PCC            ; Re-enable the SSI
                        000160
548       P:02CE P:02CE 00000C            RTS
549    
550                             ; *******************************************************************
551                             ; Enable serial communication to the utility board
552       P:02CF P:02CF 08F4A1  SER_UTL   MOVEP             #$0000,X:PCC            ; Software reset of SSI
                        000000
553       P:02D1 P:02D1 0AAD2A            BSET    #10,X:CRB                         ; SSI -> gated clock for util board
554       P:02D2 P:02D2 08F4A1            MOVEP             #$0160,X:PCC            ; Enable the SSI
                        000160
555       P:02D4 P:02D4 0AA400            BCLR    #0,X:PBD                          ; Clear H0 for utility board SSI
556       P:02D5 P:02D5 00000C            RTS
557    
558                             ; *******************************************************************
559       P:02D6 P:02D6 0D02D8  CLR_SWS   JSR     <CLEAR_SWITCHES
560       P:02D7 P:02D7 0C0000            JMP     <FINISH
561    
562                             ; *******************************************************************
563                             ; Clear all video processor analog switches to lower their power dissipation
564                             CLEAR_SWITCHES
565       P:02D8 P:02D8 0D02C8            JSR     <SER_ANA                          ; Set SSI to analog board communication
566       P:02D9 P:02D9 56F400            MOVE              #$0C3000,A              ; Value of integrate speed and gain switches
                        0C3000
567       P:02DB P:02DB 20001B            CLR     B
568       P:02DC P:02DC 241000            MOVE              #$100000,X0             ; Increment over board numbers for DAC writes
569       P:02DD P:02DD 45F400            MOVE              #$001000,X1             ; Increment over board numbers for WRSS writes
                        001000
570       P:02DF P:02DF 060F80            DO      #15,L_VIDEO                       ; Fifteen video processor boards maximum
                        0002E6
571       P:02E1 P:02E1 08CE2F            MOVEP             A,X:SSITX               ; Gain, integrate speed
572       P:02E2 P:02E2 200040            ADD     X0,A
573       P:02E3 P:02E3 577000            MOVE              B,X:WRSS
                        00FF80
574       P:02E5 P:02E5 0D021C            JSR     <PAL_DLY                          ; Delay for the serial data transmission
575       P:02E6 P:02E6 200068            ADD     X1,B
576                             L_VIDEO
577       P:02E7 P:02E7 0A0000            BCLR    #CDAC,X:<LATCH                    ; Enable clearing of DACs
578       P:02E8 P:02E8 0A0002            BCLR    #ENCK,X:<LATCH                    ; Disable clock and DAC output switches
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_common.asm  Page 11



579       P:02E9 P:02E9 09F081            MOVEP             X:LATCH,Y:WRLATCH       ; Execute these two operations
                        000000
580       P:02EB P:02EB 44F400            MOVE              #IDLE,X0
                        000212
581       P:02ED P:02ED 440000            MOVE              X0,X:<IDL_ADR
582       P:02EE P:02EE 0D02CF            JSR     <SER_UTL                          ; Return SSI to utility board
583       P:02EF P:02EF 00000C            RTS
584    
585                             ; *******************************************************************
586                             ; Set the video processor gain and integrator speed for all video boards
587                             ;  Command syntax is  SGN  #GAIN  #SPEED, #GAIN = 1, 2, 5 or 10
588                             ;                                         #SPEED = 0 for slow, 1 for fast
589       P:02F0 P:02F0 0D02C8  ST_GAIN   JSR     <SER_ANA                          ; Set SSI to analog board communication
590       P:02F1 P:02F1 56DC00            MOVE              X:(R4)+,A               ; Gain value (1,2,5 or 10)
591       P:02F2 P:02F2 44F400            MOVE              #>1,X0
                        000001
592       P:02F4 P:02F4 200045            CMP     X0,A                              ; Check for gain = x1
593       P:02F5 P:02F5 0E22F9            JNE     <STG2
594       P:02F6 P:02F6 57F400            MOVE              #>$77,B
                        000077
595       P:02F8 P:02F8 0C030D            JMP     <STG_A
596       P:02F9 P:02F9 44F400  STG2      MOVE              #>2,X0                  ; Check for gain = x2
                        000002
597       P:02FB P:02FB 200045            CMP     X0,A
598       P:02FC P:02FC 0E2300            JNE     <STG5
599       P:02FD P:02FD 57F400            MOVE              #>$BB,B
                        0000BB
600       P:02FF P:02FF 0C030D            JMP     <STG_A
601       P:0300 P:0300 44F400  STG5      MOVE              #>5,X0                  ; Check for gain = x5
                        000005
602       P:0302 P:0302 200045            CMP     X0,A
603       P:0303 P:0303 0E2307            JNE     <STG10
604       P:0304 P:0304 57F400            MOVE              #>$DD,B
                        0000DD
605       P:0306 P:0306 0C030D            JMP     <STG_A
606       P:0307 P:0307 44F400  STG10     MOVE              #>10,X0                 ; Check for gain = x10
                        00000A
607       P:0309 P:0309 200045            CMP     X0,A
608       P:030A P:030A 0E2000            JNE     <ERROR
609       P:030B P:030B 57F400            MOVE              #>$EE,B
                        0000EE
610    
611       P:030D P:030D 56DC00  STG_A     MOVE              X:(R4)+,A               ; Integrator Speed (0 for slow, 1 for fast)
612       P:030E P:030E 0ACC00            JCLR    #0,A1,STG_B
                        000312
613       P:0310 P:0310 0ACD68            BSET    #8,B1
614       P:0311 P:0311 0ACD69            BSET    #9,B1
615       P:0312 P:0312 44F400  STG_B     MOVE              #$0C3C00,X0
                        0C3C00
616       P:0314 P:0314 20004A            OR      X0,B
617       P:0315 P:0315 5F1700            MOVE                          B,Y:<GAIN   ; Store the GAIN value for later us
618    
619                             ; Send this same value to 15 video processor boards whether they exist or not
620       P:0316 P:0316 241000            MOVE              #$100000,X0             ; Increment value
621       P:0317 P:0317 060F80            DO      #15,STG_LOOP
                        00031C
622       P:0319 P:0319 577000            MOVE              B,X:SSITX               ; Transmit the SSI word
                        00FFEF
623       P:031B P:031B 0D021C            JSR     <PAL_DLY                          ; Wait for SSI and PAL to be empty
624       P:031C P:031C 200048            ADD     X0,B                              ; Increment the video processor board number
625                             STG_LOOP
626    
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_common.asm  Page 12



627       P:031D P:031D 0D02CF            JSR     <SER_UTL                          ; Return SSI to utility board communication
628       P:031E P:031E 0C0000            JMP     <FINISH
629       P:031F P:031F 56DC00  ERR_SGN   MOVE              X:(R4)+,A
630       P:0320 P:0320 0D02CF            JSR     <SER_UTL                          ; Return SSI to utility board communication
631       P:0321 P:0321 0C0000            JMP     <ERROR
632    
633                             ; *******************************************************************
634                             ; Write an arbitraty control word over the SSI link to any register, any board
635                             ; Command syntax is  WRC number, number is 24-bit number to be sent to any board
636                             ;WR_CNTRL
637                             ;       JSR     <SER_ANA        ; Set SSI to analog board communication
638                             ;       JSR     <PAL_DLY        ; Wait for the number to be sent
639                             ;        MOVEP  X:(R4)+,X:SSITX ; Send out the waveform
640                             ;       JSR     <PAL_DLY        ; Wait for SSI and PAL to be empty
641                             ;       JSR     <SER_UTL        ; Return SSI to utility board communication
642                             ;       JMP     <FINISH
643    
644                             ; *******************************************************************
645                             ; Set the video processor boards in DC-coupled diagnostic mode or not
646                             ; Command syntax is  SDC #      # = 0 for normal operation
647                             ;                               # = 1 for DC coupled diagnostic mode
648       P:0322 P:0322 0D02C8  SET_DC    JSR     <SER_ANA                          ; Set SSI to analog board communication
649       P:0323 P:0323 44DC00            MOVE              X:(R4)+,X0
650       P:0324 P:0324 0AC420            JSET    #0,X0,SDC_1
                        000329
651       P:0326 P:0326 0A174A            BCLR    #10,Y:<GAIN
652       P:0327 P:0327 0A174B            BCLR    #11,Y:<GAIN
653       P:0328 P:0328 0C032B            JMP     <SDC_A
654       P:0329 P:0329 0A176A  SDC_1     BSET    #10,Y:<GAIN
655       P:032A P:032A 0A176B            BSET    #11,Y:<GAIN
656       P:032B P:032B 241000  SDC_A     MOVE              #$100000,X0             ; Increment value
657       P:032C P:032C 060F80            DO      #15,SDC_LOOP
                        000331
658       P:032E P:032E 08F0EF            MOVEP             Y:GAIN,X:SSITX
                        000017
659       P:0330 P:0330 0D021C            JSR     <PAL_DLY                          ; Wait for SSI and PAL to be empty
660       P:0331 P:0331 200048            ADD     X0,B                              ; Increment the video processor board number
661                             SDC_LOOP
662       P:0332 P:0332 0D02CF            JSR     <SER_UTL                          ; Return SSI to utility board communication
663       P:0333 P:0333 0C0000            JMP     <FINISH
664    
665                             ; *******************************************************************
666                             ; Set a particular DAC numbers, for setting DC bias voltages, clock driver
667                             ;   voltages and video processor offset
668                             ;
669                             ; SBN  #BOARD  ['CLK' or 'VID']  #DAC  voltage
670                             ;
671                             ;                               #BOARD is from 0 to 15
672                             ;                               #DAC number
673                             ;                               #voltage is from 0 to 4095
674    
675                             SET_BIAS_NUMBER                                     ; Set bias number
676       P:0334 P:0334 0D02C8            JSR     <SER_ANA                          ; Set SSI to analog board communication
677       P:0335 P:0335 56DC00            MOVE              X:(R4)+,A               ; First argument is board number, 0 to 15
678       P:0336 P:0336 0614A0            REP     #20
679       P:0337 P:0337 200033            LSL     A
680       P:0338 P:0338 21C400            MOVE              A,X0
681       P:0339 P:0339 56DC00            MOVE              X:(R4)+,A               ; Second argument is DAC number
682       P:033A P:033A 060EA0            REP     #14
683       P:033B P:033B 200033            LSL     A
684       P:033C P:033C 200042            OR      X0,A
685       P:033D P:033D 57DC00            MOVE              X:(R4)+,B               ; Third argument is 'VID' or 'CLK' string
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_common.asm  Page 13



686       P:033E P:033E 44F400            MOVE              #'VID',X0
                        564944
687       P:0340 P:0340 20004D            CMP     X0,B
688       P:0341 P:0341 0E2345            JNE     <CLK_DRV
689       P:0342 P:0342 0ACC73            BSET    #19,A1                            ; Set bits to mean video processor DAC
690       P:0343 P:0343 0ACC72            BSET    #18,A1
691       P:0344 P:0344 0C0349            JMP     <VID_BRD
692       P:0345 P:0345 44F400  CLK_DRV   MOVE              #'CLK',X0
                        434C4B
693       P:0347 P:0347 20004D            CMP     X0,B
694       P:0348 P:0348 0E2353            JNE     <ERR_SBN
695       P:0349 P:0349 21C400  VID_BRD   MOVE              A,X0
696       P:034A P:034A 56DC00            MOVE              X:(R4)+,A               ; Fourth argument is voltage value, 0 to $fff
697       P:034B P:034B 46F400            MOVE              #$000FFF,Y0             ; Mask off just 12 bits to be sure
                        000FFF
698       P:034D P:034D 200056            AND     Y0,A
699       P:034E P:034E 200042            OR      X0,A
700       P:034F P:034F 08CE2F            MOVEP             A,X:SSITX               ; Write the number to the DAC
701       P:0350 P:0350 0D021C            JSR     <PAL_DLY                          ; Wait for the number to be sent
702       P:0351 P:0351 0D02CF            JSR     <SER_UTL                          ; Return SSI to utility board communication
703       P:0352 P:0352 0C0000            JMP     <FINISH
704       P:0353 P:0353 56DC00  ERR_SBN   MOVE              X:(R4)+,A               ; Read and discard the fourth argument
705       P:0354 P:0354 0D02CF            JSR     <SER_UTL                          ; Return SSI to utility board communication
706       P:0355 P:0355 0C0000            JMP     <ERROR
707    
708                             ; *******************************************************************
709                             ; Specify the MUX value to be output on the clock driver board
710                             ; Command syntax is  SMX  #clock_driver_board #MUX1 #MUX2
711                             ;                               #clock_driver_board from 0 to 15
712                             ;                               #MUX1, #MUX2 from 0 to 23
713    
714       P:0356 P:0356 0D02C8  SET_MUX   JSR     <SER_ANA                          ; Set SSI to analog board communication
715       P:0357 P:0357 56DC00            MOVE              X:(R4)+,A               ; Clock driver board number
716       P:0358 P:0358 0614A0            REP     #20
717       P:0359 P:0359 200033            LSL     A
718       P:035A P:035A 44F400            MOVE              #$003000,X0
                        003000
719       P:035C P:035C 200042            OR      X0,A
720       P:035D P:035D 21C500            MOVE              A,X1                    ; Move here for storage
721    
722                             ; Get the first MUX number
723       P:035E P:035E 56DC00            MOVE              X:(R4)+,A               ; Get the first MUX number
724       P:035F P:035F 0AF0A9            JLT     ERR_SM1
                        0003A1
725       P:0361 P:0361 44F400            MOVE              #>24,X0                 ; Check for argument less than 32
                        000018
726       P:0363 P:0363 200045            CMP     X0,A
727       P:0364 P:0364 0AF0A1            JGE     ERR_SM1
                        0003A1
728       P:0366 P:0366 21CF00            MOVE              A,B
729       P:0367 P:0367 44F400            MOVE              #>7,X0
                        000007
730       P:0369 P:0369 20004E            AND     X0,B
731       P:036A P:036A 44F400            MOVE              #>$18,X0
                        000018
732       P:036C P:036C 200046            AND     X0,A
733       P:036D P:036D 0E2370            JNE     <SMX_1                            ; Test for 0 <= MUX number <= 7
734       P:036E P:036E 0ACD63            BSET    #3,B1
735       P:036F P:036F 0C037B            JMP     <SMX_A
736       P:0370 P:0370 44F400  SMX_1     MOVE              #>$08,X0
                        000008
737       P:0372 P:0372 200045            CMP     X0,A                              ; Test for 8 <= MUX number <= 15
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_common.asm  Page 14



738       P:0373 P:0373 0E2376            JNE     <SMX_2
739       P:0374 P:0374 0ACD64            BSET    #4,B1
740       P:0375 P:0375 0C037B            JMP     <SMX_A
741       P:0376 P:0376 44F400  SMX_2     MOVE              #>$10,X0
                        000010
742       P:0378 P:0378 200045            CMP     X0,A                              ; Test for 16 <= MUX number <= 23
743       P:0379 P:0379 0E23A1            JNE     <ERR_SM1
744       P:037A P:037A 0ACD65            BSET    #5,B1
745       P:037B P:037B 20006A  SMX_A     OR      X1,B1                             ; Add prefix to MUX numbers
746       P:037C P:037C 21A700            MOVE              B1,Y1
747    
748                             ; Add on the second MUX number
749       P:037D P:037D 56DC00            MOVE              X:(R4)+,A               ; Get the next MUX number
750       P:037E P:037E 0AF0A9            JLT     ERR_SM2
                        0003A2
751       P:0380 P:0380 44F400            MOVE              #>24,X0                 ; Check for argument less than 32
                        000018
752       P:0382 P:0382 200045            CMP     X0,A
753       P:0383 P:0383 0AF0A1            JGE     ERR_SM2
                        0003A2
754       P:0385 P:0385 0606A0            REP     #6
755       P:0386 P:0386 200033            LSL     A
756       P:0387 P:0387 21CF00            MOVE              A,B
757       P:0388 P:0388 44F400            MOVE              #$1C0,X0
                        0001C0
758       P:038A P:038A 20004E            AND     X0,B
759       P:038B P:038B 44F400            MOVE              #>$600,X0
                        000600
760       P:038D P:038D 200046            AND     X0,A
761       P:038E P:038E 0E2391            JNE     <SMX_3                            ; Test for 0 <= MUX number <= 7
762       P:038F P:038F 0ACD69            BSET    #9,B1
763       P:0390 P:0390 0C039C            JMP     <SMX_B
764       P:0391 P:0391 44F400  SMX_3     MOVE              #>$200,X0
                        000200
765       P:0393 P:0393 200045            CMP     X0,A                              ; Test for 8 <= MUX number <= 15
766       P:0394 P:0394 0E2397            JNE     <SMX_4
767       P:0395 P:0395 0ACD6A            BSET    #10,B1
768       P:0396 P:0396 0C039C            JMP     <SMX_B
769       P:0397 P:0397 44F400  SMX_4     MOVE              #>$400,X0
                        000400
770       P:0399 P:0399 200045            CMP     X0,A                              ; Test for 16 <= MUX number <= 23
771       P:039A P:039A 0E23A2            JNE     <ERR_SM2
772       P:039B P:039B 0ACD6B            BSET    #11,B1
773       P:039C P:039C 200078  SMX_B     ADD     Y1,B                              ; Add prefix to MUX numbers
774    
775       P:039D P:039D 08CD2F            MOVEP             B1,X:SSITX
776       P:039E P:039E 0D021C            JSR     <PAL_DLY                          ; Delay for all this to happen
777       P:039F P:039F 0D02CF            JSR     <SER_UTL                          ; Return SSI to utility board communication
778       P:03A0 P:03A0 0C0000            JMP     <FINISH
779       P:03A1 P:03A1 56DC00  ERR_SM1   MOVE              X:(R4)+,A
780       P:03A2 P:03A2 0D02CF  ERR_SM2   JSR     <SER_UTL                          ; Return SSI to utility board communication
781       P:03A3 P:03A3 0C0000            JMP     <ERROR
782    
783                             ; *******************************************************************
784                             ; Alert the PCI interface board that images are coming soon
785                             PCI_READ_IMAGE
786       P:03A4 P:03A4 44F400            MOVE              #$020104,X0             ; Send header word to the FO transmitter
                        020104
787       P:03A6 P:03A6 0D03B1            JSR     <XMT_FO
788       P:03A7 P:03A7 44F400            MOVE              #'RDA',X0
                        524441
789       P:03A9 P:03A9 0D03B1            JSR     <XMT_FO
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_common.asm  Page 15



790       P:03AA P:03AA 4CF000            MOVE                          Y:NSIMAGE,X0 ; Number of columns to read
                        00001B
791       P:03AC P:03AC 0D03B1            JSR     <XMT_FO
792       P:03AD P:03AD 4CF000            MOVE                          Y:NPIMAGE,X0 ; Number of rows to read
                        00001C
793       P:03AF P:03AF 0D03B1            JSR     <XMT_FO
794       P:03B0 P:03B0 00000C            RTS
795    
796                             ; *******************************************************************
797       P:03B1 P:03B1 09C400  XMT_FO    MOVEP             X0,Y:WRFO
798       P:03B2 P:03B2 060FA0            REP     #15
799       P:03B3 P:03B3 000000            NOP
800       P:03B4 P:03B4 00000C            RTS
801    
802    
803                             ;************************************************************************
804                             ;                                                                                               *
805                             ;    Permanent address register assignments                                     *
806                             ;        R1 - Address of SSI receiver contents                                  *
807                             ;        R2 - Address of SCI receiver contents                                  *
808                             ;      R3 - Pointer to current top of command buffer                    *
809                             ;      R4 - Pointer to processed contents of command buffer                     *
810                             ;      R5 - Temporary register for processing SSI and SCI contents      *
811                             ;      R6 - CCD clock driver address for CCD #0 = $FF80                 *
812                             ;           It is also the A/D address of analog board #0                       *
813                             ;                                                                                               *
814                             ;    Other registers                                                                    *
815                             ;      R0, R7 - Temporary registers used all over the place                     *
816                             ;      R5 - Can be used as a temporary register but is circular,                *
817                             ;           modulo 32                                                                   *
818                             ;************************************************************************
819    
820                             ; Specify execution and load addresses (internal RAM MPL)
821                                       IF      @SCP("HOST","HOST")
822       P:0130 P:0130                   ORG     P:APL_ADR,P:APL_ADR               ; Download address
823                                       ELSE
825                                       ENDIF
826    
827                             ; ***********************************************************************
828                             ; Include CCD readout routines
829                                       INCLUDE "tim2_rdccd.asm"
830                             ; *******************************************************************
831                             ; rdccd.asm for Gen 2
832                             ; Readout routines for CCD clocking
833                             ; last change 09Sep07 MPL
834    
835                             ; *******************************************************************
836    
837                             ; Main loop, transfer and read rows
838                             RDCCD
839       P:0130 P:0130 0A0024            BSET    #ST_RDC,X:<STATUS                 ; Set status to reading out
840       P:0131 P:0131 0D03A4            JSR     <PCI_READ_IMAGE                   ; Get the PCI board reading the image
841    
842       P:0132 P:0132 0AA421            BSET    #WW,X:PBD                         ; Set WW = 1 for 16-bit image data
843       P:0133 P:0133 0A00AA            JSET    #TST_IMG,X:STATUS,SYNTHETIC_IMAGE
                        00022F
844    
845                             ; comment next lines to save P: memory
846                             ;       MOVE    Y:<AREAD0,R0            ; read mode setup
847                             ;       JSR     <CLOCK
848    
849       P:0135 P:0135 68A500            MOVE                          Y:<AFPXFER0,R0 ; fast par transfer setup
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_rdccd.asm  Page 16



850       P:0136 P:0136 0D01D7            JSR     <CLOCK
851    
852       P:0137 P:0137 301500            MOVE              #<FRAMET,R0             ; frame transfer
853       P:0138 P:0138 0D0189            JSR     <PQSKIP
854       P:0139 P:0139 0E8008            JCS     <START
855    
856       P:013A P:013A 300E00            MOVE              #<NPPRESKIP,R0          ; skip to underscan
857       P:013B P:013B 0D017E            JSR     <PSKIP
858       P:013C P:013C 0E8008            JCS     <START
859       P:013D P:013D 68A600            MOVE                          Y:<AFPXFER2,R0 ; end fast par transfer
860       P:013E P:013E 0D01D7            JSR     <CLOCK
861       P:013F P:013F 300700            MOVE              #<NSCLEAR,R0            ; flush
862       P:0140 P:0140 0D019F            JSR     <FSSKIP
863    
864       P:0141 P:0141 300F00            MOVE              #<NPUNDERSCAN,R0        ; read underscan
865       P:0142 P:0142 0D0158            JSR     <PDATA
866       P:0143 P:0143 0E8008            JCS     <START
867    
868       P:0144 P:0144 68A500            MOVE                          Y:<AFPXFER0,R0 ; fast par transfer setup
869       P:0145 P:0145 0D01D7            JSR     <CLOCK
870       P:0146 P:0146 301000            MOVE              #<NPSKIP,R0             ; skip to ROI
871       P:0147 P:0147 0D017E            JSR     <PSKIP
872       P:0148 P:0148 0E8008            JCS     <START
873       P:0149 P:0149 68A600            MOVE                          Y:<AFPXFER2,R0 ; end fast par transfer
874       P:014A P:014A 0D01D7            JSR     <CLOCK
875       P:014B P:014B 300700            MOVE              #<NSCLEAR,R0            ; flush
876       P:014C P:014C 0D019F            JSR     <FSSKIP
877    
878       P:014D P:014D 300200            MOVE              #<NPDATA,R0             ; read ROI
879       P:014E P:014E 0D0158            JSR     <PDATA
880       P:014F P:014F 0E8008            JCS     <START
881    
882                             ; 13jul06 MPL added to finish if no overscan rows
883                             ;       MOVE  #<NPOVERSCAN,A
884                             ;       TST     A
885                             ;       JLE     <RDC_END
886    
887                             ;       MOVE    Y:<AFPXFER0,R0          ; fast par transfer setup
888                             ;       JSR     <CLOCK
889                             ;       MOVE  #<NPPOSTSKIP,R0           ; skip to overscan
890                             ;       JSR   <PSKIP
891                             ;       JCS     <START
892                             ;       MOVE    Y:<AFPXFER2,R0          ; end fast par transfer
893                             ;       JSR     <CLOCK
894                             ;       MOVE  #<NSCLEAR,R0              ; flush
895                             ;       JSR     <FSSKIP
896    
897                             ;       MOVE  #<NPOVERSCAN,R0           ; read overscan
898                             ;       JSR   <PDATA
899                             ;       JCS     <START
900    
901                             ;       MOVE    Y:<AREAD8,R0            ; end read mode
902                             ;       JSR     <CLOCK
903    
904                             RDC_END
905       P:0150 P:0150 0A0082            JCLR    #IDLMODE,X:<STATUS,RDC_E          ; Don't idle after readout
                        000155
906       P:0152 P:0152 44F400            MOVE              #IDLE,X0
                        000212
907       P:0154 P:0154 440000            MOVE              X0,X:<IDL_ADR
908                             RDC_E
909       P:0155 P:0155 0AA401            BCLR    #WW,X:PBD                         ; Clear WW to 0 for 24-bit commands
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_rdccd.asm  Page 17



910       P:0156 P:0156 0A0004            BCLR    #ST_RDC,X:<STATUS                 ; Set status to not reading out
911       P:0157 P:0157 0C0008            JMP     <START                            ; Wait for a new command
912    
913                             ; *******************************************************************
914                             PDATA
915       P:0158 P:0158 0D01D0            JSR     <CNPAMPS                          ; compensate for split register
916       P:0159 P:0159 0EF171            JLE     <PDATA0
917       P:015A P:015A 06CE00            DO      A,PDATA0                          ; loop through # of binned rows into each serial
 register
                        000170
918       P:015C P:015C 300400            MOVE              #<NPBIN,R0              ; shift NPBIN rows into serial register
919       P:015D P:015D 0D0172            JSR     <PDSKIP
920       P:015E P:015E 0E0161            JCC     <PDATA1
921       P:015F P:015F 00008C            ENDDO
922       P:0160 P:0160 0C0171            JMP     <PDATA0
923                             PDATA1
924       P:0161 P:0161 300900            MOVE              #<NSPRESKIP,R0          ; skip to serial underscan
925       P:0162 P:0162 0D01A7            JSR     <SSKIP
926       P:0163 P:0163 300A00            MOVE              #<NSUNDERSCAN,R0        ; read underscan
927       P:0164 P:0164 0D01B1            JSR     <SDATA
928       P:0165 P:0165 300B00            MOVE              #<NSSKIP,R0             ; skip to ROI
929       P:0166 P:0166 0D01A7            JSR     <SSKIP
930       P:0167 P:0167 300100            MOVE              #<NSDATA,R0             ; read ROI
931       P:0168 P:0168 0D01B1            JSR     <SDATA
932       P:0169 P:0169 300C00            MOVE              #<NSPOSTSKIP,R0         ; skip to serial overscan
933       P:016A P:016A 0D01A7            JSR     <SSKIP
934       P:016B P:016B 300D00            MOVE              #<NSOVERSCAN,R0         ; read overscan
935       P:016C P:016C 0D01B1            JSR     <SDATA
936       P:016D P:016D 0AF940            BCLR    #0,SR                             ; set CC
937       P:016E P:016E 000000            NOP
938       P:016F P:016F 000000            NOP
939       P:0170 P:0170 000000            NOP
940                             PDATA0
941       P:0171 P:0171 00000C            RTS
942    
943                             ; *******************************************************************
944                             PDSKIP
945       P:0172 P:0172 5EE000            MOVE                          Y:(R0),A    ; shift data lines into serial reg
946       P:0173 P:0173 200003            TST     A
947       P:0174 P:0174 0EF17D            JLE     <PDSKIP0
948       P:0175 P:0175 066040            DO      Y:(R0),PDSKIP0
                        00017C
949       P:0177 P:0177 68A800            MOVE                          Y:<APDXFER,R0
950       P:0178 P:0178 0D01DE            JSR     <PCLOCK
951       P:0179 P:0179 0D0000            JSR     <GET_RCV
952       P:017A P:017A 0E017C            JCC     <PDSKIP1
953       P:017B P:017B 00008C            ENDDO
954                             PDSKIP1
955       P:017C P:017C 000000            NOP
956                             PDSKIP0
957       P:017D P:017D 00000C            RTS
958    
959                             ; *******************************************************************
960                             PSKIP
961       P:017E P:017E 0D01D0            JSR     <CNPAMPS
962       P:017F P:017F 0EF188            JLE     <PSKIP0
963       P:0180 P:0180 06CE00            DO      A,PSKIP0
                        000187
964       P:0182 P:0182 68A700            MOVE                          Y:<APXFER,R0
965       P:0183 P:0183 0D01DE            JSR     <PCLOCK
966       P:0184 P:0184 0D0000            JSR     <GET_RCV
967       P:0185 P:0185 0E0187            JCC     <PSKIP1
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_rdccd.asm  Page 18



968       P:0186 P:0186 00008C            ENDDO
969                             PSKIP1
970       P:0187 P:0187 000000            NOP
971                             PSKIP0
972       P:0188 P:0188 00000C            RTS
973    
974                             ; *******************************************************************
975                             PQSKIP
976       P:0189 P:0189 0D01D0            JSR     <CNPAMPS
977       P:018A P:018A 0EF193            JLE     <PQSKIP0
978       P:018B P:018B 06CE00            DO      A,PQSKIP0
                        000192
979       P:018D P:018D 68A900            MOVE                          Y:<APQXFER,R0
980       P:018E P:018E 0D01DE            JSR     <PCLOCK
981       P:018F P:018F 0D0000            JSR     <GET_RCV
982       P:0190 P:0190 0E0192            JCC     <PQSKIP1
983       P:0191 P:0191 00008C            ENDDO
984                             PQSKIP1
985       P:0192 P:0192 000000            NOP
986                             PQSKIP0
987       P:0193 P:0193 00000C            RTS
988    
989                             ; *******************************************************************
990                             RSKIP
991       P:0194 P:0194 0D01D0            JSR     <CNPAMPS
992       P:0195 P:0195 0EF19E            JLE     <RSKIP0
993       P:0196 P:0196 06CE00            DO      A,RSKIP0
                        00019D
994       P:0198 P:0198 68AA00            MOVE                          Y:<ARXFER,R0
995       P:0199 P:0199 0D01DE            JSR     <PCLOCK
996       P:019A P:019A 0D0000            JSR     <GET_RCV
997       P:019B P:019B 0E019D            JCC     <RSKIP1
998       P:019C P:019C 00008C            ENDDO
999                             RSKIP1
1000      P:019D P:019D 000000            NOP
1001                            RSKIP0
1002      P:019E P:019E 00000C            RTS
1003   
1004                            ; *******************************************************************
1005                            FSSKIP
1006      P:019F P:019F 0D01CA            JSR     <CNSAMPS
1007      P:01A0 P:01A0 0EF1A6            JLE     <FSSKIP0
1008      P:01A1 P:01A1 06CE00            DO      A,FSSKIP0
                        0001A5
1009      P:01A3 P:01A3 68AB00            MOVE                          Y:<AFSXFER,R0
1010      P:01A4 P:01A4 0D01D7            JSR     <CLOCK
1011      P:01A5 P:01A5 000000            NOP
1012                            FSSKIP0
1013      P:01A6 P:01A6 00000C            RTS
1014   
1015                            ; *******************************************************************
1016                            SSKIP
1017      P:01A7 P:01A7 0D01CA            JSR     <CNSAMPS
1018      P:01A8 P:01A8 0EF1B0            JLE     <SSKIP0
1019      P:01A9 P:01A9 06CE00            DO      A,SSKIP0
                        0001AF
1020      P:01AB P:01AB 68AC00            MOVE                          Y:<ASXFER0,R0
1021      P:01AC P:01AC 0D01D7            JSR     <CLOCK
1022      P:01AD P:01AD 68AE00            MOVE                          Y:<ASXFER2,R0
1023      P:01AE P:01AE 0D01D7            JSR     <CLOCK
1024      P:01AF P:01AF 000000            NOP
1025                            SSKIP0
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_rdccd.asm  Page 19



1026      P:01B0 P:01B0 00000C            RTS
1027   
1028                            ; *******************************************************************
1029                            SDATA
1030      P:01B1 P:01B1 0D01CA            JSR     <CNSAMPS
1031      P:01B2 P:01B2 0EF1C3            JLE     <SDATA0
1032      P:01B3 P:01B3 06CE00            DO      A,SDATA0
                        0001C2
1033      P:01B5 P:01B5 68AC00            MOVE                          Y:<ASXFER0,R0
1034      P:01B6 P:01B6 0D01D7            JSR     <CLOCK
1035      P:01B7 P:01B7 448000            MOVE              X:<ONE,X0               ; Get bin-1
1036      P:01B8 P:01B8 5E8300            MOVE                          Y:<NSBIN,A
1037      P:01B9 P:01B9 200044            SUB     X0,A
1038      P:01BA P:01BA 0EF1C0            JLE     <SDATA1
1039      P:01BB P:01BB 06CE00            DO      A,SDATA1
                        0001BF
1040      P:01BD P:01BD 68AD00            MOVE                          Y:<ASXFER1,R0
1041      P:01BE P:01BE 0D01D7            JSR     <CLOCK
1042      P:01BF P:01BF 000000            NOP
1043                            SDATA1
1044      P:01C0 P:01C0 68AF00            MOVE                          Y:<ASXFER2D,R0 ; clock the data
1045      P:01C1 P:01C1 0D01D7            JSR     <CLOCK
1046   
1047                            ;       CLR     A
1048                            ;       MOVEP   A,Y:WRFO                ; MPL special test
1049   
1050                            ;       MOVE Y:$FFA0,A          ; read ADC 0/0
1051                            ;       MOVEP   A,Y:WRFO                ; write to fiber
1052   
1053                            SDATA0T
1054      P:01C2 P:01C2 000000            NOP
1055                            SDATA0
1056      P:01C3 P:01C3 00000C            RTS
1057   
1058                            ; *******************************************************************
1059                            FOR_PSHIFT
1060      P:01C4 P:01C4 301300            MOVE              #<NPXSHIFT,R0
1061      P:01C5 P:01C5 0D017E            JSR     <PSKIP
1062      P:01C6 P:01C6 0C0000            JMP     <FINISH
1063   
1064                            ; *******************************************************************
1065                            REV_PSHIFT
1066      P:01C7 P:01C7 301300            MOVE              #<NPXSHIFT,R0
1067      P:01C8 P:01C8 0D0194            JSR     <RSKIP
1068      P:01C9 P:01C9 0C0000            JMP     <FINISH
1069   
1070                            ; *******************************************************************
1071                            ; Compensate for split serial
1072      P:01CA P:01CA 5EE000  CNSAMPS   MOVE                          Y:(R0),A    ; get num pixels to read
1073      P:01CB P:01CB 0A05C0            JCLR    #0,Y:<NSAMPS,CNSAMP1              ; split register?
                        0001CE
1074      P:01CD P:01CD 200022            ASR     A                                 ; yes, divide by 2
1075      P:01CE P:01CE 200003  CNSAMP1   TST     A
1076      P:01CF P:01CF 00000C            RTS
1077   
1078                            ; *******************************************************************
1079                            ; Compensate for split parallel
1080      P:01D0 P:01D0 5EE000  CNPAMPS   MOVE                          Y:(R0),A    ; get num rows to shift
1081      P:01D1 P:01D1 0A06C0            JCLR    #0,Y:<NPAMPS,CNPAMP1              ; split parallels?
                        0001D4
1082      P:01D3 P:01D3 200022            ASR     A                                 ; yes, divide by 2
1083      P:01D4 P:01D4 200003  CNPAMP1   TST     A
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_rdccd.asm  Page 20



1084      P:01D5 P:01D5 0AF940            BCLR    #0,SR                             ; clear carry ???
1085      P:01D6 P:01D6 00000C            RTS
1086   
1087                            ; *******************************************************************
1088                            ; Core subroutine for clocking out CCD charge
1089      P:01D7 P:01D7 4CD800  CLOCK     MOVE                          Y:(R0)+,X0  ; # of waveform entries
1090      P:01D8 P:01D8 5ED800            MOVE                          Y:(R0)+,A   ; Start the pipeline
1091      P:01D9 P:01D9 06C400            DO      X0,CLK1                           ; Repeat X0 times
                        0001DB
1092      P:01DB P:01DB FA0600            MOVE              A,X:(R6)    Y:(R0)+,A   ; Send out the waveform
1093                            CLK1
1094      P:01DC P:01DC 566600            MOVE              A,X:(R6)                ; Flush out the pipeline
1095      P:01DD P:01DD 00000C            RTS                                       ; Return from subroutine
1096   
1097                            ; *******************************************************************
1098                            ;  Slow clock for parallel shifts
1099                            PCLOCK
1100      P:01DE P:01DE 5ED800            MOVE                          Y:(R0)+,A   ; # of waveform entries
1101      P:01DF P:01DF 448000            MOVE              X:<ONE,X0               ; Add 1 - no pipeline prime
1102      P:01E0 P:01E0 200040            ADD     X0,A
1103      P:01E1 P:01E1 06CE00            DO      A,PCLK1
                        0001E7
1104      P:01E3 P:01E3 5ED800            MOVE                          Y:(R0)+,A   ; Get the waveform
1105      P:01E4 P:01E4 062040            DO      Y:<PMULT,PCLK2
                        0001E6
1106      P:01E6 P:01E6 566600            MOVE              A,X:(R6)                ; Send out the waveform
1107                            PCLK2
1108      P:01E7 P:01E7 000000            NOP
1109                            PCLK1
1110      P:01E8 P:01E8 00000C            RTS                                       ; Return from subroutine
1111   
1112   
1113                            ; Check for program overflow
1114                                      IF      @CVS(N,*)>$200
1116                                      ENDIF                                     ; will not overflow
1117   
1118                            ; ***********  DATA AREAS - READOUT PARAMETERS AND WAVEFORMS  ************
1119   
1120                            ; Command table - make sure there are exactly 32 entries in it
1121                                      IF      @SCP("HOST","HOST")
1122      X:0080 X:0080                   ORG     X:COM_TBL,X:COM_TBL               ; Download address
1123                                      ELSE
1125                                      ENDIF
1126   
1127      X:0080 X:0080                   DC      'IDL',IDL                         ; Put CCD in IDLE mode
1128      X:0082 X:0082                   DC      'STP',STP                         ; Exit IDLE mode
1129      X:0084 X:0084                   DC      'SBV',SETBIAS                     ; Set DC bias supply voltages
1130      X:0086 X:0086                   DC      'RDC',RDCCD                       ; Begin CCD readout
1131      X:0088 X:0088                   DC      'CLR',CLEAR                       ; Fast clear the CCD
1132      X:008A X:008A                   DC      'SGN',ST_GAIN                     ; Set video processor gain
1133      X:008C X:008C                   DC      'SDC',SET_DC                      ; Set DC coupled diagnostic mode
1134      X:008E X:008E                   DC      'SBN',SET_BIAS_NUMBER             ; Set bias number
1135      X:0090 X:0090                   DC      'SMX',SET_MUX                     ; Set clock driver MUX outputs
1136      X:0092 X:0092                   DC      'CSW',CLR_SWS                     ; Clear analog switches to reduce power drain
1137      X:0094 X:0094                   DC      'RCC',READ_CONTROLLER_CONFIGURATION ; Read controller configuration
1138                            ;       DC      'SOS',SEL_OS                    ; Select Output Source
1139                            ;       DC      'SSS',SET_SUBARRAY_SIZES        ; Set ROI sizes
1140                            ;       DC      'SSP',SET_SUBARRAY_POSITIONS    ; Set ROI positions
1141   
1142      X:0096 X:0096                   DC      'OSH',OPEN_SHUTTER                ; Open shutter
1143      X:0098 X:0098                   DC      'CSH',CLOSE_SHUTTER               ; Close shutter
1144   
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2.asm  Page 21



1145      X:009A X:009A                   DC      'PON',PWR_ON                      ; Turn on all camera biases and clocks
1146      X:009C X:009C                   DC      'POF',PWR_OFF                     ; Turn +/- 15V power supplies off
1147   
1148      X:009E X:009E                   DC      'SET',SET_EXP_TIME                ; Set exposure time
1149      X:00A0 X:00A0                   DC      'RET',RD_EXP_TIME                 ; Read elapsed exposure time
1150   
1151      X:00A2 X:00A2                   DC      'SEX',START_EXPOSURE              ; Start exposure, immediate return
1152      X:00A4 X:00A4                   DC      0,START                           ; unused
1153      X:00A6 X:00A6                   DC      'PEX',PAUSE_EXPOSURE              ; Pause exposure
1154      X:00A8 X:00A8                   DC      'REX',RESUME_EXPOSURE             ; Resume a paused exposure
1155      X:00AA X:00AA                   DC      'AEX',ABORT_EXPOSURE              ; Abort a paused exposure
1156   
1157      X:00AC X:00AC                   DC      'FPX',FOR_PSHIFT                  ; Forward parallel shift
1158      X:00AE X:00AE                   DC      'RPX',REV_PSHIFT                  ; Reverse parallel shift
1159   
1160      X:00B0 X:00B0                   DC      'DON',START                       ; Nothing special
1161      X:00B2 X:00B2                   DC      0,START,0,START                   ; unused
1162      X:00B6 X:00B6                   DC      0,START                           ; unused
1163   
1164                            ; Include the waveform table at Y:0
1165   
1166                                      IF      @SCP("HOST","HOST")
1167      Y:0000 Y:0000                   ORG     Y:0,Y:0                           ; Download address
1168                                      ELSE
1170                                      ENDIF
1171   
1172                            ; ***********************************************************************
1173                            ; Include waveform files
1174                                      INCLUDE "waveforms.asm"                   ; readout waveforms
1175                            ; waveforms.asm for vattspec
1176                            ; STA0520A CCD
1177                            ; Gen2 controller
1178                            ; 08Sep10 MPL last change
1179   
1180                            ; *** boards ***
1181      000000                VIDEO     EQU     $000000                           ; Video processor board (all are addressed toget
her)
1182      002000                CLK2      EQU     $002000                           ; Clock driver board select = board 2 low bank
1183      003000                CLK3      EQU     $003000                           ; Clock driver board select = board 2 high bank
1184   
1185                            ;***  timing ***
1186      001388                P_DEL2    EQU     5000                              ; P clock delay nsec (80-20,400 ns inc 160)
1187      000078                S_DEL2    EQU     120                               ; S clock delay nsec (80-2,620 ns inc 20)
1188      000050                V_DEL2    EQU     80                                ; VP delay nsec (80-2620 ns inc 20)
1189      0007D0                DWEL      EQU     2000                              ; sample time  (80-20400 ns inc 160)
1190      000005                PARMULT   EQU     5                                 ; P_DELAY multiplier
1191      000002                GENCNT    EQU     2                                 ; Gen clock counter (2 for gen1/2, 1 for gen3)
1192   
1193   
1194                            ; *** clock rails ***
1195      8.000000E+000         RG_HI     EQU     +8.0                              ; Reset Gate
1196      -2.000000E+000        RG_LO     EQU     -2.0
1197      4.000000E+000         S_HI      EQU     +4.0                              ; Serial clocks
1198      -4.000000E+000        S_LO      EQU     -4.0
1199      4.000000E+000         SW_HI     EQU     +4.0                              ; Summing well
1200      -4.000000E+000        SW_LO     EQU     -4.0
1201      1.000000E+000         P_HI      EQU     +1.0                              ; Parallel clocks
1202      -8.000000E+000        P_LO      EQU     -8.0
1203      2.000000E+000         P3_HI     EQU     +2.0                              ; Parallel 3 clock
1204      -6.000000E+000        P3_LO     EQU     -6.0
1205      0.000000E+000         TG_HI     EQU     +0.0                              ; not used
1206      0.000000E+000         TG_LO     EQU     +0.0                              ; not used
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  waveforms.asm  Page 22



1207   
1208                            ; *** bias voltages ***
1209      2.500000E+001         VOD       EQU     +25.0                             ; Output Drains
1210      1.500000E+001         VRD       EQU     +15.0                             ; Reset Drain
1211      -1.000000E+000        VOG       EQU     -1.0                              ; Output Gate
1212      0.000000E+000         B5        EQU     0.0                               ; not used
1213      0.000000E+000         B7        EQU     0.0                               ; not used
1214   
1215                            ; *** video output offset ***
1216                            ; higher value here lowers output value (~4.8 DN change/unit change here)
1217      0008FC                OFFSET    EQU     2300                              ; global offset to all channels
1218      000000                OFFSET0   EQU     0                                 ; offsets for channel 0
1219      000000                OFFSET1   EQU     0                                 ; offsets for channel 1
1220   
1221                            ; *** aliases ***
1222      4.000000E+000         S1_HI     EQU     S_HI
1223      -4.000000E+000        S1_LO     EQU     S_LO
1224      4.000000E+000         S2_HI     EQU     S_HI
1225      -4.000000E+000        S2_LO     EQU     S_LO
1226      4.000000E+000         S3_HI     EQU     S_HI
1227      -4.000000E+000        S3_LO     EQU     S_LO
1228      1.000000E+000         P1_HI     EQU     P_HI
1229      -8.000000E+000        P1_LO     EQU     P_LO
1230      1.000000E+000         P2_HI     EQU     P_HI
1231      -8.000000E+000        P2_LO     EQU     P_LO
1232      1.000000E+000         Q1_HI     EQU     P_HI
1233      -8.000000E+000        Q1_LO     EQU     P_LO
1234      1.000000E+000         Q2_HI     EQU     P_HI
1235      -8.000000E+000        Q2_LO     EQU     P_LO
1236      2.000000E+000         Q3_HI     EQU     P3_HI
1237      -6.000000E+000        Q3_LO     EQU     P3_LO
1238   
1239                            ; video channel 0 direction has some par-ser issues which cause columner structure
1240                            ; *** video channels ***
1241                            ;SXMIT  EQU     $00F000 ; Transmit A/D = 0
1242      00F021                SXMIT     EQU     $00F021                           ; Transmit A/D = 1
1243   
1244                            ;SXMIT          EQU     $00F020 ; Transmit A/D channels #0 to #1
1245   
1246                            ; *** include files and routines ***
1247                                      INCLUDE "includes.asm"
1248                            ; *** DSP Y memory parameter table - downloaded by AzCamTool ***
1249                                      INCLUDE "Ypars.asm"
1250                            ; Values in this block start at Y:0 and are overwritten by AzCamTool
1251                            ; with WRM commands.  They are not overwritten by waveform tables.
1252                            ; All values are unbinned pixels unless noted.
1253   
1254      Y:0000 Y:0000         CAMSTAT   DC      0                                 ; not used
1255      Y:0001 Y:0001         NSDATA    DC      1                                 ; number BINNED serial columns in ROI
1256      Y:0002 Y:0002         NPDATA    DC      1                                 ; number of BINNED parallel rows in ROI
1257      Y:0003 Y:0003         NSBIN     DC      1                                 ; Serial binning parameter (>= 1)
1258      Y:0004 Y:0004         NPBIN     DC      1                                 ; Parallel binning parameter (>= 1)
1259   
1260      Y:0005 Y:0005         NSAMPS    DC      0                                 ; 0 => 1 amp, 1 => split serials
1261      Y:0006 Y:0006         NPAMPS    DC      0                                 ; 0 => 1 amp, 1 => split parallels
1262      Y:0007 Y:0007         NSCLEAR   DC      1                                 ; number of columns to clear during flush
1263      Y:0008 Y:0008         NPCLEAR   DC      1                                 ; number of rows to clear during flush
1264   
1265      Y:0009 Y:0009         NSPRESKIP DC      0                                 ; number of cols to skip before underscan
1266                             NSUNDERSCAN
1267      Y:000A Y:000A                   DC      0                                 ; number of BINNED columns in underscan
1268      Y:000B Y:000B         NSSKIP    DC      0                                 ; number of cols to skip between underscan and d
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  Ypars.asm  Page 23



ata
1269      Y:000C Y:000C         NSPOSTSKIP DC     0                                 ; number of cols to skip between data and oversc
an
1270      Y:000D Y:000D         NSOVERSCAN DC     0                                 ; number of BINNED columns in overscan
1271   
1272      Y:000E Y:000E         NPPRESKIP DC      0                                 ; number of rows to skip before underscan
1273                             NPUNDERSCAN
1274      Y:000F Y:000F                   DC      0                                 ; number of BINNED rows in underscan
1275      Y:0010 Y:0010         NPSKIP    DC      0                                 ; number of rows to skip between underscan and d
ata
1276      Y:0011 Y:0011         NPPOSTSKIP DC     0                                 ; number of rows to skip between data and oversc
an
1277      Y:0012 Y:0012         NPOVERSCAN DC     0                                 ; number of BINNED rows in overscan
1278   
1279      Y:0013 Y:0013         NPXSHIFT  DC      0                                 ; number of rows to parallel shift
1280      Y:0014 Y:0014         TESTDATA  DC      0                                 ; 0 => normal, 1 => send incremented fake data
1281      Y:0015 Y:0015         FRAMET    DC      0                                 ; number of storage rows for frame transfer shif
t
1282      Y:0016 Y:0016         PREFLASH  DC      0                                 ; not used
1283      Y:0017 Y:0017         GAIN      DC      0                                 ; Video proc gain and integrator speed stored he
re
1284      Y:0018 Y:0018         TST_DAT   DC      0                                 ; Place for synthetic test image pixel data
1285      Y:0019 Y:0019         SH_DEL    DC      100                               ; Delay (msecs) between shutter closing and imag
e readout
1286      Y:001A Y:001A         CONFIG    DC      CC                                ; Controller configuration
1287      Y:001B Y:001B         NSIMAGE   DC      1                                 ; total number of columns in image
1288      Y:001C Y:001C         NPIMAGE   DC      1                                 ; total number of rows in image
1289      Y:001D Y:001D         PAD3      DC      0                                 ; unused
1290      Y:001E Y:001E         PAD4      DC      0                                 ; unused
1291      Y:001F Y:001F         IDLEONE   DC      2                                 ; lines to shift in IDLE (really 1)
1292   
1293                            ; Values in this block start at Y:20 and are overwritten if waveform table
1294                            ; is downloaded
1295      Y:0020 Y:0020         PMULT     DC      PARMULT                           ; parallel clock multiplier
1296      Y:0021 Y:0021         ACLEAR0   DC      TNOP                              ; Clear prologue - NOT USED
1297      Y:0022 Y:0022         ACLEAR2   DC      TNOP                              ; Clear epilogue - NOT USED
1298      Y:0023 Y:0023         AREAD0    DC      TNOP                              ; Read prologue - NOT USED
1299      Y:0024 Y:0024         AREAD8    DC      TNOP                              ; Read epilogue - NOT USED
1300      Y:0025 Y:0025         AFPXFER0  DC      FPXFER0                           ; Fast parallel transfer prologue
1301      Y:0026 Y:0026         AFPXFER2  DC      FPXFER2                           ; Fast parallel transfer epilogue
1302      Y:0027 Y:0027         APXFER    DC      PXFER                             ; Parallel transfer - storage only
1303      Y:0028 Y:0028         APDXFER   DC      PXFER                             ; Parallel transfer (data) - storage only
1304      Y:0029 Y:0029         APQXFER   DC      PQXFER                            ; Parallel transfer - storage and image
1305      Y:002A Y:002A         ARXFER    DC      RXFER                             ; Reverse parallel transfer (for focus)
1306      Y:002B Y:002B         AFSXFER   DC      FSXFER                            ; Fast serial transfer
1307      Y:002C Y:002C         ASXFER0   DC      SXFER0                            ; Serial transfer prologue
1308      Y:002D Y:002D         ASXFER1   DC      SXFER1                            ; Serial transfer ( * colbin-1 )
1309      Y:002E Y:002E         ASXFER2   DC      SXFER2                            ; Serial transfer epilogue - no data
1310      Y:002F Y:002F         ASXFER2D  DC      SXFER2D                           ; Serial transfer epilogue - data
1311      Y:0030 Y:0030         ADACS     DC      DACS
1312   
1313                            ; *** clock state bits ***
1314                                      INCLUDE "SwitchStates.asm"
1315                            ; Switch state bits for clocks
1316                            ; ITL standard Gen2/Gen3 edge connector
1317   
1318                            ; low bank (usually CLK2)
1319      000000                RGL       EQU     0                                 ;       CLK0    Pin 1
1320      000001                RGH       EQU     1                                 ;       CLK0
1321      000000                P1L       EQU     0                                 ;       CLK1    Pin 2
1322      000002                P1H       EQU     2                                 ;       CLK1
1323      000000                P2L       EQU     0                                 ;       CLK2    Pin 3
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  SwitchStates.asm  Page 24



1324      000004                P2H       EQU     4                                 ;       CLK2
1325      000000                P3L       EQU     0                                 ;       CLK3    Pin 4
1326      000008                P3H       EQU     8                                 ;       CLK3
1327      000000                S1L       EQU     0                                 ;       CLK4    Pin 5
1328      000010                S1H       EQU     $10                               ;       CLK4
1329      000000                S3L       EQU     0                                 ;       CLK5    Pin 6
1330      000020                S3H       EQU     $20                               ;       CLK5
1331      000000                S2L       EQU     0                                 ;       CLK6    Pin 7
1332      000040                S2H       EQU     $40                               ;       CLK6
1333      000000                Q3L       EQU     0                                 ;       CLK7    Pin 8
1334      000080                Q3H       EQU     $80                               ;       CLK7
1335      000000                Q2L       EQU     0                                 ;       CLK8    Pin 9
1336      000100                Q2H       EQU     $100                              ;       CLK8
1337      000000                Q1L       EQU     0                                 ;       CLK9    Pin 10
1338      000200                Q1H       EQU     $200                              ;       CLK9
1339      000000                SWL       EQU     0                                 ;       CLK10   Pin 11
1340      000400                SWH       EQU     $400                              ;       CLK10
1341      000000                TGL       EQU     0                                 ;       CLK10   Pin 12
1342      000800                TGH       EQU     $800                              ;       CLK10
1343   
1344                            ; high bank (usually CLK3) - not used
1345      000000                Z1L       EQU     0                                 ;       CLK12   Pin 13
1346      001000                Z1H       EQU     $1000                             ;       CLK12
1347      000000                Z2L       EQU     0                                 ;       CLK13   Pin 14
1348      002000                Z2H       EQU     $2000                             ;       CLK13
1349      000000                Z3L       EQU     0                                 ;       CLK14   Pin 15
1350      004000                Z3H       EQU     $4000                             ;       CLK14
1351      000000                Z4L       EQU     0                                 ;       CLK15   Pin 16
1352      008000                Z4H       EQU     $8000                             ;       CLK15
1353      000000                Z5L       EQU     0                                 ;       CLK16   Pin 17
1354      010000                Z5H       EQU     $10000                            ;       CLK16
1355      000000                Z6L       EQU     0                                 ;       CLK17   Pin 18
1356      020000                Z6H       EQU     $20000                            ;       CLK17
1357      000000                Z7L       EQU     0                                 ;       CLK18   Pin 19
1358      040000                Z7H       EQU     $40000                            ;       CLK18
1359      000000                Z8L       EQU     0                                 ;       CLK19   Pin 33
1360      080000                Z8H       EQU     $80000                            ;       CLK19
1361      000000                Z9L       EQU     0                                 ;       CLK20   Pin 34
1362      100000                Z9H       EQU     $100000                           ;       CLK20
1363      000000                Z10L      EQU     0                                 ;       CLK21   Pin 35
1364      200000                Z10H      EQU     $200000                           ;       CLK21
1365      000000                Z11L      EQU     0                                 ;       CLK22   Pin 36
1366      400000                Z11H      EQU     $400000                           ;       CLK22
1367      000000                Z12L      EQU     0                                 ;       CLK23   Pin 37
1368      800000                Z12H      EQU     $800000                           ;       CLK23
1369   
1370                            ; *** bias voltage table ***
1371                                      INCLUDE "DACS.asm"
1372                            ; This table is sent by the SETBIAS command to update clock board values.
1373                            ; The format is BBBB DDDD DDMM VVVV VVVV VVVV (board, DAC, Mode, Value)
1374   
1375      Y:0031 Y:0031         DACS      DC      EDACS-DACS-GENCNT
1376      Y:0032 Y:0032                   DC      (CLK2<<8)+(0<<14)+@CVI((RG_HI+10.0)/20.0*4095) ; RG High
1377      Y:0033 Y:0033                   DC      (CLK2<<8)+(1<<14)+@CVI((RG_LO+10.0)/20.0*4095) ; RG Low
1378      Y:0034 Y:0034                   DC      (CLK2<<8)+(2<<14)+@CVI((P1_HI+10.0)/20.0*4095) ; P1 High -- storage
1379      Y:0035 Y:0035                   DC      (CLK2<<8)+(3<<14)+@CVI((P1_LO+10.0)/20.0*4095) ; P1 Low
1380      Y:0036 Y:0036                   DC      (CLK2<<8)+(4<<14)+@CVI((P2_HI+10.0)/20.0*4095) ; P2 High
1381      Y:0037 Y:0037                   DC      (CLK2<<8)+(5<<14)+@CVI((P2_LO+10.0)/20.0*4095) ; P2 Low
1382      Y:0038 Y:0038                   DC      (CLK2<<8)+(6<<14)+@CVI((P3_HI+10.0)/20.0*4095) ; P3 High
1383      Y:0039 Y:0039                   DC      (CLK2<<8)+(7<<14)+@CVI((P3_LO+10.0)/20.0*4095) ; P3 Low
1384      Y:003A Y:003A                   DC      (CLK2<<8)+(8<<14)+@CVI((S1_HI+10.0)/20.0*4095) ; S1 High -- serials
1385      Y:003B Y:003B                   DC      (CLK2<<8)+(9<<14)+@CVI((S1_LO+10.0)/20.0*4095) ; S1 Low
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  DACS.asm  Page 25



1386      Y:003C Y:003C                   DC      (CLK2<<8)+(10<<14)+@CVI((S3_HI+10.0)/20.0*4095) ; S3 High
1387      Y:003D Y:003D                   DC      (CLK2<<8)+(11<<14)+@CVI((S3_LO+10.0)/20.0*4095) ; S3 Low
1388      Y:003E Y:003E                   DC      (CLK2<<8)+(12<<14)+@CVI((S2_HI+10.0)/20.0*4095) ; S2 High
1389      Y:003F Y:003F                   DC      (CLK2<<8)+(13<<14)+@CVI((S2_LO+10.0)/20.0*4095) ; S2 Low
1390      Y:0040 Y:0040                   DC      (CLK2<<8)+(14<<14)+@CVI((Q3_HI+10.0)/20.0*4095) ; Q3 High -- image
1391      Y:0041 Y:0041                   DC      (CLK2<<8)+(15<<14)+@CVI((Q3_LO+10.0)/20.0*4095) ; Q3 Low
1392      Y:0042 Y:0042                   DC      (CLK2<<8)+(16<<14)+@CVI((Q2_HI+10.0)/20.0*4095) ; Q2 High
1393      Y:0043 Y:0043                   DC      (CLK2<<8)+(17<<14)+@CVI((Q2_LO+10.0)/20.0*4095) ; Q2 Low
1394      Y:0044 Y:0044                   DC      (CLK2<<8)+(18<<14)+@CVI((Q1_HI+10.0)/20.0*4095) ; Q1 High
1395      Y:0045 Y:0045                   DC      (CLK2<<8)+(19<<14)+@CVI((Q1_LO+10.0)/20.0*4095) ; Q1 Low
1396      Y:0046 Y:0046                   DC      (CLK2<<8)+(20<<14)+@CVI((SW_HI+10.0)/20.0*4095) ; SW High
1397      Y:0047 Y:0047                   DC      (CLK2<<8)+(21<<14)+@CVI((SW_LO+10.0)/20.0*4095) ; SW Low
1398      Y:0048 Y:0048                   DC      (CLK2<<8)+(22<<14)+@CVI((TG_HI+10.0)/20.0*4095) ; TG High
1399      Y:0049 Y:0049                   DC      (CLK2<<8)+(23<<14)+@CVI((TG_LO+10.0)/20.0*4095) ; TG Low
1400   
1401                            ; Set gain and integrator speed [$board-c3-speed-gain]
1402                            ;  speed: f => fast, c => slow
1403                            ;  gain: 77, bb, dd, ee => 1x,2x,5x,10x; [ChanB+ChanA]
1404   
1405                            ; *** not used ***
1406      000C00                SPD       EQU     $c00                              ; slow video proc
1407      0000EE                GAN       EQU     $ee                               ; gain 10 video proc
1408   
1409      Y:004A Y:004A                   DC      $0c3000+SPD+GAN
1410                            ;       DC      $0c3cdd                 ; x5 Gain, slow integrate, board #0
1411   
1412                            ; Output offset voltages to get around 1000 DN A/D units on a dark frame
1413   
1414      Y:004B Y:004B                   DC      $0c4000+OFFSET0+OFFSET            ; Output video offset, Output #0
1415      Y:004C Y:004C                   DC      $0cc000+OFFSET1+OFFSET            ; Output video offset, Output #1
1416   
1417                            ; DC bias voltages
1418   
1419      Y:004D Y:004D                   DC      $0d0000+@CVI((VOD-7.5)/22.5*4095) ; Vod (7.5-30), pin #1,  VID0
1420      Y:004E Y:004E                   DC      $0d4000+@CVI((VOD-7.5)/22.5*4095) ; Vod (7.5-30), pin #2,  VID0
1421      Y:004F Y:004F                   DC      $0d8000+@CVI((VRD-5.0)/15.0*4095) ; Vrd (5-20),   pin #3,  VID0
1422      Y:0050 Y:0050                   DC      $0e0000+@CVI((B5-5.0)/15.0*4095)  ; B5  (5-20),   pin #5,  VID0
1423      Y:0051 Y:0051                   DC      $0f0000+@CVI((B7+5.0)/10.0*4095)  ; B7  (-5-+5),  pin #9,  VID0
1424      Y:0052 Y:0052                   DC      $0f8000+@CVI((VOG+10.0)/20.0*4095) ; Vog (-10-+10),pin #11, VID0
1425      Y:0053 Y:0053                   DC      $0fc000+@CVI((VOG+10.0)/20.0*4095) ; Vog (-10-+10),pin #12, VID0
1426                            EDACS
1427   
1428                            ; *** shorthand for waveforms ***
1429      020000                S_DELAY   EQU     @CVI((S_DEL2-80)/20)<<16
1430      000000                V_DELAY   EQU     @CVI((V_DEL2-80)/20)<<16
1431      9E0000                P_DELAY   EQU     (1<<23)+(@CVI((P_DEL2-80)/160)<<16)
1432      8C0000                DWELL     EQU     (1<<23)+(@CVI((DWEL-80)/160)<<16)
1433   
1434                            ; *** timing NOP ***
1435      Y:0054 Y:0054         TNOP      DC      ETNOP-TNOP-GENCNT
1436      Y:0055 Y:0055                   DC      $00E000
1437      Y:0056 Y:0056                   DC      $00E000
1438                            ETNOP
1439   
1440                            ; *** default clock states ***
1441      000040                SDEF      EQU     S1L+S2H+S3L+RGL
1442      000306                PQDEF     EQU     P1H+P2H+P3L+Q1H+Q2H+Q3L
1443                            ;PQDEF          EQU     P1L+P2H+P3L+Q1L+Q2H+Q3L
1444   
1445                            ; parallels_for with chan 0
1446                            ; parallels_rev with chan 1
1447   
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  waveforms.asm  Page 26



1448                            ; *** parallel shifting  ***
1449      Y:0057 Y:0057         PXFER     DC      EPXFER-PXFER-GENCNT
1450                                      INCLUDE "parallels_rev.asm"
1451                            ; parallels_rev
1452   
1453                            ; define default states
1454                            ; PDEF is frame or frame+image parallel clocks state during serial transfer
1455                            ; QDEF is image clocks state during serial transfer, if FT
1456   
1457   
1458      Y:0058 Y:0058                   DC      CLK2+P_DELAY+SDEF+P1H+P2L+P3H+Q1H+Q2L+Q3H
1459      Y:0059 Y:0059                   DC      CLK2+P_DELAY+SDEF+P1L+P2L+P3H+Q1L+Q2L+Q3H
1460      Y:005A Y:005A                   DC      CLK2+P_DELAY+SDEF+P1L+P2H+P3H+Q1L+Q2H+Q3H
1461      Y:005B Y:005B                   DC      CLK2+P_DELAY+SDEF+P1L+P2H+P3L+Q1L+Q2H+Q3L
1462      Y:005C Y:005C                   DC      CLK2+P_DELAY+SDEF+P1H+P2H+P3L+Q1H+Q2H+Q3L
1463      Y:005D Y:005D                   DC      CLK2+P_DELAY+SDEF+P1H+P2L+P3L+Q1H+Q2L+Q3L
1464   
1465                            ;       INCLUDE "parallels_for.asm"
1466                            EPXFER
1467   
1468      000057                PQXFER    EQU     PXFER
1469      000057                RXFER     EQU     PXFER
1470   
1471                            ; *** serial shifting ***
1472                                      INCLUDE "s_2_321w.asm"
1473                            ;s_2_321w
1474   
1475      022306                PARS      EQU     CLK2+PQDEF+S_DELAY
1476      000000                VIDS      EQU     VIDEO+V_DELAY
1477   
1478                            ; setup for fast flush
1479      Y:005E Y:005E         FPXFER0   DC      EFPXFER0-FPXFER0-GENCNT
1480      Y:005F Y:005F                   DC      PARS+RGH+S1H+S2H+S3H+SWH
1481      Y:0060 Y:0060                   DC      PARS+RGH+S1H+S2H+S3H+SWH
1482                            EFPXFER0
1483   
1484                            ; end fast flush
1485      Y:0061 Y:0061         FPXFER2   DC      EFPXFER2-FPXFER2-GENCNT
1486      Y:0062 Y:0062                   DC      PARS+RGL+S1L+S2H+S3L+SWL
1487      Y:0063 Y:0063                   DC      PARS+RGL+S1L+S2H+S3L+SWL
1488                            EFPXFER2
1489   
1490                            ; fast serial shift
1491      Y:0064 Y:0064         FSXFER    DC      EFSXFER-FSXFER-GENCNT
1492      Y:0065 Y:0065                   DC      PARS+RGL+S1H+S2H+S3L+SWL
1493      Y:0066 Y:0066                   DC      PARS+RGL+S1H+S2L+S3L+SWL
1494      Y:0067 Y:0067                   DC      PARS+RGL+S1H+S2L+S3H+SWH
1495      Y:0068 Y:0068                   DC      PARS+RGL+S1L+S2L+S3H+SWH
1496      Y:0069 Y:0069                   DC      PARS+RGL+S1L+S2H+S3H+SWH
1497      Y:006A Y:006A                   DC      PARS+RGH+S1L+S2H+S3L+SWL
1498                            EFSXFER
1499   
1500      Y:006B Y:006B         SXFER0    DC      ESXFER0-SXFER0-GENCNT
1501      Y:006C Y:006C                   DC      PARS+RGH+S1L+S2H+S3L+SWL
1502      Y:006D Y:006D                   DC      PARS+RGL+S1L+S2H+S3L+SWL
1503      Y:006E Y:006E                   DC      VIDS+%1110100
1504      Y:006F Y:006F                   DC      PARS+RGL+S1H+S2H+S3L+SWL
1505      Y:0070 Y:0070                   DC      PARS+RGL+S1H+S2L+S3L+SWL
1506      Y:0071 Y:0071                   DC      PARS+RGL+S1H+S2L+S3H+SWH
1507      Y:0072 Y:0072                   DC      PARS+RGL+S1L+S2L+S3H+SWH
1508      Y:0073 Y:0073                   DC      PARS+RGL+S1L+S2H+S3H+SWH
1509      Y:0074 Y:0074                   DC      PARS+RGL+S1L+S2H+S3L+SWH
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  s_2_321w.asm  Page 27



1510                            ESXFER0
1511   
1512      Y:0075 Y:0075         SXFER1    DC      ESXFER1-SXFER1-GENCNT
1513      Y:0076 Y:0076                   DC      PARS+RGL+S1H+S2H+S3L+SWH
1514      Y:0077 Y:0077                   DC      PARS+RGL+S1H+S2L+S3L+SWH
1515      Y:0078 Y:0078                   DC      PARS+RGL+S1H+S2L+S3H+SWH
1516      Y:0079 Y:0079                   DC      PARS+RGL+S1L+S2L+S3H+SWH
1517      Y:007A Y:007A                   DC      PARS+RGL+S1L+S2H+S3H+SWH
1518      Y:007B Y:007B                   DC      PARS+RGL+S1L+S2H+S3L+SWH
1519                            ESXFER1
1520   
1521      Y:007C Y:007C         SXFER2    DC      ESXFER2-SXFER2-GENCNT
1522                                      INCLUDE "int_noise.asm"
1523                            ; CDS integrate on noise
1524      Y:007D Y:007D                   DC      VIDS+%1110111                     ; Stop resetting integrator
1525      Y:007E Y:007E                   DC      VIDS+%1110111                     ; Delay for Pgnal to settle
1526      Y:007F Y:007F                   DC      VIDEO+DWELL+%0000111              ; Integrate noise
1527      Y:0080 Y:0080                   DC      VIDS+%0011011                     ; Stop Integrate, switch POL
1528      Y:0081 Y:0081                   DC      PARS+RGL+S1L+S2H+S3L+SWL
1529                                      INCLUDE "int_signal.asm"
1530                            ; CDS integrate on signal
1531      Y:0082 Y:0082                   DC      VIDS+%0011011                     ; Delay for Pgnal to settle
1532      Y:0083 Y:0083                   DC      VIDEO+DWELL+%0001011              ; Integrate signal
1533      Y:0084 Y:0084                   DC      VIDS+%0011011                     ; Stop integrate, clamp, reset, A/D is sampling
1534                            ESXFER2
1535   
1536      Y:0085 Y:0085         SXFER2D   DC      ESXFER2D-SXFER2D-GENCNT
1537      Y:0086 Y:0086                   DC      SXMIT                             ; Transmit A/D data to host
1538                                      INCLUDE "int_noise.asm"
1539                            ; CDS integrate on noise
1540      Y:0087 Y:0087                   DC      VIDS+%1110111                     ; Stop resetting integrator
1541      Y:0088 Y:0088                   DC      VIDS+%1110111                     ; Delay for Pgnal to settle
1542      Y:0089 Y:0089                   DC      VIDEO+DWELL+%0000111              ; Integrate noise
1543      Y:008A Y:008A                   DC      VIDS+%0011011                     ; Stop Integrate, switch POL
1544      Y:008B Y:008B                   DC      PARS+RGL+S1L+S2H+S3L+SWL
1545                                      INCLUDE "int_signal.asm"
1546                            ; CDS integrate on signal
1547      Y:008C Y:008C                   DC      VIDS+%0011011                     ; Delay for Pgnal to settle
1548      Y:008D Y:008D                   DC      VIDEO+DWELL+%0001011              ; Integrate signal
1549      Y:008E Y:008E                   DC      VIDS+%0011011                     ; Stop integrate, clamp, reset, A/D is sampling
1550                            ESXFER2D
1551   
1552                            ; ******** END OF WAVEFORM.ASM **********
1553   
1554                               ENDSEC                                    ; End of section TIM
1555   
1556                     ;  End of program
1557                               END

0    Errors
0    Warnings


