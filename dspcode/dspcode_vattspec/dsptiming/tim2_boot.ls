Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_boot.asm  Page 1



1                        ; This file is used to generate DSP boot code for the second generation
2                        ;  TimII timing board, Rev. 4B.  It is V1.7 code.
3      
4                                  PAGE    132                               ; Printronix page width - 132 columns
5      
6                        ; Include a header file that defines global parameters
7                                  INCLUDE "tim2_hdr.asm"
8                        ; timhdr.asm for Gen2
9      
10                               COMMENT *
11     
12                       This is a header file that is shared between the fiber optic timing board
13                       boot and application code files
14     
15                       20Aug04 last change MPL
16                               *
17     
18                                 PAGE    132                               ; Printronix page width - 132 columns
19     
20                       ; Some basic structural definitions
21        000130         APL_ADR   EQU     $130                              ; P: memory location where application code begins
22        0000D0         APL_LEN   EQU     $200-APL_ADR                      ; Maximum length of application program
23        000280         MISC_LEN  EQU     $280                              ; Maximum length of "miscellanous" code
24        000040         COM_LEN   EQU     $40                               ; Length of memory for application commands
25        00003C         TIM_ISR   EQU     $3C                               ; DSP timer interrupt service routine address
26        00003E         PGM_CON   EQU     $3E                               ; Program continues on here
27        000080         COM_TBL   EQU     $80                               ; Starting address of command table in X: memory
28        000500         N_W_APL   EQU     $500                              ; Number of words in each application
29        000028         NUM_COM   EQU     40                                ; Number of entries in command table
30     
31        000000         RST_ISR   EQU     $00                               ; Hardware reset interrupt
32        000006         ROM_ID    EQU     $06                               ; Location of program Identification = SWI interrupt
33        000008         START     EQU     $08                               ; Starting address of program
34        000060         RCV_BUF   EQU     $60                               ; Starting address of receiver buffer in X:
35        00000F         TBL_ADR   EQU     $0F                               ; (IR) Waveform tables starting address
36     
37        004000         ROM_OFF   EQU     $4000                             ; Boot program offset address in EEPROM
38        004200         LD_X      EQU     $4200                             ; Assembler loads X: starting at this EEPROM address
39        00C600         RD_X      EQU     $C600                             ; DSP reads X: from this EEPROM address
40     
41                       ; Define DSP port addresses
42        00FF80         WRSS      EQU     $FF80                             ; Write clock driver and VP switch states
43        00FFC0         RDFO      EQU     $FFC0                             ; Read serial receiver fiber optic contents
44        00FFC0         WRFO      EQU     $FFC0                             ; Write to fiber optic serial transmitter
45        00FFA0         RDAD      EQU     $FFA0                             ; Read A/D datum into DSP
46        00FFA0         RDAD0     EQU     $FFA0                             ; Address for reading A/D #0
47        00FFA1         RDAD1     EQU     $FFA1                             ; Address for reading A/D #1
48        00FFC1         WRLATCH   EQU     $FFC1                             ; Write to timing board latch
49        006000         RSTWDT    EQU     $6000                             ; Address to reset the timing board watchdog timer
50        00FFFE         BCR       EQU     $FFFE                             ; Bus (=Port A) Control Register -> Wait States
51        00FFE0         PBC       EQU     $FFE0                             ; Port B Control Register
52        00FFE2         PBDDR     EQU     $FFE2                             ; Port B Data Direction Register
53        00FFE4         PBD       EQU     $FFE4                             ; Port B Data Register
54        00FFE1         PCC       EQU     $FFE1                             ; Port C Control Register
55        00FFE3         PCDDR     EQU     $FFE3                             ; PortC Data Direction Register
56        00FFE5         PCD       EQU     $FFE5                             ; Port C Data Register
57        00FFFF         IPR       EQU     $FFFF                             ; Interrupt Priority Register
58        00FFEF         SSITX     EQU     $FFEF                             ; SSI Transmit and Receive data register
59        00FFEF         SSIRX     EQU     $FFEF                             ; SSI Transmit and Receive data register
60        00FFEE         SSISR     EQU     $FFEE                             ; SSI Status Register
61        00FFEC         CRA       EQU     $FFEC                             ; SSI Control Register A
62        00FFED         CRB       EQU     $FFED                             ; SSI Control Regsiter B
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_hdr.asm  Page 2



63        00FFDE         TCSR      EQU     $FFDE                             ; Timer control and status register
64        00FFDF         TCR       EQU     $FFDF                             ; Timer count register
65     
66                       ; Hardware bit definitions all over the place
67        000006         SSI_TDE   EQU     6                                 ; SSI Transmitter data register empty
68        000007         SSI_RDF   EQU     7                                 ; SSI Receiver data register full
69        000002         LVEN      EQU     2                                 ; Low voltage enable (+/-15 volt nominal)
70        000003         HVEN      EQU     3                                 ; Enable high voltage (+32V nominal)
71        000005         TIM_U_RST EQU     5                                 ; Timing to utility board reset bit number in U25
72        00000D         PWRST     EQU     13                                ; Power control board reset
73        000007         RST_FIFO  EQU     7                                 ; Reset FIFO bit number in control latch U25
74        000009         EF        EQU     9                                 ; FIFO empty flag, low true
75        000000         TIM_BIT   EQU     0                                 ; Timer status bit
76        000001         WW        EQU     1                                 ; Word width = 1 for 16-bit image data, 0 for 24-bit
77        000000         CDAC      EQU     0                                 ; Bit number in U25 for clearing DACs
78        000002         ENCK      EQU     2                                 ; Bit number in U25 for enabling analog switches
79        000001         DUALCLK   EQU     1                                 ; Set to clock two halves of clock driver board togethe
r
80     
81                       ; Software status bits, defined at X:<STATUS = X:0
82        000000         ST_RCV    EQU     0                                 ; Set if FO, cleared if SSI
83        000002         IDLMODE   EQU     2                                 ; Set if need to idle after readout
84        000003         ST_SHUT   EQU     3                                 ; Set to indicate shutter is closed, clear for open
85        000004         ST_RDC    EQU     4                                 ; Set if executing 'RDC' command - reading out
86        000005         SPLIT_S   EQU     5                                 ; Set if split serial
87        000006         SPLIT_P   EQU     6                                 ; Set if split parallel
88        000007         MPP       EQU     7                                 ; Set if parallels are in MPP mode
89        00000A         TST_IMG   EQU     10                                ; Set if controller is to generate a test image
90        00000B         SHUT      EQU     11                                ; Set if opening shutter at beginning of exposure
91        00000D         NOREAD    EQU     13                                ; Set if not to readout after exposure
92     
93                       ; Specify controller configuration bits of the X:STATUS word
94                       ;  to describe the software capabilities of this application file
95                       ; The bit is set (=1) if the capability is supported by the controller
96     
97                               COMMENT *
98     
99                       BIT #'s         FUNCTION
100                      2,1,0           Video Processor
101                                              000     CCD Rev. 3
102                                              001     CCD Gen I
103                                              010     IR Rev. 4
104                                              011     IR Coadder
105    
106                      4,3             Timing Board
107                                              00      Rev. 4, Gen II
108                                              01      Gen I
109    
110                      6,5             Utility Board
111                                              00      No utility board
112                                              01      Utility Rev. 3
113    
114                      7               Shutter
115                                              0       No shutter support
116                                              1       Yes shutter support
117    
118                      9,8             Temperature readout
119                                              00      No temperature readout
120                                              01      Polynomial Diode calibration
121                                              10      Linear temperature sensor calibration
122    
123                      10              Subarray readout
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_hdr.asm  Page 3



