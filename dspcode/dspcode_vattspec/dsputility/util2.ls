Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  util2.asm  Page 1



1                               COMMENT *
2      
3                        This file is used to generate DSP code for the utility board. It will time
4                             the exposure, operate the shutter, control the CCD temperature and
5                             turn the analog power on. This is Rev. 3.00 software.
6                        Modified 1-12-97 for 10 MHz input clock frequency by adding 2 to elapsed
7                             exposure time rather than one.
8                        Power ON sequence written for Gen II power control board, Rev. 4A
9      
10                       -d HOST 'HOST'  To generate code for downloading to DSP memory.
11                       -d HOST 'ROM'   To generate code for writing to the ROM.
12     
13                               *
14                                 PAGE    132                               ; Printronix page width - 132 columns
15     
16                       ; Name it a section so it doesn't conflict with other application programs
17                                 SECTION UTILAPPL
18     
19                       ;  These are also defined in "utilboot.asm", so be sure they agree
20        000090         APL_ADR   EQU     $90                               ; Starting address of application program
21        000080         BUF_STR   EQU     $80                               ; Starting address of buffers in X:
22        000020         BUF_LEN   EQU     $20                               ; Length of buffers
23        000080         SSI_BUF   EQU     BUF_STR                           ; Starting address of SCI buffer in X:
24        0000A0         COM_BUF   EQU     SSI_BUF+BUF_LEN                   ; Starting address of command buffer in X:
25        0000C0         COM_TBL   EQU     COM_BUF+BUF_LEN                   ; Starting address of command table in X:
26     
27                       ;  Define some useful constants
28        001EE0         APL_XY    EQU     $1EE0                             ; Starting address in EEPROM of X: and Y: values
29        000096         DLY_MUX   EQU     150                               ; Number of DSP cycles to delay for MUX settling
30        0000C8         DLY_AD    EQU     200                               ; Number of DSP cycles to delay for A/D settling
31     
32                       ; Assign addresses to port B data register
33        00FFE4         PBD       EQU     $FFE4                             ; Port B Data Register
34        00FFFF         IPR       EQU     $FFFF                             ; Interrupt Priority Register
35     
36                       ;  Addresses of memory mapped components in Y: data memory space
37                       ;  Write addresses first
38        00FFF0         WR_DIG    EQU     $FFF0                             ; was $FFFF  Write Digital output values D00-D15
39        00FFF1         WR_MUX    EQU     $FFF1                             ; Select MUX connected to A/D input - one of 16
40        00FFF2         EN_DIG    EQU     $FFF2                             ; Enable digital outputs
41        00FFF7         WR_DAC3   EQU     $FFF7                             ; Write to DAC#3 D00-D11
42        00FFF6         WR_DAC2   EQU     $FFF6                             ; Write to DAC#2 D00-D11
43        00FFF5         WR_DAC1   EQU     $FFF5                             ; Write to DAC#1 D00-D11
44        00FFF4         WR_DAC0   EQU     $FFF4                             ; Write to DAC#0 D00-D11
45     
46                       ;  Read addresses next
47        00FFF0         RD_DIG    EQU     $FFF0                             ; Read Digital input values D00-D15
48        00FFF1         STR_ADC   EQU     $FFF1                             ; Start ADC conversion, ignore data
49        00FFF2         RD_ADC    EQU     $FFF2                             ; Read A/D converter value D00-D11
50        00FFF7         WATCH     EQU     $FFF7                             ; Watch dog timer - tell it that DSP is alive
51     
52                       ;  Bit definitions of STATUS word
53        000000         ST_SRVC   EQU     0                                 ; Set if ADC routine needs executing
54        000001         ST_EX     EQU     1                                 ; Set if timed exposure is in progress
55        000002         ST_SH     EQU     2                                 ; Set if shutter is open
56        000003         ST_READ   EQU     3                                 ; Set if a readout needs to be initiated
57        000004         STRT_EX   EQU     4                                 ; Set to indicate start of exposure
58     
59                       ; Bit definitions of software OPTIONS word
60        000000         OPT_SH    EQU     0                                 ; Set to open and close shutter
61     
62                       ;  Bit definitions of Port B = Host Processor Interface
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  util2.asm  Page 2



63        000000         PWR_EN1   EQU     0                                 ; Power enable bit ONE - Output
64        000001         PWR_EN0   EQU     1                                 ; Power enable bit ZERO  - Output
65        000002         PWRST     EQU     2                                 ; Reset power conditioner counter - Output
66        000003         SHUTTER   EQU     3                                 ; Control shutter - Output
67        000004         IRQ_T     EQU     4                                 ; Request interrupt service from timing board - Output
68        000005         SYS_RST   EQU     5                                 ; Reset entire system - Output
69        000008         WATCH_T   EQU     8                                 ; Processed watchdog signal from timing board - Input
70     
71                       ;**************************************************************************
72                       ;                                                                         *
73                       ;    Register assignments                                                 *
74                       ;        R1 - Address of SCI receiver contents                            *
75                       ;        R2 - Address of processed SCI receiver contents                  *
76                       ;        R3 - Pointer to current top of command buffer                    *
77                       ;        R4 - Pointer to processed contents of command buffer             *
78                       ;        N4 - Address for internal jumps after receiving 'DON' replies    *
79                       ;        R0, R5, R6, A, X0, X1 - For use by program only                  *
80                       ;        R7 - For use by SCI ISR only                                     *
81                       ;        Y0, Y1, and B - For use by timer ISR only. If any of these       *
82                       ;               registers are needed elsewhere they must be saved and     *
83                       ;               restored in the TIMER ISR.                                *
84                       ;**************************************************************************
85     
86                       ; Specify execution and load addresses.
87        P:0090 P:0090                   ORG     P:APL_ADR,P:APL_ADR
88     
89                              ; The TIMER addresses must be defined here and SERVICE must follow to match
90                              ;   up with the utilboot code
91                              ;       JMP     <SERVICE                ; Millisecond timer interrupt
92        P:0090 P:0090 00000C            RTS
93     
94        P:0091 P:0091 000004  TIMER     RTI                                       ; RTI for now so downloading works
95        P:0092 P:0092 0A0081            JCLR    #ST_EX,X:STATUS,NO_TIM            ; Continue on if we're not exposing
                        0000AE