124                                              0       Not supported
125                                              1       Yes supported
126    
127                      11              Binning
128                                              0       Not supported
129                                              1       Yes supported
130    
131                      12              Split-Serial readout
132                                              0       Not supported
133                                              1       Yes supported
134    
135                      13              Split-Parallel readout
136                                              0       Not supported
137                                              1       Yes supported
138    
139                      14              MPP = Inverted parallel clocks
140                                              0       Not supported
141                                              1       Yes supported
142    
143                      16,15           Clock Driver Board
144                                              00      Rev. 3
145                                              11      No clock driver board (Gen I)
146    
147                      19,18,17                Special implementations
148                                              000     Somewhere else
149                                              001     Mount Laguna Observatory
150                                              010     NGST Aladdin
151                                              xxx     Other
152                              *
153    
154                      CCDVIDREV3B
155       000000                   EQU     $000000                           ; CCD Video Processor Rev. 3
156       000001         VIDGENI   EQU     $000001                           ; CCD Video Processor Gen I
157       000002         IRREV4    EQU     $000002                           ; IR Video Processor Rev. 4
158       000003         COADDER   EQU     $000003                           ; IR Coadder
159       000000         TIMREV4   EQU     $000000                           ; Timing Rev. 4
160       000008         TIMGENI   EQU     $000008                           ; Timing Gen I
161       000020         UTILREV3  EQU     $000020                           ; Utility Rev. 3 supported
162       000080         SHUTTER_CC EQU    $000080                           ; Shutter supported
163       000100         TEMP_POLY EQU     $000100                           ; Polynomial calibration
164                      TEMP_LINEAR
165       000200                   EQU     $000200                           ; Linear calibration
166       000400         SUBARRAY  EQU     $000400                           ; Subarray readout supported
167       000800         BINNING   EQU     $000800                           ; Binning supported
168                      SPLIT_SERIAL
169       001000                   EQU     $001000                           ; Split serial supported
170                      SPLIT_PARALLEL
171       002000                   EQU     $002000                           ; Split parallel supported
172       004000         MPP_CC    EQU     $004000                           ; Inverted clocks supported
173       018000         CLKDRVGENI EQU    $018000                           ; No clock driver board - Gen I
174       020000         MLO       EQU     $020000                           ; Set if Mount Laguna Observatory
175       040000         NGST      EQU     $040000                           ; NGST Aladdin implementation
176    
177                      ; After RESET jump to the initialization code
178       P:0000 P:4000                   ORG     P:RST_ISR,P:RST_ISR+ROM_OFF
179       P:0000 P:4000 0C0130            JMP     <INIT                             ; Initialize DSP after hardware reset
180       P:0001 P:4001 000000            NOP
181    
182                             ; DSP Timer interrupt for exposure time control
183       P:003C P:403C                   ORG     P:TIM_ISR,P:TIM_ISR+ROM_OFF
184       P:003C P:403C 0D00B4            JSR     <TIMER                            ; Long interrupt service routine
185       P:003D P:403D 000000            NOP
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_boot.asm  Page 4



186    
187                             ; Put some words identifying this version of the ROM code. It is placed at
188                             ;   the address of the SWI = software interrupt, which is never used.
189       P:0006 P:4006                   ORG     P:ROM_ID,P:ROM_ID+ROM_OFF
190       P:0006 P:4006                   DC      $000000                           ; Institution
191                                                                                 ; Location
192                                                                                 ; Instrument
193       P:0007 P:4007                   DC      $030002                           ; Version 3.00, board #2 = timing
194    
195                             ;**************************************************************************
196                             ;                                                                         *
197                             ;    Permanent address register assignments                               *
198                             ;        R3 - Pointer to commands received pending processing             *
199                             ;        R4 - Pointer to processed commands                                 *
200                             ;        R6 - CCD clock driver address for CCD #0                         *
201                             ;                It is also the A/D address of analog board #0            *
202                             ;                                                                         *
203                             ;    Other registers                                                                  *
204                             ;        R1, R2, R5 - Not used very much                                              *
205                             ;        R0, R7 - Temporary registers used all over the place             *
206                             ;**************************************************************************
207    
208                             ; Initialization code is in the application area since it executes only once
209       P:0130 P:4130                   ORG     P:APL_ADR,P:APL_ADR+ROM_OFF       ; Download address
210    
211                             ; Initialization of the DSP - system register, serial link, interrupts.
212                             ;    This is executed once on DSP boot from ROM, and is not incorporated
213                             ;    into any download code since its not needed.
214    
215       P:0130 P:4130 0502BA  INIT      MOVEC             #$0002,OMR              ; Operating Mode Register = Normal
216                                                                                 ;   Expanded - set after reset by hardware
217    
218       P:0131 P:4131 0003F8            ORI     #$03,MR                           ; Mask interrupts
219    
220       P:0132 P:4132 08F4A0            MOVEP             #0,X:PBC                ; Port B Control Register to Parallel I/O
                        000000
221    
222       P:0134 P:4134 08F4A4            MOVEP             #$050D,X:PBD            ; Port B Data Register
                        00050D
223                                                                                 ;   H0=0 -> utility board SSI, WW=0 -> 24-bit
224                                                                                 ;   STATUS 0 to 3 = 0, AUX1=1, FD15 = 0,
225                                                                                 ;   LVEN = HVEN = 1, PWRST = 0
226    
227       P:0136 P:4136 08F4A2            MOVEP             #$15FF,X:PBDDR          ; Port B Data Direction Register
                        0015FF
228                                                                                 ;   Set signals listed in PBD above to outputs
229                                                                                 ;   and SYNC to an input
230    
231       P:0138 P:4138 08F4AC            MOVEP             #$6002,X:CRA            ; SSI programming - no prescaling;
                        006002
232                                                                                 ;   24 bits/word; on-demand communications;
233                                                                                 ;   no prescale; 4.17 MHz serial clock rate
234    
235       P:013A P:413A 08F4AD            MOVEP             #$3D30,X:CRB            ; SSI programming - OF0, OF1 don't apply;
                        003D30
236                                                                                 ;   SC0, SC1, SC2 are inputs; SCK is output;
237                                                                                 ;   shift MSB first; rcv and xmt asynchronous
238                                                                                 ;   wrt each other; gated clock; bit frame
239                                                                                 ;   sync; network mode to get on-demand;
240                                                                                 ;   RCV and TX enabled, RCV and TX interrrupts
241                                                                                 ;   disabled -> Utility board SSI
242    
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_boot.asm  Page 5