96        P:0094 P:0094 0A0084            JCLR    #STRT_EX,X:<STATUS,EX_STRT        ; Skip if exposure has been started
                        00009E
97        P:0096 P:0096 0A0004            BCLR    #STRT_EX,X:<STATUS                ; Clear status = "not start of exposure"
98        P:0097 P:0097 20001B            CLR     B
99        P:0098 P:0098 5F1700            MOVE                          B,Y:<EL_TIM_MSECONDS ; Initialize elapsed time
100       P:0099 P:0099 5F3600            MOVE                          B,Y:<EL_TIM_FRACTION
101       P:009A P:009A 0A0080            JCLR    #OPT_SH,X:<OPTIONS,NO_TIM         ; Don't open shutter if a dark frame
                        0000AE
102       P:009C P:009C 0D00F3            JSR     <OSHUT                            ; Open shutter if start of exposure
103       P:009D P:009D 0C00AE            JMP     <NO_TIM                           ; Don't increment EL_TIM at first
104       P:009E P:009E 4EB71B  EX_STRT   CLR     B                     Y:<INCR,Y0  ; INCR = 0.8 seconds
105       P:009F P:009F 478000            MOVE              X:<ZERO,Y1
106       P:00A0 P:00A0 5D9700            MOVE                          Y:<EL_TIM_MSECONDS,B1 ; Get elapsed time
107       P:00A1 P:00A1 59B600            MOVE                          Y:<EL_TIM_FRACTION,B0
108       P:00A2 P:00A2 4F9838            ADD     Y,B                   Y:<TGT_TIM,Y1 ; EL_TIM = EL_TIM + 0.8 milliseconds
109       P:00A3 P:00A3 593600            MOVE                          B0,Y:<EL_TIM_FRACTION
110       P:00A4 P:00A4 5D177C            SUB     Y1,B                  B1,Y:<EL_TIM_MSECONDS
111       P:00A5 P:00A5 0E90AE            JLT     <NO_TIM                           ; If (EL .GE. TGT) we've timed out
112    
113                             ; Close the shutter at once if needed
114       P:00A6 P:00A6 0A0080            JCLR    #OPT_SH,X:OPTIONS,NO_SHUT         ; Close the shutter only if needed
                        0000AA
115       P:00A8 P:00A8 0AA423            BSET    #SHUTTER,X:PBD                    ; Set Port B bit #3 to close shutter
116       P:00A9 P:00A9 0A0022            BSET    #ST_SH,X:<STATUS                  ; Set status to mean shutter closed
117    
118                             ; Wait SH_DLY milliseconds for the shutter to fully close before reading out
119       P:00AA P:00AA 4FB800  NO_SHUT   MOVE                          Y:<SH_DEL,Y1 ; Get shutter closing time
120       P:00AB P:00AB 20007C            SUB     Y1,B                              ; B = EL_TIM - (TGT_TIM + SH_DEL)
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  util2.asm  Page 3



121       P:00AC P:00AC 0E90AE            JLT     <NO_TIM                           ; If (EL .GE. TGT+DEL) we've timed out
122       P:00AD P:00AD 0A0023            BSET    #ST_READ,X:<STATUS                ; Set so a readout will be initiated
123    
124                             ; Return from interrupt
125       P:00AE P:00AE 0A0020  NO_TIM    BSET    #ST_SRVC,X:<STATUS                ; SERVICE needs executing
126       P:00AF P:00AF 05B579            MOVEC                         Y:<SV_SR,SR ; Restore Status Register
127       P:00B0 P:00B0 000000            NOP
128       P:00B1 P:00B1 000004            RTI                                       ; Return from TIMER interrupt
129    
130                             ; This long subroutine is executed every millisecond, but isn't an ISR so
131                             ;   that care need not be taken to preserve registers and stacks.
132       P:00B2 P:00B2 0A0000  SERVICE   BCLR    #ST_SRVC,X:<STATUS                ; Clear request to execute SERVICE
133       P:00B3 P:00B3 0A0083            JCLR    #ST_READ,X:<STATUS,UPD_DIG        ; Initiate readout?
                        0000BC
134    
135                             ; Extra call if using the VME interface board
136                                       IF      @SCP("INTERFACE","VME")
141                                       ENDIF
142    
143       P:00B5 P:00B5 568000            MOVE              X:<TIMING,A
144       P:00B6 P:00B6 565B00            MOVE              A,X:(R3)+               ; Header from Utility to timing
145       P:00B7 P:00B7 5EA900            MOVE                          Y:<RDC,A
146       P:00B8 P:00B8 565B00            MOVE              A,X:(R3)+               ; Start reading out the CCD
147       P:00B9 P:00B9 0A0001            BCLR    #ST_EX,X:<STATUS                  ; Exposure is no longer in progress
148       P:00BA P:00BA 0A0003            BCLR    #ST_READ,X:<STATUS                ; Readout will be initiated
149       P:00BB P:00BB 00000C            RTS                                       ; Return now to save time
150    
151                             ; Update all the digital input/outputs; reset watchdog timer
152       P:00BC P:00BC 0970F0  UPD_DIG   MOVEP             Y:RD_DIG,Y:DIG_IN       ; Read 16 digital inputs
                        000000
153       P:00BE P:00BE 09F4B2            MOVEP             #1,Y:EN_DIG             ; Enable digital outputs
                        000001
154       P:00C0 P:00C0 09F0F0            MOVEP             Y:DIG_OUT,Y:WR_DIG      ; Write 16 digital outputs
                        000001
155    
156                             ; Update the 4 DACs
157       P:00C2 P:00C2 09F0F4            MOVEP             Y:DAC0,Y:WR_DAC0        ; Write to DAC0
                        000002
158       P:00C4 P:00C4 09F0F5            MOVEP             Y:DAC1,Y:WR_DAC1        ; Write to DAC1
                        000003
159       P:00C6 P:00C6 09F0F6            MOVEP             Y:DAC2,Y:WR_DAC2        ; Write to DAC2
                        000004
160       P:00C8 P:00C8 09F0F7            MOVEP             Y:DAC3,Y:WR_DAC3        ; Write to DAC3
                        000005
161    
162                             ; Analog Input processor - read the 16 A/D inputs
163       P:00CA P:00CA 448000            MOVE              X:<ONE,X0               ; For incrementing accumulator to select MUX
164       P:00CB P:00CB 350713            CLR     A         #<AD_IN,R5              ; Will contain MUX number
165       P:00CC P:00CC 060640            DO      Y:NUM_AD,LOOP_AD                  ; Loop over each A/D converter input
                        0000DB
166       P:00CE P:00CE 09CE31            MOVEP             A,Y:WR_MUX              ; Select MUX input
167       P:00CF P:00CF 069680            DO      #DLY_MUX,L_AD1                    ; Wait for the MUX to settle
                        0000D1
168       P:00D1 P:00D1 5C3400            MOVE                          A1,Y:<SV_A1 ; DO needed so SSI input can come in
169                             L_AD1
170       P:00D2 P:00D2 094531            MOVEP             Y:STR_ADC,X1            ; Start A/D conversion - dummy read
171       P:00D3 P:00D3 06C880            DO      #DLY_AD,L_AD2                     ; Wait for the A/D to settle
                        0000D5
172       P:00D5 P:00D5 458000            MOVE              X:<CFFF,X1
173                             L_AD2
174       P:00D6 P:00D6 094C32            MOVEP             Y:RD_ADC,A1             ; Get the A/D value
175       P:00D7 P:00D7 200066            AND     X1,A                              ; A/D is only valid to 12 bits
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  util2.asm  Page 4



176       P:00D8 P:00D8 0BCC4B            BCHG    #11,A1                            ; Change 12-bit 2's complement to unipolar
177       P:00D9 P:00D9 5C5D00            MOVE                          A1,Y:(R5)+  ; Put the A/D value in the table
178       P:00DA P:00DA 5CB400            MOVE                          Y:<SV_A1,A1 ; Restore A1 = MUX number
179       P:00DB P:00DB 200040            ADD     X0,A                              ; Increment A = MUX number by one
180                             LOOP_AD
181       P:00DC P:00DC 09F0B1            MOVEP             X:ONE,Y:WR_MUX          ; Sample +5V when idle
                        000000