243       P:013C P:413C 08F4A1            MOVEP             #$01E8,X:PCC            ; Port C Control Register
                        0001E8
244    
245       P:013E P:413E 08F4A5            MOVEP             #$0007,X:PCD            ; Port C Data Register
                        000007
246    
247       P:0140 P:4140 08F4A3            MOVEP             #$0007,X:PCDDR          ; Port C Data Direction Register
                        000007
248                                                                                 ;   Set signals listed in PCD above to outputs
249    
250       P:0142 P:4142 08F49E            MOVEP             #>2,X:TCSR              ; Enable timer interrupts
                        000002
251    
252       P:0144 P:4144 08F49F            MOVEP             #$61A8,X:TCR            ; Divide so timer interrupts every millisecond
                        0061A8
253    
254                             ; Clear all video processor analog switches to lower their power dissipation
255       P:0146 P:4146 0AA420            BSET    #0,X:PBD                          ; Set H0 for analog boards SSI
256       P:0147 P:4147 08F4A1            MOVEP             #$0000,X:PCC            ; Software reset of SSI
                        000000
257       P:0149 P:4149 0AAD0A            BCLR    #10,X:CRB                         ; Change SSI to continuous clock for analog
258       P:014A P:414A 08F4A1            MOVEP             #$0160,X:PCC            ; Re-enable the SSI
                        000160
259       P:014C P:414C 06F481            DO      #500,*+3                          ; Wait 8 usec for serial data transmission
                        00014E
260       P:014E P:414E 000000            NOP
261    
262       P:014F P:414F 56F400            MOVE              #$0C3000,A
                        0C3000
263       P:0151 P:4151 20001B            CLR     B
264       P:0152 P:4152 241000            MOVE              #$100000,X0
265       P:0153 P:4153 45F400            MOVE              #$001000,X1
                        001000
266       P:0155 P:4155 060F80            DO      #15,L_VIDEO                       ; Fifteen video processor boards maximum
                        00015F
267       P:0157 P:4157 08CE2F            MOVEP             A,X:SSITX               ; Gain, integrate speed
268       P:0158 P:4158 200040            ADD     X0,A
269       P:0159 P:4159 577000            MOVE              B,X:WRSS
                        00FF80
270       P:015B P:415B 200068            ADD     X1,B
271       P:015C P:415C 06F481            DO      #500,*+3                          ; Wait 8 usec for serial data transmission
                        00015E
272       P:015E P:415E 000000            NOP
273       P:015F P:415F 000000            NOP
274                             L_VIDEO
275    
276                             ; Initialize the synchronous serial port
277       P:0160 P:4160 08F4A1            MOVEP             #$0000,X:PCC            ; Software reset of SSI
                        000000
278       P:0162 P:4162 0AAD2A            BSET    #10,X:CRB                         ; Change SSI to gated clock for utility board
279       P:0163 P:4163 08F4A1            MOVEP             #$0160,X:PCC            ; Enable the SSI
                        000160
280       P:0165 P:4165 0AA400            BCLR    #0,X:PBD                          ; Clear H0 for utility board SSI
281    
282                             ; Initialize X: data DSP memory
283       P:0166 P:4166 60F400            MOVE              #RD_X,R0                ; Starting X: address in EEPROM
                        00C600
284       P:0168 P:4168 310000            MOVE              #0,R1                   ; Put values starting at beginning of X:
285       P:0169 P:4169 060081            DO      #$100,X_MOVE                      ; Assume 256 = $100 values exist
                        000171
286       P:016B P:416B 060380            DO      #3,X_LOOP                         ; Reconstruct bytes to 24-bit words
                        000170
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_boot.asm  Page 6



287       P:016D P:416D 07D88A            MOVE              P:(R0)+,A2              ; Get one byte from EEPROM
288       P:016E P:416E 0608A0            REP     #8
289       P:016F P:416F 200022            ASR     A                                 ; Shift right 8 bits
290       P:0170 P:4170 000000            NOP                                       ; DO loop restriction
291                             X_LOOP
292       P:0171 P:4171 545900            MOVE              A1,X:(R1)+              ; Write 24-bit words to X: memory
293                             X_MOVE
294    
295                             ; Reset the utility board to force it to re-boot
296       P:0172 P:4172 0A0905            BCLR    #TIM_U_RST,X:<LATCH
297       P:0173 P:4173 09F081            MOVEP             X:LATCH,Y:WRLATCH       ; Clear reset utility board bit
                        000009
298       P:0175 P:4175 06C8A0            REP     #200                              ; Delay by RESET* low time
299       P:0176 P:4176 000000            NOP
300       P:0177 P:4177 0A0925            BSET    #TIM_U_RST,X:<LATCH
301       P:0178 P:4178 09F081            MOVEP             X:LATCH,Y:WRLATCH       ; Clear reset utility board bit
                        000009
302       P:017A P:417A 56F400            MOVE              #10000,A                ; Delay for utility boot < 1 msec
                        002710
303       P:017C P:417C 06CE00            DO      A,*+3
                        00017E
304       P:017E P:417E 000000            NOP
305    
306                             ; Initialize the permanent registers
307       P:017F P:417F 336000            MOVE              #<RCV_BUF,R3            ; Starting address of command buffer
308       P:0180 P:4180 66F400            MOVE              #WRSS,R6                ; Address of clock and video processor switches
                        00FF80
309       P:0182 P:4182 301000            MOVE              #<TST_RCV,R0            ; Execution address when idle => when not
310       P:0183 P:4183 600C00            MOVE              R0,X:<IDL_ADR           ;   processing commands or reading out
311       P:0184 P:4184 227413            CLR     A         R3,R4
312       P:0185 P:4185 051FA3            MOVE              #31,M3                  ; Buffers are circular, modulo 32
313       P:0186 P:4186 0464A3            MOVE              M3,M4
314       P:0187 P:4187 062080            DO      #32,ZERO_X                        ; Zero receiver buffer
                        000189
315       P:0189 P:4189 565B00            MOVE              A,X:(R3)+
316                             ZERO_X
317    
318                             ; Reset the input command FIFO
319       P:018A P:418A 0A0907            BCLR    #RST_FIFO,X:<LATCH
320       P:018B P:418B 09F081            MOVEP             X:LATCH,Y:WRLATCH
                        000009
321       P:018D P:418D 0A0927            BSET    #RST_FIFO,X:<LATCH
322       P:018E P:418E 09F081            MOVEP             X:LATCH,Y:WRLATCH
                        000009
323    
324                             ; Set the interrupt priority level for the DSP timer
325       P:0190 P:4190 08F4BF            MOVEP             #$030000,X:IPR          ; Exposure timer priority = 2
                        030000
326       P:0192 P:4192 00FCB8            ANDI    #$FC,MR                           ; Unmask all interrupt levels
327    
328                             ; Specify the external memory space wait states
329       P:0193 P:4193 08F4BE            MOVEP             #$0111,X:BCR            ; Wait states = X: Y: P: and Y: ext. I/O
                        000111