182    
183                             ; Control the CCD Temperature
184                             ; The algorithmn assumes a reverse biased diode whose A/D count A_CCDT
185                             ;   is proportional to temperature. Don't start controlling temperature
186                             ;   until it falls below target temperature.
187       P:00DE P:00DE 4C9C00            MOVE                          Y:<T_CCDT,X0 ; Get actual CCD temperature
188       P:00DF P:00DF 5E8C00            MOVE                          Y:<A_CCDT,A ; Get lower CCD temperature limit
189       P:00E0 P:00E0 200044            SUB     X0,A
190       P:00E1 P:00E1 21C400            MOVE              A,X0
191       P:00E2 P:00E2 4D9D00            MOVE                          Y:<T_COEFF,X1
192       P:00E3 P:00E3 2000A0            MPY     X0,X1,A                           ; A = (actual - target) * T_COEFF
193       P:00E4 P:00E4 4D8200            MOVE                          Y:<DAC0,X1  ; A positive -> actual > target ->
194       P:00E5 P:00E5 4C9E00            MOVE                          Y:<DAC0_LS,X0 ;   too cold -> add more heat
195       P:00E6 P:00E6 200020            ADD     X,A                               ; Add both least and most significant
196                                                                                 ;   words (X0 and X1) to accumulator A
197       P:00E7 P:00E7 4CB300            MOVE                          Y:<CC00,X0  ; Heats greater than this are not allowed
198       P:00E8 P:00E8 200045            CMP     X0,A
199       P:00E9 P:00E9 0E90EC            JLT     <TST_LOW
200       P:00EA P:00EA 208E00            MOVE              X0,A                    ; Make it the maximum heat
201       P:00EB P:00EB 0C00EF            JMP     <WR_DAC
202       P:00EC P:00EC 200003  TST_LOW   TST     A                                 ; Heats of less than zero are not allowed
203       P:00ED P:00ED 0E70EF            JGT     <WR_DAC
204       P:00EE P:00EE 568000            MOVE              X:<ZERO,A               ; No heat
205       P:00EF P:00EF 09CE34  WR_DAC    MOVEP             A,Y:WR_DAC0             ; Update DAC and record of it
206       P:00F0 P:00F0 5E0200            MOVE                          A,Y:<DAC0
207       P:00F1 P:00F1 581E00            MOVE                          A0,Y:<DAC0_LS
208       P:00F2 P:00F2 00000C            RTS                                       ; Return from subroutine SERVICE call
209    
210                             ; Shutter support subroutines for the TIMER executive
211                             ;   Also support shutter connection to timing board for now.
212       P:00F3 P:00F3 0AA403  OSHUT     BCLR    #SHUTTER,X:PBD                    ; Clear Port B bit #3 to open shutter
213       P:00F4 P:00F4 0A0002            BCLR    #ST_SH,X:<STATUS                  ; Clear status bit to mean shutter open
214       P:00F5 P:00F5 00000C            RTS
215    
216       P:00F6 P:00F6 0AA423  CSHUT     BSET    #SHUTTER,X:PBD                    ; Set Port B bit #3 to close shutter
217       P:00F7 P:00F7 0A0022            BSET    #ST_SH,X:<STATUS                  ; Set status to mean shutter closed
218       P:00F8 P:00F8 00000C            RTS
219    
220                             ; These are called directly by command, so need to call subroutines in turn
221       P:00F9 P:00F9 0D00F3  OPEN      JSR     OSHUT                             ; Call open shutter subroutine
222       P:00FA P:00FA 0C0000            JMP     <FINISH                           ; Send 'DON' reply
223       P:00FB P:00FB 0D00F6  CLOSE     JSR     CSHUT                             ; Call close shutter subroutine
224       P:00FC P:00FC 0C0000            JMP     <FINISH                           ; Send 'DON' reply
225    
226    
227                             ;  **************  BEGIN  COMMAND  PROCESSING  ***************
228                             ; Subroutine to turn analog power OFF
229                             PWR_OFF_SUBROUTINE
230       P:00FD P:00FD 448000            MOVE              X:<HDR_ID,X0
231       P:00FE P:00FE 4C3A00            MOVE                          X0,Y:<COM_HDR
232       P:00FF P:00FF 0A7009            BCLR    #9,X:PBDDR                        ; Make sure PWREN is an input
                        000000
233       P:0101 P:0101 568000            MOVE              X:<TIMING,A
234       P:0102 P:0102 565B00            MOVE              A,X:(R3)+               ; Header from Utility to timing board
235       P:0103 P:0103 5EB200            MOVE                          Y:<CSW,A
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  util2.asm  Page 5



236       P:0104 P:0104 565B00            MOVE              A,X:(R3)+               ; Clear all analog switches
237       P:0105 P:0105 74F400            MOVE              #*+3,N4                 ; Set internal jump address after 'DON'
                        000108
238       P:0107 P:0107 0C0000            JMP     <XMT_CHK                          ; Send the command to the timing board
239    
240                             ; Instruct the power control board to turn the analog power switches OFF
241                                       IF      @SCP("R6","R6")
242       P:0108 P:0108 0AA420            BSET    #LVEN,X:PBD                       ; LVEN = HVEN = 1 => Power reset
243       P:0109 P:0109 0AA422            BSET    #PWRST,X:PBD
244       P:010A P:010A 0AA420            BSET    #HVEN,X:PBD
245                                       ELSE                                      ; Earlier Revision power control boards
250                                       ENDIF
251    
252       P:010B P:010B 00000C            RTS                                       ; Return from PWR_OFF_SUBROUTINE
253    
254                             ; Power OFF command execution
255       P:010C P:010C 08F4BF  PWR_OFF   MOVEP             #$2000,X:IPR            ; Disable TIMER interrupts
                        002000
256       P:010E P:010E 0D00FD            JSR     <PWR_OFF_SUBROUTINE
257       P:010F P:010F 0C015F            JMP     <PWR_END                          ; Reply 'DON'
258    
259                             ; Start power-on cycle
260       P:0110 P:0110 08F4BF  PWR_ON    MOVEP             #$2000,X:IPR            ; Disable TIMER interrupts
                        002000
261       P:0112 P:0112 0D00FD            JSR     <PWR_OFF_SUBROUTINE               ; Turn everything OFF
262    
263                             ; The clocks must be not clocking during power ON because of the A/D converter
264       P:0113 P:0113 568000            MOVE              X:<TIMING,A
265       P:0114 P:0114 565B00            MOVE              A,X:(R3)+               ; Header from Utility to timing
266       P:0115 P:0115 5EB100            MOVE                          Y:<STP,A
267       P:0116 P:0116 565B00            MOVE              A,X:(R3)+               ; Stop the clocks during power on
268       P:0117 P:0117 74F400            MOVE              #*+3,N4                 ; Set internal jump address after 'DON'
                        00011A
269       P:0119 P:0119 0C0000            JMP     <XMT_CHK                          ; Send the command to the timing board
270    
271                             ; Wait for at least one cycle of serial and parallel clocks for the STP
272                             ;   command to take effect
273       P:011A P:011A 44F400            MOVE              #30000,X0
                        007530
274       P:011C P:011C 06C400            DO      X0,WT_PON1                        ; Wait 30 millisec or so for settling
                        00011F
275       P:011E P:011E 0605A0            REP     #5
276       P:011F P:011F 094437            MOVEP             Y:WATCH,X0              ; Reset watchdog timer
277                             WT_PON1
278    
279                             ; Now turn ON the low voltages (+/- 6.5V, 16.5V)
280                                       IF      @SCP("R6","R6")
281       P:0120 P:0120 0AA400            BCLR    #LVEN,X:PBD                       ; LVEN = Low => Turn on +/- 6.5V, +/- 16.5V
282       P:0121 P:0121 0AA402            BCLR    #PWRST,X:PBD
283                                       ELSE
289                                       ENDIF
290       P:0122 P:0122 0D016C            JSR     <PWR_DLY                          ; Delay for a little while
291    
292       P:0123 P:0123 09F4B1            MOVEP             #2,Y:WR_MUX             ; Select +15V MUX input
                        000002
293       P:0125 P:0125 44F400            MOVE              #65000,X0
                        00FDE8
294       P:0127 P:0127 06C400            DO      X0,WT_PON2                        ; Wait 20 millisec or so for settling
                        00012A
295       P:0129 P:0129 0605A0            REP     #5
296       P:012A P:012A 094437            MOVEP             Y:WATCH,X0              ; Reset watchdog timer
297                             WT_PON2
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  util2.asm  Page 6



298       P:012B P:012B 094431            MOVEP             Y:STR_ADC,X0            ; Start A/D conversion - dummy read
299       P:012C P:012C 06C880            DO      #DLY_AD,L_PON2                    ; Wait for the A/D to settle
                        00012E
300       P:012E P:012E 448013            CLR     A         X:<CFFF,X0              ; This saves some space
301                             L_PON2
302       P:012F P:012F 094C32            MOVEP             Y:RD_ADC,A1             ; Get the A/D value
303       P:0130 P:0130 4CA146            AND     X0,A                  Y:<T_P15,X0 ; A/D is only valid to 12 bits
304    
305                             ; Test that the voltage is in the range abs(initial - target) < margin
306       P:0131 P:0131 5C2644            SUB     X0,A                  A1,Y:<I_P15
307       P:0132 P:0132 4CA226            ABS     A                     Y:<K_P15,X0
308       P:0133 P:0133 200044            SUB     X0,A
309       P:0134 P:0134 0E7164            JGT     <PERR                             ; Take corrective action
310    
311       P:0135 P:0135 09F4B1  TST_M15   MOVEP             #3,Y:WR_MUX             ; Select -15v MUX input
                        000003
312       P:0137 P:0137 069680            DO      #DLY_MUX,L_PON3                   ; Wait for the MUX to settle
                        000139
313       P:0139 P:0139 000000            NOP
314                             L_PON3
315       P:013A P:013A 094431            MOVEP             Y:STR_ADC,X0            ; Start A/D conversion - dummy read
316       P:013B P:013B 06C880            DO      #DLY_AD,L_PON4                    ; Wait for the A/D to settle
                        00013D
317       P:013D P:013D 448013            CLR     A         X:<CFFF,X0              ; Clear A, so put it in DO loop
318                             L_PON4
319       P:013E P:013E 094C32            MOVEP             Y:RD_ADC,A1             ; Get the A/D value
320       P:013F P:013F 4CA346            AND     X0,A                  Y:<T_M15,X0 ; A/D is only valid to 12 bits
321    
322                             ; Test that the voltage is in the range abs(initial - target) < margin
323       P:0140 P:0140 5C2744            SUB     X0,A                  A1,Y:<I_M15
324       P:0141 P:0141 4CA426            ABS     A                     Y:<K_M15,X0
325       P:0142 P:0142 200044            SUB     X0,A
326       P:0143 P:0143 0E7164            JGT     <PERR
327    
328                             ; Now turn on the high voltage HV (nominally +36 volts)
329                                       IF      @SCP("R6","R6")
330       P:0144 P:0144 0AA400  HV_ON     BCLR    #HVEN,X:PBD                       ; HVEN = Low => Turn on +36V
331                                       ELSE
336                                       ENDIF
337    
338       P:0145 P:0145 0D016C            JSR     <PWR_DLY                          ; Delay for a little while
339       P:0146 P:0146 09F4B1            MOVEP             #1,Y:WR_MUX             ; Select high voltage MUX input
                        000001
340       P:0148 P:0148 44F400            MOVE              #65000,X0
                        00FDE8
341       P:014A P:014A 06C400            DO      X0,WT_HV                          ; Wait a few millisec for settling
                        00014C