330    
331                             ; Reply to the host computer that the system re-booted
332       P:0195 P:4195 56F400            MOVE              #$020002,A
                        020002
333       P:0197 P:4197 565B00            MOVE              A,X:(R3)+
334       P:0198 P:4198 56F400            MOVE              #'SYR',A
                        535952
335       P:019A P:419A 565B00            MOVE              A,X:(R3)+
336    
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_boot.asm  Page 7



337                             ; Go execute the program - initialization is over
338       P:019B P:419B 0C002B            JMP     <PRC_RCV                          ; Go look for incoming commands
339    
340                             ; Check for program space overflow
341                                       IF      @CVS(N,*)>$1FF
343                                       ENDIF
344    
345                             ;  ****************  Beginning of command execution code  ******************
346    
347                             ; Start the code in the interrupt vector area that is not used
348       P:0008 P:4008                   ORG     P:START,P:START+ROM_OFF           ; Program start at P:$18
349    
350                             ; Return here after executing each command
351       P:0008 P:4008 336000            MOVE              #<RCV_BUF,R3
352       P:0009 P:4009 227400            MOVE              R3,R4
353       P:000A P:400A 608C00            MOVE              X:<IDL_ADR,R0
354       P:000B P:400B 0A7020            BSET    #ST_RCV,X:STATUS                  ; Assume its NOT an SSI word
                        000000
355       P:000D P:400D 0A9EA0            JSET    #TIM_BIT,X:TCSR,CHK_TIM           ; If exposing go check timer
                        0000B1
356       P:000F P:400F 0AE080            JMP     (R0)
357    
358       P:0010 P:4010 0D005D  TST_RCV   JSR     <GET_RCV                          ; Look for pending serial words
359       P:0011 P:4011 0E0010            JCC     <TST_RCV                          ; If none, then keep checking
360    
361                             ; First check for requests for service from the utility board
362       P:0012 P:4012 0A00A0  CHK_SSI   JSET    #ST_RCV,X:<STATUS,HEADER          ; Only check if its a FIFO word
                        000018
363       P:0014 P:4014 46FB00            MOVE              X:-(R3),Y0              ; Get candidate header
364       P:0015 P:4015 56A000            MOVE              X:<UTL_REQ,A            ; Is it the utility board requesting service?
365       P:0016 P:4016 200055            CMP     Y0,A
366       P:0017 P:4017 0EA088            JEQ     <GET_UTL                          ; Yes, go get the rest of utility board words
367    
368                             ; Check the header (S,D,N) for self-consistency
369       P:0018 P:4018 44FB00  HEADER    MOVE              X:-(R3),X0              ; Get candidate header
370       P:0019 P:4019 0D0090            JSR     <CHK_HDR                          ; Go check it; A1 = NWORDS
371       P:001A P:401A 440A00            MOVE              X0,X:<HDR               ; Save the header
372       P:001B P:401B 0E8008            JCS     <START                            ; Error if carry bit is set - discard header
373    
374                             ; Read all the words of the command before processing the command
375       P:001C P:401C 228400            MOVE              R4,X0                   ; Header address = RCV_BUF
376       P:001D P:401D 205B40            ADD     X0,A      (R3)+                   ; R3 must reach this for command to be complete
377       P:001E P:401E 21C500            MOVE              A,X1                    ; X1 = header address + NWORDS
378    
379                             ; Implement a timeout
380       P:001F P:401F 062200            DO      X:<TIM_COM,TIME_OUT
                        000028
381       P:0021 P:4021 0D005D            JSR     <GET_RCV
382       P:0022 P:4022 0E0028            JCC     <NOT_YET
383       P:0023 P:4023 226E00            MOVE              R3,A                    ; Get address of last word written to buffer
384       P:0024 P:4024 200065            CMP     X1,A                              ; Has it been incremented to RCV_BUF + NWORDS?
385       P:0025 P:4025 0E9028            JLT     <NOT_YET                          ; No, keep looking for more
386       P:0026 P:4026 00008C            ENDDO
387       P:0027 P:4027 0C002B            JMP     <PRC_RCV                          ; Go process the entire command normally
388       P:0028 P:4028 000000  NOT_YET   NOP
389                             TIME_OUT
390       P:0029 P:4029 0D009B            JSR     <CHK_ERR                          ; Reset either the FIFO or the SSI
391       P:002A P:402A 0C0008            JMP     <START                            ; Start over
392    
393                             ; Process the receiver entry - is its destination number = D_BRD?
394       P:002B P:402B 226E00  PRC_RCV   MOVE              R3,A                    ; Pointer to current contents of receiver
395       P:002C P:402C 228400            MOVE              R4,X0                   ; Pointer to processed contents
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_boot.asm  Page 8



396       P:002D P:402D 44E445            CMP     X0,A      X:(R4),X0               ; Are they equal? Get header for later
397       P:002E P:402E 0EA008            JEQ     <START                            ; If unequal, process command
398       P:002F P:402F 2C0700            MOVE              #7,A1
399       P:0030 P:4030 559B46            AND     X0,A      X:<DMASK,B1             ; Extract NWORDS
400       P:0031 P:4031 459A4E            AND     X0,B      X:<DBRD,X1              ; Extract destination byte
401       P:0032 P:4032 540B6D            CMP     X1,B      A1,X:<NWORDS            ; Does header = destination number?
402       P:0033 P:4033 0EA045            JEQ     <COMMAND                          ; Yes, process it as a command
403       P:0034 P:4034 0E903E            JLT     <FO_XMT                           ; Send to fiber optic transmitter?
404       P:0035 P:4035 0C0036            JMP     <XMT_UTL
405    
406                             ; Transmit words to the utility board over the SSI
407       P:0036 P:4036 060B00  XMT_UTL   DO      X:<NWORDS,DON_XMT                 ; Transmit NWORDS
                        00003A
408       P:0038 P:4038 0AAE86            JCLR    #SSI_TDE,X:SSISR,*                ; Continue if SSI XMT register is empty
                        000038
409       P:003A P:403A 08DCAF            MOVEP             X:(R4)+,X:SSITX         ; Write to SSI buffer
410                             DON_XMT
411       P:003B P:403B 0C002B            JMP     <PRC_RCV                          ; Check command continuation
412    
413                             ; Check for program space overwriting of timer ISR
414                                       IF      @CVS(N,*)>$3C
416                                       ENDIF
417    
418       P:003E P:403E                   ORG     P:PGM_CON,P:PGM_CON+ROM_OFF       ; Step over timer ISR
419    
420                             ; Transmit words to the host computer over the fiber optics link
421       P:003E P:403E 060B00  FO_XMT    DO      X:<NWORDS,DON_FFO                 ; Transmit all the words in the command
                        000043
422       P:0040 P:4040 062880            DO      #40,DLY_FFO                       ; Delay for the serial transmitter
                        000042