342       P:014C P:014C 000000            NOP
343                             WT_HV
344       P:014D P:014D 094431            MOVEP             Y:STR_ADC,X0            ; Start A/D conversion - dummy read
345       P:014E P:014E 06C880            DO      #DLY_AD,L_PON6                    ; Wait for the A/D to settle
                        000150
346       P:0150 P:0150 448013            CLR     A         X:<CFFF,X0              ; Clear A, so put it in DO loop
347                             L_PON6
348       P:0151 P:0151 094C32            MOVEP             Y:RD_ADC,A1             ; Get the A/D value
349       P:0152 P:0152 4C9F46            AND     X0,A                  Y:<T_HV,X0  ; A/D is only valid to 12 bits
350    
351                             ; Test that the voltage is in the range abs(initial - target) < margin
352       P:0153 P:0153 5C2544            SUB     X0,A                  A1,Y:<I_HV
353       P:0154 P:0154 4CA026            ABS     A                     Y:<K_HV,X0
354       P:0155 P:0155 200044            SUB     X0,A
355       P:0156 P:0156 0E7164            JGT     <PERR                             ; Take corrective action
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  util2.asm  Page 7



356    
357                             ; Start up the clocks and DC biases from the timing board
358       P:0157 P:0157 568000            MOVE              X:<TIMING,A
359       P:0158 P:0158 565B00            MOVE              A,X:(R3)+               ; Header from Utility to timing
360       P:0159 P:0159 5EB000            MOVE                          Y:<IDL,A
361       P:015A P:015A 565B00            MOVE              A,X:(R3)+               ; Start up the clock drivers
362       P:015B P:015B 568000            MOVE              X:<TIMING,A
363       P:015C P:015C 565B00            MOVE              A,X:(R3)+               ; Header from Utility to timing
364       P:015D P:015D 5EAF00            MOVE                          Y:<SBV,A
365       P:015E P:015E 565B00            MOVE              A,X:(R3)+               ; Set bias voltages
366    
367                             ; Reply with a DONE message to the host computer
368       P:015F P:015F 4CBA00  PWR_END   MOVE                          Y:<COM_HDR,X0
369       P:0160 P:0160 440000            MOVE              X0,X:<HDR_ID            ; Header to host
370       P:0161 P:0161 08F4BF            MOVEP             #$2007,X:IPR            ; Enable TIMER interrupts
                        002007
371       P:0163 P:0163 0C0000            JMP     <FINISH                           ; Go transmit reply
372    
373                             ; Or, return with an error message
374       P:0164 P:0164 4CBA00  PERR      MOVE                          Y:<COM_HDR,X0
375       P:0165 P:0165 440000            MOVE              X0,X:<HDR_ID            ; Header to host
376       P:0166 P:0166 0D00FD            JSR     <PWR_OFF_SUBROUTINE               ; Turn power OFF if there's an error
377       P:0167 P:0167 4CBA00            MOVE                          Y:<COM_HDR,X0
378       P:0168 P:0168 440000            MOVE              X0,X:<HDR_ID            ; Header to host
379       P:0169 P:0169 08F4BF            MOVEP             #$2007,X:IPR            ; Enable TIMER interrupts
                        002007
380       P:016B P:016B 0C0000            JMP     <ERROR                            ; Go transmit reply
381    
382                             ; Delay between power control board instructions
383       P:016C P:016C 06A08F  PWR_DLY   DO      #4000,L_DLY
                        00016E
384       P:016E P:016E 000000            NOP
385                             L_DLY
386       P:016F P:016F 00000C            RTS
387    
388                             ; Start an exposure by first issuing a 'CLR' to the timing board
389                             START_EX
390       P:0170 P:0170 448000            MOVE              X:<HDR_ID,X0            ; Save header of device issuing command
391       P:0171 P:0171 4C3A00            MOVE                          X0,Y:<COM_HDR
392       P:0172 P:0172 568000            MOVE              X:<TIMING,A
393       P:0173 P:0173 565B00            MOVE              A,X:(R3)+               ; Header from Utility to timing
394       P:0174 P:0174 5EA800            MOVE                          Y:<CLR,A
395       P:0175 P:0175 565B00            MOVE              A,X:(R3)+               ; Clear the CCD
396       P:0176 P:0176 74F400            MOVE              #*+3,N4                 ; Set internal jump address after 'DON'
                        000179
397       P:0178 P:0178 0C0000            JMP     <XMT_CHK                          ; Send the command to the timing board
398    
399                             ; Come to here after timing board has signaled that clearing is done
400       P:0179 P:0179 0A0024            BSET    #STRT_EX,X:<STATUS
401       P:017A P:017A 0A0021            BSET    #ST_EX,X:<STATUS                  ; Exposure is in progress
402       P:017B P:017B 44F400            MOVE              #$010302,X0
                        010302
403       P:017D P:017D 440000            MOVE              X0,X:<HDR_ID            ; Header to device issuing 'SEX' command
404       P:017E P:017E 44F400            MOVE              #'IIA',X0               ; Rev. 1.7 voodoo command
                        494941
405       P:0180 P:0180 0C0000            JMP     <FINISH1                          ; Issue 'DON' and get next command
406    
407       P:0181 P:0181 0A0001  PAUSE     BCLR    #ST_EX,X:<STATUS                  ; Take out of exposing mode
408       P:0182 P:0182 0B00A0            JSSET   #OPT_SH,X:<OPTIONS,CSHUT          ; Close shutter if needed
                        0000F6
409       P:0184 P:0184 0C0000            JMP     <FINISH                           ; Issue 'DON' and get next command
410    
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  util2.asm  Page 8



411       P:0185 P:0185 0A0021  RESUME    BSET    #ST_EX,X:<STATUS                  ; Put in exposing mode
412       P:0186 P:0186 0B00A0            JSSET   #OPT_SH,X:<OPTIONS,OSHUT          ; Open shutter if needed
                        0000F3
413       P:0188 P:0188 0C0000            JMP     <FINISH                           ; Issue 'DON' and get next command
414    
415       P:0189 P:0189 0A0001  ABORT     BCLR    #ST_EX,X:<STATUS                  ; Take out of exposing mode
416       P:018A P:018A 448000            MOVE              X:<HDR_ID,X0            ; Save header of device issuing command
417       P:018B P:018B 4C3A00            MOVE                          X0,Y:<COM_HDR
418       P:018C P:018C 0D00F6            JSR     <CSHUT                            ; Close the shutter
419       P:018D P:018D 568000            MOVE              X:<TIMING,A
420       P:018E P:018E 565B00            MOVE              A,X:(R3)+               ; Header from Utility to timing
421       P:018F P:018F 5EB000            MOVE                          Y:<IDL,A
422       P:0190 P:0190 565B00            MOVE              A,X:(R3)+               ; Put timing board in IDLE mode
423       P:0191 P:0191 74F400            MOVE              #*+3,N4                 ; Set internal jump address after 'DON'
                        000194
424       P:0193 P:0193 0C0000            JMP     <XMT_CHK                          ; Send the command to the timing board
425       P:0194 P:0194 4CBA00            MOVE                          Y:<COM_HDR,X0
426       P:0195 P:0195 440000            MOVE              X0,X:<HDR_ID            ; Header to device issuing 'AEX' command
427       P:0196 P:0196 0C0000            JMP     <FINISH                           ; Issue 'DON' and get next command
428    
429                             ; A 'DON' reply has been received in response to a command issued by
430                             ;    the Utility board. Read the X:STATUS bits in responding to it.
431    
432                             ; Test if an internal program jump is needed after receiving a 'DON' reply
433       P:0197 P:0197 239000  PR_DONE   MOVE              N4,R0                   ; Get internal jump address
434       P:0198 P:0198 3C0000            MOVE              #<START,N4              ; Set internal jump address to default
435       P:0199 P:0199 0AE080            JMP     (R0)                              ; Jump to the internal jump address
436    
437                             ; Check for program overflow - its hard to overflow since this application
438                             ;   can be very large indeed
439                                       IF      @CVS(N,*)>APL_XY
441                                       ENDIF                                     ;  will not be overwritten
442    
443                             ; Command table resident in X: data memory
444                             ;  The last part of the command table is not defined for "bootrom"
445                             ;     because it contains application-specific commands
446    
447                                       IF      @SCP("HOST","HOST")
448       X:00C0 X:00C0                   ORG     X:COM_TBL,X:COM_TBL
449                                       ELSE                                      ; Memory offsets for generating EEPROMs
451                                       ENDIF
452       X:00C0 X:00C0                   DC      'PON',PWR_ON                      ; Power ON
453       X:00C2 X:00C2                   DC      'POF',PWR_OFF                     ; Power OFF
454       X:00C4 X:00C4                   DC      'SEX',START_EX                    ; Start exposure
455       X:00C6 X:00C6                   DC      'PEX',PAUSE                       ; Pause exposure
456       X:00C8 X:00C8                   DC      'REX',RESUME                      ; Resume exposure
457       X:00CA X:00CA                   DC      'AEX',ABORT                       ; Abort exposure
458       X:00CC X:00CC                   DC      'OSH',OPEN                        ; Open shutter
459       X:00CE X:00CE                   DC      'CSH',CLOSE                       ; Close shutter
460       X:00D0 X:00D0                   DC      'DON',PR_DONE                     ; Process DON reply
461       X:00D2 X:00D2                   DC      0,START,0,START,0,START,0,START
462       X:00DA X:00DA                   DC      0,START,0,START,0,START
463    
464                             ; Y: parameter table definitions, containing no "bootrom" definitions
465                                       IF      @SCP("HOST","HOST")
466       Y:0000 Y:0000                   ORG     Y:0,Y:0                           ; Download address
467                                       ELSE
469                                       ENDIF
470       Y:0000 Y:0000         DIG_IN    DC      0                                 ; Values of 16 digital input lines
471       Y:0001 Y:0001         DIG_OUT   DC      0                                 ; Values of 16 digital output lines
472       Y:0002 Y:0002         DAC0      DC      0                                 ; Table of four DAC values to be output
473       Y:0003 Y:0003         DAC1      DC      1000
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  util2.asm  Page 9