423       P:0042 P:4042 000000            NOP
424                             DLY_FFO
425       P:0043 P:4043 09DC80            MOVEP             X:(R4)+,Y:WRFO          ; Send each word to the fo transmitter
426                             DON_FFO
427       P:0044 P:4044 0C002B            JMP     <PRC_RCV
428    
429                             ; Process the receiver entry - is it in the command table ?
430       P:0045 P:4045 205C00  COMMAND   MOVE              (R4)+                   ; Increment over the header
431       P:0046 P:4046 56DC00            MOVE              X:(R4)+,A               ; Get the command buffer entry
432       P:0047 P:4047 308000            MOVE              #<COM_TBL,R0            ; Get command table starting address
433       P:0048 P:4048 062880            DO      #NUM_COM,END_COM                  ; Loop over the command table
                        00004F
434       P:004A P:404A 45D800            MOVE              X:(R0)+,X1              ; Get the command table entry
435       P:004B P:404B 65E065            CMP     X1,A      X:(R0),R5               ; Does receiver = table entries address?
436       P:004C P:404C 0E204F            JNE     <NOT_COM                          ; No, keep looping
437       P:004D P:404D 00008C            ENDDO                                     ; Restore the DO loop system registers
438       P:004E P:404E 0AE580            JMP     (R5)                              ; Jump execution to the command
439       P:004F P:404F 205800  NOT_COM   MOVE              (R0)+                   ; Increment the register past the table address
440                             END_COM
441    
442                             ; It's not in the command table - send an error message
443       P:0050 P:4050 449D00  ERROR     MOVE              X:<ERR,X0               ; Send the message - there was an error
444       P:0051 P:4051 0C0053            JMP     <FINISH1                          ; This protects against unknown commands
445    
446                             ; Send a reply packet - header and reply
447       P:0052 P:4052 449E00  FINISH    MOVE              X:<DON,X0               ; Send a DONE message as a reply
448       P:0053 P:4053 568A00  FINISH1   MOVE              X:<HDR,A                ; Get header of incoming command
449       P:0054 P:4054 469C00            MOVE              X:<SMASK,Y0             ; This was the source byte, and is to
450       P:0055 P:4055 468F56            AND     Y0,A      X:<TWO,Y0               ;    become the destination byte
451       P:0056 P:4056 0608A0            REP     #8                                ; Shift right one byte, add it to the
452       P:0057 P:4057 460B23            LSR     A         Y0,X:<NWORDS            ;     header, and put 2 as the number
453       P:0058 P:4058 469950            ADD     Y0,A      X:<SBRD,Y0              ;    of words in the string
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_boot.asm  Page 9



454       P:0059 P:4059 200050            ADD     Y0,A                              ; Add source board's header, set X1 for above
455       P:005A P:405A 565B00            MOVE              A,X:(R3)+               ; Put header on the transmitter stack
456       P:005B P:405B 445B00            MOVE              X0,X:(R3)+              ; Put value of XO on the transmitter stack
457       P:005C P:405C 0C002B            JMP     <PRC_RCV                          ; Go transmit these words
458    
459                             ; Read the FIFO data one byte at a time and construct a 3-byte word
460       P:005D P:405D 0A0080  GET_RCV   JCLR    #ST_RCV,X:<STATUS,GET_SSI
                        000080
461       P:005F P:405F 0AA489            JCLR    #EF,X:PBD,GET_SSI
                        000080
462       P:0061 P:4061 0AA489            JCLR    #EF,X:PBD,GET_SSI                 ; Protection against metastability
                        000080
463       P:0063 P:4063 200013            CLR     A
464       P:0064 P:4064 21C700            MOVE              A,Y1
465       P:0065 P:4065 509200            MOVE              X:<EIGHT,A0
466       P:0066 P:4066 210600            MOVE              A0,Y0
467       P:0067 P:4067 060380            DO      #3,L_WORD                         ; Process three bytes per word
                        00007C
468       P:0069 P:4069 20001B            CLR     B
469    
470                             ; Because of FIFO metastability require that EF be stable for two tests
471       P:006A P:406A 0AA489  TST1      JCLR    #EF,X:PBD,TST2                    ; EF = Low,  Low  => END_DO
                        00006D
472       P:006C P:406C 0C0070            JMP     <TST3                             ;      High, Low  => try again
473       P:006D P:406D 0AA489  TST2      JCLR    #EF,X:PBD,END_DO                  ;      Low,  High => try again
                        000074
474       P:006F P:406F 0C006A            JMP     <TST1                             ;      High, High => read FIFO
475       P:0070 P:4070 0AA489  TST3      JCLR    #EF,X:PBD,TST1
                        00006A
476       P:0072 P:4072 094B00            MOVEP             Y:RDFO,B2               ; Read the next byte of FIFO data
477       P:0073 P:4073 0C0076            JMP     <L_INCR
478    
479       P:0074 P:4074 00008C  END_DO    ENDDO                                     ; ENDDO the L_WORD DO loop above
480       P:0075 P:4075 0C0086            JMP     <CLR_RTS
481    
482       P:0076 P:4076 06C800  L_INCR    DO      A0,L_ASR                          ; Shift a byte from B2 into B1
                        000079
483       P:0078 P:4078 20002A            ASR     B
484       P:0079 P:4079 0ACB47            BCLR    #7,B2
485                             L_ASR
486       P:007A P:407A 200030            ADD     Y,A                               ; Increment the LSB of A for DO loop argument
487       P:007B P:407B 21A400            MOVE              B1,X0
488       P:007C P:407C 200042            OR      X0,A                              ; Add in the current byte to the word
489                             L_WORD
490       P:007D P:407D 545B00            MOVE              A1,X:(R3)+              ; Put the word in the RCV buffer
491       P:007E P:407E 0A0020            BSET    #ST_RCV,X:<STATUS
492       P:007F P:407F 0C0084            JMP     <SET_RTS                          ; Set status register carry bit and return
493    
494       P:0080 P:4080 0AAE87  GET_SSI   JCLR    #SSI_RDF,X:SSISR,CLR_RTS
                        000086
495       P:0082 P:4082 085BAF            MOVEP             X:SSIRX,X:(R3)+         ; Put the word in the SSI receiver buffer
496       P:0083 P:4083 0A0000            BCLR    #ST_RCV,X:<STATUS
497       P:0084 P:4084 0AF960  SET_RTS   BSET    #0,SR                             ; Valid FIFO word => SR carry bit = 1
498       P:0085 P:4085 00000C            RTS
499       P:0086 P:4086 0AF940  CLR_RTS   BCLR    #0,SR                             ; Not valid FIFO word => SR carry bit = 0
500       P:0087 P:4087 00000C            RTS
501    
502                             ; Acknowledge the utility board request and wait for a normal header word
503       P:0088 P:4088 0AAE86  GET_UTL   JCLR    #SSI_TDE,X:SSISR,*                ; Wait for transmitter to be empty
                        000088
504       P:008A P:408A 08F0AF            MOVEP             X:TIM_ACK,X:SSITX       ; Write acknowledge to utility board
                        000021
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_boot.asm  Page 10



505       P:008C P:408C 0AAE87            JCLR    #SSI_RDF,X:SSISR,*                ; Wait for next utility board word
                        00008C
506       P:008E P:408E 085BAF            MOVEP             X:SSIRX,X:(R3)+         ; Overwrite UTL_REQ word
507       P:008F P:408F 0C0018            JMP     <HEADER                           ; Process it as normal header word
508    
509                             ; Check the header word (S,D,N) contained in X0 for self-consistency
510       P:0090 P:4090 549700  CHK_HDR   MOVE              X:<MASK1,A1             ; Test for S.LE.3 and D.LE.3 and N.LE.7
511       P:0091 P:4091 200046            AND     X0,A
512       P:0092 P:4092 0E209B            JNE     <CHK_ERR                          ; Test failed
513       P:0093 P:4093 549800            MOVE              X:<MASK2,A1
514       P:0094 P:4094 200046            AND     X0,A                              ; Test for either S.NE.0 or D.NE.0
515       P:0095 P:4095 0EA09B            JEQ     <CHK_ERR                          ; Test failed
516       P:0096 P:4096 549100            MOVE              X:<SEVEN,A1
517       P:0097 P:4097 200046            AND     X0,A                              ; Test for NWORDS .GE. 1
518       P:0098 P:4098 0EA09B            JEQ     <CHK_ERR
519       P:0099 P:4099 0AF940            BCLR    #0,SR                             ; Check OK - header is self-consistent
520       P:009A P:409A 00000C            RTS
521    
522                             ; Clear the FIFO and restart R3 and R4
523       P:009B P:409B 0A0080  CHK_ERR   JCLR    #ST_RCV,X:<STATUS,CLR_SSI
                        0000A4
524       P:009D P:409D 0A0907            BCLR    #RST_FIFO,X:<LATCH                ; Clear the FIFO
525       P:009E P:409E 09F081            MOVEP             X:LATCH,Y:WRLATCH
                        000009
526       P:00A0 P:40A0 0A0927            BSET    #RST_FIFO,X:<LATCH
527       P:00A1 P:40A1 09F081            MOVEP             X:LATCH,Y:WRLATCH
                        000009
528       P:00A3 P:40A3 0C00A8            JMP     <RTS_ERR
529       P:00A4 P:40A4 08F4A1  CLR_SSI   MOVEP             #$0000,X:PCC            ; Software reset of SSI
                        000000
530       P:00A6 P:40A6 08F4A1            MOVEP             #$01E8,X:PCC            ; Enable the SSI
                        0001E8
531       P:00A8 P:40A8 0AF960  RTS_ERR   BSET    #0,SR
532       P:00A9 P:40A9 00000C            RTS
533    
534                             ; Start up the exposure timer and check for incoming commands during
535                             ;  the exposure countdown
536       P:00AA P:40AA 568100  EXPOSE    MOVE              X:<EXP_TIM,A            ; Enter exposure time into timer's
537       P:00AB P:40AB 560300            MOVE              A,X:<TGT_TIM            ;   target time
538       P:00AC P:40AC 200013            CLR     A                                 ; Zero out elapsed time
539       P:00AD P:40AD 560200            MOVE              A,X:<EL_TIM
540       P:00AE P:40AE 0A9E20            BSET    #TIM_BIT,X:TCSR                   ; Enable the DSP timer
541       P:00AF P:40AF 0D005D  CHK_RCV   JSR     <GET_RCV                          ; Check for an incoming command
542       P:00B0 P:40B0 0E8012            JCS     <CHK_SSI                          ; If command is received, go check it
543       P:00B1 P:40B1 0A9EA0  CHK_TIM   JSET    #TIM_BIT,X:TCSR,CHK_RCV           ; Wait for timer to end
                        0000AF
544       P:00B3 P:40B3 0AE780            JMP     (R7)                              ; Jump to the internal jump address
545    
546                             ; Interrupt service routine for the DSP timer, called every millisecond
547       P:00B4 P:40B4 050439  TIMER     MOVEC             SR,X:<SV_SR             ; Save registers used in this ISR
548       P:00B5 P:40B5 510500            MOVE              B0,X:<SV_B0
549       P:00B6 P:40B6 550600            MOVE              B1,X:<SV_B1
550       P:00B7 P:40B7 530700            MOVE              B2,X:<SV_B2
551       P:00B8 P:40B8 470800            MOVE              Y1,X:<SV_Y1
552       P:00B9 P:40B9 578E00            MOVE              X:<ONE,B
553       P:00BA P:40BA 478200            MOVE              X:<EL_TIM,Y1            ; Get elapsed time
554       P:00BB P:40BB 478378            ADD     Y1,B      X:<TGT_TIM,Y1           ; Get target time
555       P:00BC P:40BC 570200            MOVE              B,X:<EL_TIM             ; EL_TIM = EL_TIM + 1
556       P:00BD P:40BD 20007D            CMP     Y1,B
557       P:00BE P:40BE 0E90C0            JLT     <NO_TIM                           ; If (EL .GE. TGT) we've timed out
558       P:00BF P:40BF 0A9E00            BCLR    #TIM_BIT,X:TCSR                   ; Disable timer
559       P:00C0 P:40C0 058439  NO_TIM    MOVEC             X:<SV_SR,SR             ; Restore saved registers
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_boot.asm  Page 11



560       P:00C1 P:40C1 518500            MOVE              X:<SV_B0,B0
561       P:00C2 P:40C2 558600            MOVE              X:<SV_B1,B1
562       P:00C3 P:40C3 538700            MOVE              X:<SV_B2,B2
563       P:00C4 P:40C4 478800            MOVE              X:<SV_Y1,Y1
564       P:00C5 P:40C5 000004            RTI                                       ; Return from TIMER interrupt
565    
566                             ; Test Data Link - simply return value received after 'TDL'
567       P:00C6 P:40C6 44DC00  TDL       MOVE              X:(R4)+,X0              ; Get data value
568       P:00C7 P:40C7 0C0053            JMP     <FINISH1                          ; Return from executing TDL command
569    
570                             ; Read DSP or EEPROM memory ('RDM' address): read memory, reply with value
571       P:00C8 P:40C8 60E400  RDMEM     MOVE              X:(R4),R0               ; Need the address in an address register
572       P:00C9 P:40C9 56DC00            MOVE              X:(R4)+,A               ; Need address also in a 24-bit register
573       P:00CA P:40CA 0ACE14            JCLR    #20,A,RDX                         ; Test address bit for Program memory
                        0000CE
574       P:00CC P:40CC 07E084            MOVE              P:(R0),X0               ; Read from Program Memory
575       P:00CD P:40CD 0C0053            JMP     <FINISH1                          ; Send out a header with the value
576       P:00CE P:40CE 0ACE15  RDX       JCLR    #21,A,RDY                         ; Test address bit for X: memory
                        0000D2
577       P:00D0 P:40D0 44E000            MOVE              X:(R0),X0               ; Write to X data memory
578       P:00D1 P:40D1 0C0053            JMP     <FINISH1                          ; Send out a header with the value
579       P:00D2 P:40D2 0ACE16  RDY       JCLR    #22,A,RDR                         ; Test address bit for Y: memory
                        0000D6