474       Y:0004 Y:0004         DAC2      DC      2000
475       Y:0005 Y:0005         DAC3      DC      3000
476       Y:0006 Y:0006         NUM_AD    DC      16                                ; Number of inputs to A/D converter
477       Y:0007 Y:0007         AD_IN     DC      0,0,0,0,0,0,0,0
478       Y:000F Y:000F                   DC      0,0,0,0,0,0,0,0                   ; Table of 16 A/D values
479                              EL_TIM_MSECONDS
480       Y:0017 Y:0017                   DC      0                                 ; Number of milliseconds elapsed
481       Y:0018 Y:0018         TGT_TIM   DC      6000                              ; Number of milliseconds desired in exposure
482       Y:0019 Y:0019         U_CCDT    DC      $C20                              ; Upper range of CCD temperature control loop
483       Y:001A Y:001A         L_CCDT    DC      $C50                              ; Lower range of CCD temperature control loop
484       Y:001B Y:001B         K_CCDT    DC      85                                ; Constant of proportionality for CCDT control
485       00000C                A_CCDT    EQU     AD_IN+5                           ; Address of CCD temperature in A/D table
486       Y:001C Y:001C         T_CCDT    DC      $0FFF                             ; Target CCD T for small increment algorithmn
487       Y:001D Y:001D         T_COEFF   DC      $010000                           ; Coefficient for difference in temperatures
488       Y:001E Y:001E         DAC0_LS   DC      0                                 ; Least significant part of heater voltage
489    
490                             ; Define power supply turn-on variables
491                                       IF      @SCP("R6","R6")
492       Y:001F Y:001F         T_HV      DC      $240                              ; Target HV supply voltage for Rev 6 pwr contl b
oard
493                                       ELSE
495                                       ENDIF
496       Y:0020 Y:0020         K_HV      DC      $080                              ; Tolerance of HV supply voltage
497       Y:0021 Y:0021         T_P15     DC      $5C0                              ; Target +15 volts supply voltage
498       Y:0022 Y:0022         K_P15     DC      $080                              ; Tolerance of +15 volts supply voltage
499       Y:0023 Y:0023         T_M15     DC      $A40                              ; Target -15 volts supply voltage
500       Y:0024 Y:0024         K_M15     DC      $080                              ; Tolerance of -15 volts supply voltage
501       Y:0025 Y:0025         I_HV      DC      0                                 ; Initial value of HV
502       Y:0026 Y:0026         I_P15     DC      0                                 ; Initial value of +15 volts
503       Y:0027 Y:0027         I_M15     DC      0                                 ; Initial value of -15 volts
504    
505                             ; Define some command names
506       Y:0028 Y:0028         CLR       DC      'CLR'                             ; Clear CCD
507       Y:0029 Y:0029         RDC       DC      'RDC'                             ; Readout CCD
508       Y:002A Y:002A         ABR       DC      'ABR'                             ; Abort readout
509       Y:002B Y:002B         OSH       DC      'OSH'                             ; Open shutter connected to timing board
510       Y:002C Y:002C         CSH       DC      'CSH'                             ; Close shutter connected to timing board
511       Y:002D Y:002D         POK       DC      'POK'                             ; Message to host - power in OK
512       Y:002E Y:002E         PER       DC      'PER'                             ; Message to host - ERROR in power up sequence
513       Y:002F Y:002F         SBV       DC      'SBV'                             ; Message to timing - set bias voltages
514       Y:0030 Y:0030         IDL       DC      'IDL'                             ; Message to timing - put camera in idle mode
515       Y:0031 Y:0031         STP       DC      'STP'                             ; Message to timing - Stop idling
516       Y:0032 Y:0032         CSW       DC      'CSW'                             ; Message to timing - clear switches
517    
518                             ; Miscellaneous
519       Y:0033 Y:0033         CC00      DC      $C00                              ; Maximum heater voltage so the board doesn't bu
rn up
520       Y:0034 Y:0034         SV_A1     DC      0                                 ; Save register A1 during analog processing
521       Y:0035 Y:0035         SV_SR     DC      0                                 ; Save status register during timer processing
522                              EL_TIM_FRACTION
523       Y:0036 Y:0036                   DC      0                                 ; Fraction of a millisecond of elapsed exposure 
time
524       Y:0037 Y:0037         INCR      DC      $CCCCCC                           ; Exposure time increment = 0.8 milliseconds
525       Y:0038 Y:0038         SH_DEL    DC      10                                ; Shutter closing time
526       Y:0039 Y:0039         TEMP      DC      0                                 ; Temporary storage location for X:PBD word
527       Y:003A Y:003A         COM_HDR   DC      0                                 ; Header of command being executed
528    
529                             ; During the downloading of this application program the one millisecond
530                             ;   timer interrupts are enabled, so the utility board will attempt to execute
531                             ;   the partially downloaded TIMER routine, and crash. A workaround is to
532                             ;   put a RTI as the first instruction of TIMER so it doesn't execute, then
533                             ;   write the correct instruction only after all the rest of the application
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  util2.asm  Page 10



534                             ;   program has been downloaded. Here it is -
535    
536       P:0090 P:0090                   ORG     P:APL_ADR,P:APL_ADR
537       P:0090 P:0090 0C00B2            JMP     <SERVICE                          ; Millisecond timer interrupt
538       P:0091 P:0091 053579            MOVEC                         SR,Y:<SV_SR ; Save Status Register
539    
540    
541                                ENDSEC                                    ; End of SECTION UTILAPPL
542    
543                      ; End of program
544                                END

0    Errors
0    Warnings