580       P:00D4 P:40D4 4CE000            MOVE                          Y:(R0),X0   ; Read from Y data memory
581       P:00D5 P:40D5 0C0053            JMP     <FINISH1                          ; Send out a header with the value
582       P:00D6 P:40D6 0ACE17  RDR       JCLR    #23,A,ERROR                       ; Test address bit for read from EEPROM memory
                        000050
583       P:00D8 P:40D8 0ABE27            BSET    #7,X:BCR                          ; Slow down P: accesses to EEPROM speed
584       P:00D9 P:40D9 449000            MOVE              X:<THREE,X0             ; Convert to word address to a byte address
585       P:00DA P:40DA 220600            MOVE              R0,Y0                   ; Get 16-bit address in a data register
586       P:00DB P:40DB 2000D0            MPY     X0,Y0,A                           ; Multiply
587       P:00DC P:40DC 200022            ASR     A                                 ; Eliminate zero fill of fractional multiply
588       P:00DD P:40DD 211000            MOVE              A0,R0                   ; Need to address memory
589       P:00DE P:40DE 0AD06F            BSET    #15,R0                            ; Set bit so its in EEPROM space
590       P:00DF P:40DF 060380            DO      #3,L1RDR
                        0000E4
591       P:00E1 P:40E1 07D88A            MOVE              P:(R0)+,A2              ; Read each ROM byte
592       P:00E2 P:40E2 0608A0            REP     #8
593       P:00E3 P:40E3 200022            ASR     A                                 ; Move right into A1
594       P:00E4 P:40E4 000000            NOP
595                             L1RDR
596       P:00E5 P:40E5 218400            MOVE              A1,X0                   ; FINISH1 transmits X0 as its reply
597       P:00E6 P:40E6 0ABE07            BCLR    #7,X:BCR                          ; Restore P: speed to fast
598       P:00E7 P:40E7 0C0053            JMP     <FINISH1
599    
600                             ; Program WRMEM ('WRM' address datum): write to memory, reply 'DON'.
601       P:00E8 P:40E8 60E400  WRMEM     MOVE              X:(R4),R0               ; Get the desired address
602       P:00E9 P:40E9 56DC00            MOVE              X:(R4)+,A               ; We need a 24-bit version of the address
603       P:00EA P:40EA 44DC00            MOVE              X:(R4)+,X0              ; Get datum into X0 so MOVE works easily
604       P:00EB P:40EB 0ACE14            JCLR    #20,A,WRX                         ; Test address bit for Program memory
                        0000EF
605       P:00ED P:40ED 076084            MOVE              X0,P:(R0)               ; Write to Program memory
606       P:00EE P:40EE 0C0052            JMP     <FINISH
607       P:00EF P:40EF 0ACE15  WRX       JCLR    #21,A,WRY                         ; Test address bit for X: memory
                        0000F3
608       P:00F1 P:40F1 446000            MOVE              X0,X:(R0)               ; Write to X: memory
609       P:00F2 P:40F2 0C0052            JMP     <FINISH
610       P:00F3 P:40F3 0ACE16  WRY       JCLR    #22,A,WRR                         ; Test address bit for Y: memory
                        0000F7
611       P:00F5 P:40F5 4C6000            MOVE                          X0,Y:(R0)   ; Write to Y: memory
612       P:00F6 P:40F6 0C0052            JMP     <FINISH
613       P:00F7 P:40F7 0ACE17  WRR       JCLR    #23,A,ERROR                       ; Test address bit for write to EEPROM
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_boot.asm  Page 12



                        000050
614       P:00F9 P:40F9 0ABE27            BSET    #7,X:BCR                          ; Slow down P: accesses to EEPROM speed
615       P:00FA P:40FA 459000            MOVE              X:<THREE,X1             ; Convert to word address to a byte address
616       P:00FB P:40FB 220600            MOVE              R0,Y0                   ; Get 16-bit address in a data register
617       P:00FC P:40FC 2000E0            MPY     X1,Y0,A                           ; Multiply
618       P:00FD P:40FD 200022            ASR     A                                 ; Eliminate zero fill of fractional multiply
619       P:00FE P:40FE 211000            MOVE              A0,R0                   ; Need to address memory
620       P:00FF P:40FF 0AD06F            BSET    #15,R0                            ; Set bit so its in EEPROM space
621       P:0100 P:4100 208C00            MOVE              X0,A1                   ; Get data from command string
622       P:0101 P:4101 060380            DO      #3,L1WRR                          ; Loop over three bytes of the word
                        00010A
623       P:0103 P:4103 07588C            MOVE              A1,P:(R0)+              ; Write each EEPROM byte
624       P:0104 P:4104 0608A0            REP     #8
625       P:0105 P:4105 469622            ASR     A         X:<C50000,Y0            ; Move right one byte, enter delay
626       P:0106 P:4106 06C600            DO      Y0,L2WRR                          ; Delay by 12 milliseconds for EEPROM write
                        000109
627       P:0108 P:4108 0604A0            REP     #4                                ; Assume 50 MHz DSP56002
628       P:0109 P:4109 000000            NOP
629                             L2WRR
630       P:010A P:410A 000000            NOP                                       ; DO loop nesting restriction
631                             L1WRR
632       P:010B P:410B 0ABE07  JMP_FIN   BCLR    #7,X:BCR                          ; Restore P: access speed
633       P:010C P:410C 0C0052            JMP     <FINISH
634    
635    
636                             ; Read EEPROM code into DSP memory starting at P:APL_ADR. Allow $F00 bytes
637                             ;    of EEPROM per application, from EEPROM address $0000 to $3FFF. Up to
638                             ;    four applications can be loaded. The boot code starts at $4000.
639    
640       P:010D P:410D 44DC00  LDAPPL    MOVE              X:(R4)+,X0              ; Number of application program
641       P:010E P:410E 469500            MOVE              X:<C780,Y0              ; $780 = $F00 / 2 because of MPY's LSHFT
642       P:010F P:410F 67F4D0            MPY     X0,Y0,A   #APL_ADR,R7
                        000130
643       P:0111 P:4111 211000            MOVE              A0,R0                   ; EEPROM address = # x $F00
644       P:0112 P:4112 0AD06F            BSET    #15,R0                            ; All EEPROM accesses => A15=1
645       P:0113 P:4113 0ABE27            BSET    #7,X:BCR                          ; Slow down P: accesses to EEPROM speed
646       P:0114 P:4114 065083            DO      #MISC_LEN+APL_LEN,LD_LA2          ; Load from APL_ADR
                        00011B
647       P:0116 P:4116 060380            DO      #3,LD_LA1
                        00011A
648       P:0118 P:4118 07D88A            MOVE              P:(R0)+,A2              ; Read from EEPROM
649       P:0119 P:4119 0608A0            REP     #8
650       P:011A P:411A 200022            ASR     A
651                             LD_LA1
652       P:011B P:411B 075F8C            MOVE              A1,P:(R7)+              ; Write to DSP P: memory
653                             LD_LA2
654    
655                             ; Splice the application and boot command tables together
656       P:011C P:411C 378000            MOVE              #COM_TBL,R7             ; Leave most of X: memory alone
657       P:011D P:411D 064080            DO      #COM_LEN,LD_LA4                   ; 32 commands, 2 DSP words per command
                        000124
658       P:011F P:411F 060380            DO      #3,LD_LA3
                        000123
659       P:0121 P:4121 07D88A            MOVE              P:(R0)+,A2              ; Read from EEPROM
660       P:0122 P:4122 0608A0            REP     #8
661       P:0123 P:4123 200022            ASR     A
662                             LD_LA3
663       P:0124 P:4124 545F00            MOVE              A1,X:(R7)+              ; Write to DSP X: memory
664                             LD_LA4
665    
666                             ; Transfer to Y: memory, containing application program waveforms and
667                             ;   readout parameters
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_boot.asm  Page 13



668       P:0125 P:4125 370000            MOVE              #0,R7                   ; Start at bottom of Y: memory
669       P:0126 P:4126 067081            DO      #$500-APL_LEN-COM_LEN-MISC_LEN,LD_LA6
                        00012D
670       P:0128 P:4128 060380            DO      #3,LD_LA5
                        00012C
671       P:012A P:412A 07D88A            MOVE              P:(R0)+,A2              ; Read from EEPROM
672       P:012B P:412B 0608A0            REP     #8
673       P:012C P:412C 200022            ASR     A
674                             LD_LA5
675       P:012D P:412D 5C5F00            MOVE                          A1,Y:(R7)+  ; Write to DSP Y: memory
676                             LD_LA6
677       P:012E P:412E 0C010B            JMP     <JMP_FIN                          ; Just to save one instruction
678    
679                             ; Check that the boot code is not too big
680                                       IF      @CVS(N,*)>APL_ADR
682                                       ENDIF                                     ;  will not be overwritten
683    
684                             ;  ********* Beginning of X: definitions ************
685    
686                             ; Status and header processing words
687       X:0000 P:4200                   ORG     X:0,P:LD_X
688       X:0000 P:4200         STATUS    DC      4                                 ; Status word; IDLEMODE bit is set
689    
690                             ; Timer related constants
691       X:0001 P:4201         EXP_TIM   DC      1000                              ; Exposure time (milliseconds), written by host 
computer
692       X:0002 P:4202         EL_TIM    DC      0                                 ; Elapsed exposure time in milliseconds
693       X:0003 P:4203         TGT_TIM   DC      0                                 ; TGT_TIM = EXP_TIM at beginning of exposure
694       X:0004 P:4204         SV_SR     DC      0                                 ; Save for timer ISR
695       X:0005 P:4205         SV_B0     DC      0                                 ; Save for timer ISR
696       X:0006 P:4206         SV_B1     DC      0                                 ; Save for timer ISR
697       X:0007 P:4207         SV_B2     DC      0                                 ; Save for timer ISR
698       X:0008 P:4208         SV_Y1     DC      0                                 ; Save for timer ISR
699    
700       X:0009 P:4209         LATCH     DC      $FA                               ; Starting value in latch chip U25
701       X:000A P:420A         HDR       DC      0                                 ; Header for all commands
702       X:000B P:420B         NWORDS    DC      0                                 ; Number of words in command
703       X:000C P:420C         IDL_ADR   DC      0                                 ; Address of routine to be executed when idle
704    
705                             ; Miscellaneous constant definitions
706       X:000D P:420D         ZERO      DC      0
707       X:000E P:420E         ONE       DC      1
708       X:000F P:420F         TWO       DC      2
709       X:0010 P:4210         THREE     DC      3
710       X:0011 P:4211         SEVEN     DC      7
711       X:0012 P:4212         EIGHT     DC      8
712       X:0013 P:4213         EN_SI     DC      $0160                             ; Enable the SSI serial port C
713       X:0014 P:4214         DISA_SI   DC      $0000                             ; Disable the SSI serial port C
714       X:0015 P:4215         C780      DC      $780                              ; EEPROM space per application program
715       X:0016 P:4216         C50000    DC      50000                             ; Delay for WRROM = 12 millisec
716       X:0017 P:4217         MASK1     DC      $FCFCF8                           ; Mask for checking header
717       X:0018 P:4218         MASK2     DC      $030300                           ; Mask for checking header
718       X:0019 P:4219         SBRD      DC      $020000                           ; Source Identification number
719       X:001A P:421A         DBRD      DC      $000200                           ; Destination Identification number
720       X:001B P:421B         DMASK     DC      $00FF00                           ; Mask to get destination board number out
721       X:001C P:421C         SMASK     DC      $FF0000                           ; Mask to get source board number out
722       X:001D P:421D         ERR       DC      'ERR'                             ; An error occurred
723       X:001E P:421E         DON       DC      'DON'                             ; Command was fully processed
724       X:001F P:421F         TIM       DC      $020002                           ; Timing board reply header
725       X:0020 P:4220         UTL_REQ   DC      $555555                           ; Word for utility requesting SSI service
726       X:0021 P:4221         TIM_ACK   DC      $AAAAAA                           ; Word for timing acknowledging SSI service
727       X:0022 P:4222         TIM_COM   DC      4000                              ; Timing command timeout, about 2 milliseconds
Motorola DSP56000 Assembler  Version 6.3.0   121-03-05  10:29:18  tim2_boot.asm  Page 14



728    
729                             ; Command table resident in X: data memory
730                             ;   The first part of the command table will be loaded with application commands
731       X:0080 P:4280                   ORG     X:COM_TBL,P:COM_TBL+LD_X
732       X:0080 P:4280                   DC      0,START,0,START,0,START,0,START   ; Space for 32 application
733       X:0088 P:4288                   DC      0,START,0,START,0,START,0,START   ;   commands
734       X:0090 P:4290                   DC      0,START,0,START,0,START,0,START
735       X:0098 P:4298                   DC      0,START,0,START,0,START,0,START
736       X:00A0 P:42A0                   DC      0,START,0,START,0,START,0,START
737       X:00A8 P:42A8                   DC      0,START,0,START,0,START,0,START
738       X:00B0 P:42B0                   DC      0,START,0,START,0,START,0,START
739       X:00B8 P:42B8                   DC      0,START,0,START,0,START,0,START
740       X:00C0 P:42C0                   DC      'TDL',TDL                         ; Test Data Link
741       X:00C2 P:42C2                   DC      'RDM',RDMEM                       ; Read from DSP or EEPROM memory
742       X:00C4 P:42C4                   DC      'WRM',WRMEM                       ; Write to DSP memory
743       X:00C6 P:42C6                   DC      'LDA',LDAPPL                      ; Load application progam from EEPROM to DSP
744       X:00C8 P:42C8                   DC      'STP',FINISH                      ; Put it here as a no op
745       X:00CA P:42CA                   DC      'DON',PRC_RCV                     ; Nothing special
746       X:00CC P:42CC                   DC      'ERR',PRC_RCV                     ; Nothing special
747       X:00CE P:42CE                   DC      'STP',FINISH                      ; NOP
748    
749                             ; End of program
750                                       END

0    Errors
0    Warnings


