Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  utilboot2.asm  Page 1



1                               COMMENT *
2      
3                        This file is used to generate boot DSP code for the utility board.
4                            This is Rev. 3.00 software for use with the timII board.
5      
6                                *
7                                  PAGE    132                               ; Printronix page width - 132 columns
8      
9                        ; Define some useful DSP register locations
10        000000         RST_ISR   EQU     $00                               ; Hardware reset interrupt
11        000006         ROM_ID    EQU     $06                               ; Location of ROM Identification words = SWI interrupt
12        000008         IRQA_ISR  EQU     $08                               ; Address of ISRA for 1 kHz timer interrupts
13        00000C         SSI_ISR   EQU     $0C                               ; SSI serial receiver interrupt address
14        00000E         SSI_ERR   EQU     $0E                               ; SSI interrupt with exception (error)
15        000010         START     EQU     $10                               ; Address for beginning of code
16        000080         BUF_STR   EQU     $80                               ; Starting address of buffers in X:
17        000020         BUF_LEN   EQU     $20                               ; Length of each buffer
18        000080         SSI_BUF   EQU     BUF_STR                           ; Starting address of SSI buffer in X:
19        0000A0         COM_BUF   EQU     SSI_BUF+BUF_LEN                   ; Starting address of command buffer in X:
20        0000C0         COM_TBL   EQU     COM_BUF+BUF_LEN                   ; Starting address of command table in X:
21        000018         NUM_COM   EQU     24                                ; Number of entries in the command table
22        000682         TIMEOUT   EQU     1666                              ; Timeout for receiving complete command = 1 millisec
23        000090         APL_ADR   EQU     $90                               ; Starting address of application program
24        001EE0         APL_XY    EQU     $1EE0                             ; Start of application data tables
25        006000         RST_OFF   EQU     $6000                             ; Reset code offset in EEPROM
26        006040         P_OFF     EQU     $6040                             ; P: memory offset into EEPROM
27        006100         X_OFF     EQU     $6100                             ; X: memory offset into EEPROM
28        006200         ROM_EXE   EQU     $6200                             ; P: start address for routines that execute from EEPRO
M
29        000046         DLY_MUX   EQU     70                                ; Number of DSP cycles to delay for MUX settling
30        000064         DLY_AD    EQU     100                               ; Number of DSP cycles to delay for A/D settling
31     
32                       ; Now assign a bunch of addresses to on-chip functions
33        00FFFE         BCR       EQU     $FFFE                             ; Bus (=Port A) Control Register -> Wait States
34        00FFE0         PBC       EQU     $FFE0                             ; Port B Control Register
35        00FFE2         PBDDR     EQU     $FFE2                             ; Port B Data Direction Register
36        00FFE4         PBD       EQU     $FFE4                             ; Port B Data Register
37        00FFE1         PCC       EQU     $FFE1                             ; Port C Control Register
38        00FFE5         PCDDR     EQU     $FFE5                             ; PortC Data Direction Register
39        00FFFF         IPR       EQU     $FFFF                             ; Interrupt Priority Register
40        00FFEF         SSITX     EQU     $FFEF                             ; SSI Transmit and Receive data register
41        00FFEF         SSIRX     EQU     $FFEF                             ; SSI Transmit and Receive data register
42        00FFEE         SSISR     EQU     $FFEE                             ; SSI Status Register
43        00FFEC         CRA       EQU     $FFEC                             ; SSI Control Register A
44        00FFED         CRB       EQU     $FFED                             ; SSI Control Register B
45        000006         SSI_TDE   EQU     6                                 ; SSI Transmitter data register empty
46        000007         SSI_RDF   EQU     7                                 ; SSI Receiver data register full
47     
48                       ; Addresses of memory mapped components in Y: data memory space
49                       ;   Write addresses first
50        00FFF0         WR_DIG    EQU     $FFF0                             ; Write Digital output values D00-D15
51        00FFF1         WR_MUX    EQU     $FFF1                             ; Select MUX connected to A/D input - one of 16
52        00FFF2         EN_DIG    EQU     $FFF2                             ; Enable digital outputs
53        00FFF7         WR_DAC3   EQU     $FFF7                             ; Write to DAC#3 D00-D11
54        00FFF6         WR_DAC2   EQU     $FFF6                             ; Write to DAC#2 D00-D11
55        00FFF5         WR_DAC1   EQU     $FFF5                             ; Write to DAC#1 D00-D11
56        00FFF4         WR_DAC0   EQU     $FFF4                             ; Write to DAC#0 D00-D11
57     
58                       ; Read addresses next
59        00FFF0         RD_DIG    EQU     $FFF0                             ; Read Digital input values D00-D15
60        00FFF1         STR_ADC   EQU     $FFF1                             ; Start ADC conversion, ignore data
61        00FFF2         RD_ADC    EQU     $FFF2                             ; Read A/D converter value D00-D11
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  utilboot2.asm  Page 2



62        00FFF7         WATCH     EQU     $FFF7                             ; Watch dog timer - tell it that DSP is alive
63     
64                       ; Bit definitions of STATUS word
65        000000         ST_SRVC   EQU     0                                 ; Set if SERVICE routine needs executing
66        000001         ST_EX     EQU     1                                 ; Set if timed exposure is in progress
67        000002         ST_SH     EQU     2                                 ; Set if shutter is open
68        000003         ST_READ   EQU     3                                 ; Set if a readout needs to be initiated
69     
70                       ; Bit definitions of software OPTIONS word
71        000000         OPT_SH    EQU     0                                 ; Set to open and close shutter
72     
73                       ; Bit definitions of Port B = Host Processor Interface
74        000000         HVEN      EQU     0                                 ; Enable high voltage PS (+32V nominal) - Output
75        000001         LVEN      EQU     1                                 ; Enable low voltage PS (+/-15 volt nominal) - Output
76        000002         PWRST     EQU     2                                 ; Reset power conditioner counter - Output
77        000003         SHUTTER   EQU     3                                 ; Control shutter - Output
78        000004         IRQ_T     EQU     4                                 ; Request interrupt service from timing board - Output
79        000005         SYS_RST   EQU     5                                 ; Reset entire system - Output
80        000008         WATCH_T   EQU     8                                 ; Processed watchdog signal from timing board - Input
81        000009         PWREN     EQU     9                                 ; Enable power conditioner board - Output
82     
83                       ;**************************************************************************
84                       ;                                                                         *
85                       ;    Register assignments                                                 *
86                       ;        R1 - Address of SSI receiver contents                            *
87                       ;        R2 - Address of processed SSI receiver contents                  *
88                       ;        R3 - Pointer to current top of command buffer                    *
89                       ;        R4 - Pointer to processed contents of command buffer             *
90                       ;        N4 - Address for internal jumps after receiving 'DON' replies    *
91                       ;        R0, R5, R6, A, X0, and X1 - Freely available for program use     *
92                       ;        B, Y0, and Y1  - For use by timer ISR only                       *
93                       ;                                                                         *
94                       ;**************************************************************************
95     
96                       ; Initialize the DSP. Because this is executed only on DSP boot from ROM
97                       ;   it is not incorporated into any download code.
98     
99        P:6000 P:6000                   ORG     P:RST_OFF,P:RST_OFF
100    
101       P:6000 P:6000 0502BA            MOVEC             #$02,OMR                ; Normal expanded mode
102       P:6001 P:6001 000000            NOP                                       ; Allow time for the remapping to occur
103       P:6002 P:6002 0AF080            JMP     INIT                              ; DSP resets to $E000, but we load program
                        006004
104                                                                                 ;   to EEPROM starting at RST_OFF = $6000
105    
106       P:6004 P:6004 08F4A4  INIT      MOVEP             #$003F,X:PBD            ; Power enables off, shutter high
                        00003F
107                                                                                 ;  (closed), IRQA, SYSRST
108                                                                                 ;  LVEN = HVEN = 1 => all power off
109    
110       P:6006 P:6006 08F4A2            MOVEP             #$003F,X:PBDDR          ; H0 - H5 Outputs, H6 - H9 Inputs
                        00003F
111    
112       P:6008 P:6008 0003F8            ORI     #$03,MR                           ; Temporarily mask interrupts
113    
114       P:6009 P:6009 08F4AC            MOVEP             #$6000,X:CRA            ; SSI programming - no prescaling;
                        006000
115                                                                                 ;   24 bits/word; on-demand communications;
116                                                                                 ;   no prescale; 5.0 MHz serial clock rate
117    
118       P:600B P:600B 08F4AD            MOVEP             #$BD20,X:CRB            ; SSI programming - OF0, OF1 don't apply;
                        00BD20
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  utilboot2.asm  Page 3



119                                                                                 ;   SC0, SC1, SC2 are inputs;  SCK is output;
120                                                                                 ;   shift MSB first; rcv and xmt asynchronous
121                                                                                 ;   wrt each other; gated clock; bit frame
122                                                                                 ;   sync; network mode to get on-demand;
123                                                                                 ;   RCV and its interrupts enabled; TX enabled,
124                                                                                 ;   TX interrrupts disabled.
125    
126       P:600D P:600D 08F4A1            MOVEP             #$01C8,X:PCC            ; Port C implemented as enabling the SSI
                        0001C8
127                                                                                 ;   function of STD, SRD, SCK, and SC0.
128    
129       P:600F P:600F 08F4A5            MOVEP             #$0000,X:PCDDR          ; Data Direction register = all inputs.
                        000000
130    
131       P:6011 P:6011 08F4BE            MOVEP             #$0033,X:BCR            ; Wait states for external memory accesses
                        000033
132                                                                                 ;   2 for PROM = 150 nsec
133                                                                                 ;   2 for A/D, DAC, etc. = 150 nsec
134    
135                             ; Load boot program into P: memory from EEPROM
136       P:6013 P:6013 60F400            MOVE              #P_OFF,R0               ; Starting P: address in EEPROM
                        006040
137       P:6015 P:6015 310000            MOVE              #0,R1                   ; Put values starting at beginning of P:
138       P:6016 P:6016 069280            DO      #APL_ADR+2,P_MOVE                 ; Boot program is APL_ADR words long
                        006019
139                                                                                 ;     +2 is for SERVICE and TIMER stubs
140       P:6018 P:6018 07D88E            MOVE              P:(R0)+,A               ; Get one word from EEPROM
141       P:6019 P:6019 07598E            MOVE              A,P:(R1)+               ; Write it to DSP P: memory
142                             P_MOVE
143    
144                             ; Load X: data memory from EEPROM
145       P:601A P:601A 60F400            MOVE              #X_OFF,R0               ; Starting X: address in EEPROM
                        006100
146       P:601C P:601C 310000            MOVE              #0,R1                   ; Put values starting at beginning of X:
147       P:601D P:601D 060081            DO      #$100,X_MOVE                      ; Assume 256 = $100 values exist
                        006020
148       P:601F P:601F 07D88E            MOVE              P:(R0)+,A               ; Get one word from EEPROM
149       P:6020 P:6020 565900            MOVE              A,X:(R1)+               ; Write it to DSP X: memory
150                             X_MOVE
151    
152                             ; Initialize various registers
153       P:6021 P:6021 318000            MOVE              #SSI_BUF,R1
154       P:6022 P:6022 33A000            MOVE              #COM_BUF,R3
155       P:6023 P:6023 223200            MOVE              R1,R2
156       P:6024 P:6024 227400            MOVE              R3,R4
157       P:6025 P:6025 051FA1            MOVE              #31,M1                  ; Create circular buffers, modulo 32
158       P:6026 P:6026 0462A1            MOVE              M1,M2
159       P:6027 P:6027 0463A2            MOVE              M2,M3
160       P:6028 P:6028 0464A3            MOVE              M3,M4
161       P:6029 P:6029 3C1000            MOVE              #<START,N4
162       P:602A P:602A 200013            CLR     A
163       P:602B P:602B 20001B            CLR     B
164    
165                             ; Set interrupt priorities levels
166       P:602C P:602C 08F4BF            MOVEP             #$2007,X:IPR            ; Write to interrupt priority register
                        002007
167                                                                                 ;   SSI = 1 = link to timing board
168                                                                                 ;   IRQA = 2 = timer, negative edge trigerred
169                                                                                 ;   Host, SCI, IRQB all disabled
170       P:602E P:602E 00FCB8            ANDI    #$FC,MR                           ; Unmask all interrupt levels
171       P:602F P:602F 0C003F            JMP     <XMT_CHK
172    
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  utilboot2.asm  Page 4



173                             ;  *****  Put interrupt service routine vectors in their required places  *****
174                             ;  After RESET jump to initialization code
175       P:0000 P:6040                   ORG     P:RST_ISR,P:RST_ISR+P_OFF
176       P:0000 P:6040 0AF080            JMP     INIT                              ; This is the interrupt service for RESET
                        006004
177    
178                             ; The IRQA ISR is a long interrupt keyed to the 1 millisecond timer
179       P:0008 P:6048                   ORG     P:IRQA_ISR,P:IRQA_ISR+P_OFF
180       P:0008 P:6048 0D0091            JSR     <TIMER                            ; Jump to long TIMER routine for service
181       P:0009 P:6049 000000            NOP
182    
183                             ; This SSI interrupt service routine receives timing board data
184       P:000C P:604C                   ORG     P:SSI_ISR,P:SSI_ISR+P_OFF
185       P:000C P:604C 0859AF            MOVEP             X:SSIRX,X:(R1)+         ; Put the word in the SSI receiver buffer
186       P:000D P:604D 000000            NOP
187    
188                             ; The SSI interrupts to here when there is an error.
189       P:000E P:604E                   ORG     P:SSI_ERR,P:SSI_ERR+P_OFF
190       P:000E P:604E 0BF080            JSR     CLR_SSI
                        000084
191    
192                             ; Put the ID words for this version of the ROM code. It is placed at
193                             ;   the address of the SWI = software interrupt, which we never use.
194       P:0006 P:6046                   ORG     P:ROM_ID,P:ROM_ID+P_OFF
195       P:0006 P:6046                   DC      $000000                           ; Institution
196                                                                                 ; Location
197                                                                                 ; Instrument
198       P:0007 P:6047                   DC      $030003                           ; Version 3.00, Board #3 = Utility
199    
200                             ; Start the command interpreting code
201       P:0010 P:6050                   ORG     P:START,P:START+P_OFF
202    
203                             ; Check for TIMER interrupts and go handle them if necessary
204       P:0010 P:6050 0B00A0            JSSET   #ST_SRVC,X:STATUS,SERVICE         ; Do all millisecond service tasks
                        000090
205       P:0012 P:6052 094E37            MOVEP             Y:WATCH,A               ; Reset watchdog timer
206    
207                             ; Test SSI receiver pointers
208       P:0013 P:6053 222E00            MOVE              R1,A                    ; Pointer to current contents of receiver
209       P:0014 P:6054 224400            MOVE              R2,X0                   ; Pointer to processed contents
210       P:0015 P:6055 45E245            CMP     X0,A      X:(R2),X1               ; Are they equal? Get header
211       P:0016 P:6056 0EA035            JEQ     <TST_COM                          ; Yes, so check the receiver stack
212    
213                             ; Check candidate header = (S,D,N) for self-consistency
214       P:0017 P:6057 548A00            MOVE              X:<MASK1,A1             ; Test for S.LE.3 and D.LE.3 and N.LE.7
215       P:0018 P:6058 200066            AND     X1,A                              ; X1 = header from above
216       P:0019 P:6059 0E2020            JNE     <RCV_SKP                          ; Test failed, skip over header
217       P:001A P:605A 548B00            MOVE              X:<MASK2,A1             ; Test for S.NE.0 or D.NE.0
218       P:001B P:605B 200066            AND     X1,A
219       P:001C P:605C 0EA020            JEQ     <RCV_SKP                          ; Test failed, skip over header
220       P:001D P:605D 2C0700            MOVE              #7,A1                   ; Test for N.GE.1
221       P:001E P:605E 200066            AND     X1,A                              ; A = NWORDS in command
222       P:001F P:605F 0E2022            JNE     <RCV_PR                           ; Test suceeded - process command
223       P:0020 P:6060 205A00  RCV_SKP   MOVE              (R2)+                   ; Header is wrong - skip over it
224       P:0021 P:6061 0C0010            JMP     <START                            ; Keep monitoring receiver
225    
226                             ; Get all the words of the command before processing it
227       P:0022 P:6062 21C500  RCV_PR    MOVE              A,X1                    ; Number of words in command header
228       P:0023 P:6063 068286            DO      #<TIMEOUT,TIM_OUT
                        00002F
229       P:0025 P:6065 222E00            MOVE              R1,A
230       P:0026 P:6066 224400            MOVE              R2,X0
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  utilboot2.asm  Page 5



231       P:0027 P:6067 200044            SUB     X0,A
232       P:0028 P:6068 0E102B            JGE     <RCV_L1                           ; X1 = Destination mask $00FF00
233       P:0029 P:6069 448700            MOVE              X:<C32,X0               ; Correct for circular buffer
234       P:002A P:606A 200040            ADD     X0,A                              ; No MOVE here - it isn't always executed
235       P:002B P:606B 450265  RCV_L1    CMP     X1,A      X1,X:<NWORDS
236       P:002C P:606C 0E902F            JLT     <RCV_L2
237       P:002D P:606D 00008C            ENDDO
238       P:002E P:606E 0C0031            JMP     <MV_COM
239       P:002F P:606F 000000  RCV_L2    NOP
240                             TIM_OUT
241       P:0030 P:6070 0C0020            JMP     <RCV_SKP                          ; Increment R2 and BAD_HDR
242    
243                             ; We've got the complete SSI command, so put it on the COM_BUF stack
244       P:0031 P:6071 060200  MV_COM    DO      X:<NWORDS,SSI_WR
                        000034
245       P:0033 P:6073 56DA00            MOVE              X:(R2)+,A               ; R2 = SSI address
246       P:0034 P:6074 565B00            MOVE              A,X:(R3)+               ; R3 = command buffer address
247                             SSI_WR
248    
249                             ; Test the command stack too
250       P:0035 P:6075 226E00  TST_COM   MOVE              R3,A                    ; Pointer to current contents of receiver
251       P:0036 P:6076 228400            MOVE              R4,X0                   ; Pointer to processed contents
252       P:0037 P:6077 459145            CMP     X0,A      X:<DMASK,X1             ; Are they equal? Get destination mask
253       P:0038 P:6078 0EA010            JEQ     <START                            ; Go back to the top
254    
255                             ; Process the receiver entry - is its destination number = D_BRD_ID?
256       P:0039 P:6079 56E400            MOVE              X:(R4),A                ; Get the header ID
257       P:003A P:607A 560300            MOVE              A,X:<HDR_ID             ; Store it for later use
258       P:003B P:607B 459066            AND     X1,A      X:<DBRDID,X1            ; Extract destination byte only; Store
259       P:003C P:607C 200065            CMP     X1,A                              ; = destination number?
260       P:003D P:607D 0EA061            JEQ     <COMMAND                          ; It's a command for this board
261       P:003E P:607E 0E7073            JGT     <ERROR                            ; Destination byte > #DBRDID, so error
262    
263                             ; Check the transmitter buffer for commands to send to the timing board
264       P:003F P:607F 226E00  XMT_CHK   MOVE              R3,A
265       P:0040 P:6080 228400            MOVE              R4,X0
266       P:0041 P:6081 200045            CMP     X0,A                              ; R4 is incremented below
267       P:0042 P:6082 0EA010            JEQ     <START                            ; We're all done
268    
269                             ; Request and receive acknowledgement from the timing board
270       P:0043 P:6083 0AAE86  REQ_TIM   JCLR    #SSI_TDE,X:SSISR,*                ; SSI XMT register must be empty
                        000043
271       P:0045 P:6085 08F0AF            MOVEP             X:UTL_REQ,X:SSITX       ; Write to SSI XMIT register
                        00001B
272    
273                             ; Wait for timing board acknowledgement, on a 2 millisecond timeout
274       P:0047 P:6087 061A00            DO      X:<ACK_DLY,L_TIMEOUT
                        00004D
275       P:0049 P:6089 0BAE27            BTST    #SSI_RDF,X:SSISR
276       P:004A P:608A 0E004D            JCC     <DEC_CNT
277       P:004B P:608B 00008C            ENDDO
278       P:004C P:608C 0C0053            JMP     <RD_ACK
279       P:004D P:608D 000000  DEC_CNT   NOP
280                             L_TIMEOUT
281    
282                             ; Failed - reset the SSI and try again
283       P:004E P:608E 08F4A1            MOVEP             #$0000,X:PCC            ; Software reset the SSI
                        000000
284       P:0050 P:6090 08F4A1            MOVEP             #$01C8,X:PCC            ; Enable the SSI
                        0001C8
285       P:0052 P:6092 0C0043            JMP     <REQ_TIM
286    
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  utilboot2.asm  Page 6



287                             ; The timing board acknowledgement was received, so read it and test it
288       P:0053 P:6093 084E2F  RD_ACK    MOVEP             X:SSIRX,A
289       P:0054 P:6094 449C00            MOVE              X:<TIM_ACK,X0
290       P:0055 P:6095 200045            CMP     X0,A
291       P:0056 P:6096 0E2043            JNE     <REQ_TIM                          ; If not OK, try again
292    
293                             ; Transmit the command to the timing board over the SSI
294       P:0057 P:6097 44E400            MOVE              X:(R4),X0               ; Read the header word
295       P:0058 P:6098 54F400            MOVE              #>7,A1                  ; Extract the 3 LS bits
                        000007
296       P:005A P:609A 200046            AND     X0,A                              ; X0 = NWORDS in command
297       P:005B P:609B 06CC00            DO      A1,SSI_XMT
                        00005F
298       P:005D P:609D 0AAE86  SSI_WT2   JCLR    #SSI_TDE,X:SSISR,SSI_WT2          ; SSI XMT register must be empty
                        00005D
299       P:005F P:609F 08DCAF            MOVEP             X:(R4)+,X:SSITX         ; Write to SSI buffer
300                             SSI_XMT
301       P:0060 P:60A0 0C003F            JMP     <XMT_CHK                          ; Is there more to transmit?
302    
303                             ; Process the command - is it in the command table ?
304       P:0061 P:60A1 205C00  COMMAND   MOVE              (R4)+                   ; Increment over the header ID
305       P:0062 P:60A2 56DC00            MOVE              X:(R4)+,A               ; Get the command buffer entry
306       P:0063 P:60A3 30C000            MOVE              #<COM_TBL,R0            ; Get command table address
307       P:0064 P:60A4 061880            DO      #NUM_COM,END_COM                  ; Loop over command table
                        00006B
308       P:0066 P:60A6 44D800            MOVE              X:(R0)+,X0              ; Get the command table entry
309       P:0067 P:60A7 65E045            CMP     X0,A      X:(R0),R5               ; Are the receiver and table entries the same?
310       P:0068 P:60A8 0E206B            JNE     <NOT_COM                          ; No, keep looping
311       P:0069 P:60A9 00008C            ENDDO                                     ; Restore the DO loop system registers
312       P:006A P:60AA 0AE580            JMP     (R5)                              ; Jump execution to the command
313       P:006B P:60AB 205800  NOT_COM   MOVE              (R0)+                   ; Increment the register past the table address
314                             END_COM
315    
316                             ; Step over the remaining words in the command if there's an error
317       P:006C P:60AC 568200            MOVE              X:<NWORDS,A
318       P:006D P:60AD 448600            MOVE              X:<TWO,X0
319       P:006E P:60AE 200044            SUB     X0,A                              ; Header and command have been processed
320       P:006F P:60AF 0EA073            JEQ     <ERROR
321       P:0070 P:60B0 06CE00            DO      A,INCR_R4
                        000072
322       P:0072 P:60B2 205C00            MOVE              (R4)+                   ; Increment over unprocessed part of comamnd
323                             INCR_R4
324    
325       P:0073 P:60B3 449700  ERROR     MOVE              X:<ERR,X0               ; Send the message - there was an error
326       P:0074 P:60B4 0C0076            JMP     <FINISH1                          ; This protects against unknown commands
327    
328                             ; Command execution is nearly over - generate header and message.
329       P:0075 P:60B5 449800  FINISH    MOVE              X:<DON,X0               ; Send a DONE message as a reply
330       P:0076 P:60B6 568300  FINISH1   MOVE              X:<HDR_ID,A             ; Get header of incoming command
331       P:0077 P:60B7 459200            MOVE              X:<SMASK,X1             ; This was the source byte, and is to
332       P:0078 P:60B8 458666            AND     X1,A      X:<TWO,X1               ;   become the destination byte
333       P:0079 P:60B9 0608A0            REP     #8                                ; Shift right one byte, add it to the
334       P:007A P:60BA 450223            LSR     A         X1,X:<NWORDS            ;     header, and put 2 as the number
335       P:007B P:60BB 458F60            ADD     X1,A      X:<SBRDID,X1            ;  of words in the string
336       P:007C P:60BC 200060            ADD     X1,A
337       P:007D P:60BD 565B00            MOVE              A,X:(R3)+               ; Put header on the transmitter stack
338       P:007E P:60BE 445B00            MOVE              X0,X:(R3)+              ; Put value of X0 on the transmitter stack
339       P:007F P:60BF 0C003F            JMP     <XMT_CHK                          ; Go transmit
340    
341                             ; Delay after EEPROM write in DSP internal memory because code cannot
342                             ;   execute from EEPROM during a write operation
343       P:0080 P:60C0 060E00  DLY_ROM   DO      X:<C50000,LP_WRR
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  utilboot2.asm  Page 7



                        000082
344       P:0082 P:60C2 094E37            MOVEP             Y:WATCH,A               ; Delay 10 millisec for EEPROM write
345                             LP_WRR
346       P:0083 P:60C3 0C0075            JMP     <FINISH
347    
348                             ; Clear error condition and interrupt on SSI receiver
349       P:0084 P:60C4 0870AE  CLR_SSI   MOVEP             X:SSISR,X:RCV_ERR       ; Read SSI status register
                        000019
350       P:0086 P:60C6 0870AF            MOVEP             X:SSIRX,X:RCV_ERR       ; Read receiver register to clear error
                        000019
351       P:0088 P:60C8 000004            RTI
352    
353                             ; Check for overflow
354                                       IF      @CVS(N,*)>APL_ADR
356                                       ENDIF                                     ;  will not be overwritten
357    
358                             ; Specify the memory location where the application program is to be loaded
359       P:0090 P:60D0                   ORG     P:APL_ADR,P:APL_ADR+P_OFF
360    
361                             ; Define TIMER as a simple jump addresses so the "bootrom" program
362                             ;   can work until the application program can be loaded
363       P:0090 P:60D0 00000C  SERVICE   RTS                                       ; Just return from subroutine call
364       P:0091 P:60D1 000004  TIMER     RTI                                       ; Just return from interrupt
365    
366                             ; The following boot routines execute directly from EEPROM, one 24-bit word
367                             ;   at a time. Two reasons for this - to conserve DSP P: space, and to allow
368                             ;   reading or writing to EEPROM space that overlaps with the P: internal
369                             ;   DSP memory space.
370    
371       P:6200 P:6200                   ORG     P:ROM_EXE,P:ROM_EXE
372    
373                             ; Test Data Link - simply return value received after 'TDL'
374       P:6200 P:6200 44DC00  TDL       MOVE              X:(R4)+,X0              ; Get data value
375       P:6201 P:6201 0C0076            JMP     <FINISH1                          ; Return from executing TDL command
376    
377                             ; Its a read from DSP memory - get the data and send it over the link
378       P:6202 P:6202 60E400  RDMEM     MOVE              X:(R4),R0               ; Need the address in an address register
379       P:6203 P:6203 44DC00            MOVE              X:(R4)+,X0              ; Need address also in a 24-bit register
380       P:6204 P:6204 0AC414            JCLR    #20,X0,RDX                        ; Test address bit for Program memory
                        006208
381       P:6206 P:6206 07E084            MOVE              P:(R0),X0               ; Read from Program memory
382       P:6207 P:6207 0C0076            JMP     <FINISH1                          ; Send out a header with the value
383       P:6208 P:6208 0AC415  RDX       JCLR    #21,X0,RDY                        ; Test address bit for X: memory
                        00620C
384       P:620A P:620A 44E000            MOVE              X:(R0),X0               ; Write to X data memory
385       P:620B P:620B 0C0076            JMP     <FINISH1                          ; Send out a header with the value
386       P:620C P:620C 0AC416  RDY       JCLR    #22,X0,RDR                        ; Test address bit for Y: memory
                        006210
387       P:620E P:620E 4CE000            MOVE                          Y:(R0),X0   ; Read from Y data memory
388       P:620F P:620F 0C0076            JMP     <FINISH1                          ; Send out a header with the value
389       P:6210 P:6210 0AC417  RDR       JCLR    #23,X0,ERROR                      ; Test for read of EEPROM memory
                        000073
390       P:6212 P:6212 0503BA            MOVEC             #$03,OMR                ; Development mode - disable internal P: memory
391       P:6213 P:6213 000000            NOP
392       P:6214 P:6214 07E084            MOVE              P:(R0),X0               ; Read from EEPROM
393       P:6215 P:6215 0502BA            MOVEC             #$02,OMR                ; Normal mode - enable internal P: memory
394       P:6216 P:6216 000000            NOP
395       P:6217 P:6217 0C0076            JMP     <FINISH1
396    
397                             ; Program WRMEM - ('WRM' address datum), write to memory.
398       P:6218 P:6218 60E400  WRMEM     MOVE              X:(R4),R0               ; Get the desired address
399       P:6219 P:6219 44DC00            MOVE              X:(R4)+,X0              ; We need a 24-bit version of the address
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  utilboot2.asm  Page 8



400       P:621A P:621A 45DC00            MOVE              X:(R4)+,X1              ; Get value into X1 some MOVE works easily
401       P:621B P:621B 0AC414            JCLR    #20,X0,WRX                        ; Test address bit for Program memory
                        006223
402       P:621D P:621D 220400            MOVE              R0,X0                   ; Get 16-bit version of the address
403       P:621E P:621E 568800            MOVE              X:<C512,A               ; If address >= $200 then its an EEPROM write
404       P:621F P:621F 200045            CMP     X0,A                              ;   and a delay 10 milliseconds is needed
405       P:6220 P:6220 076085            MOVE              X1,P:(R0)               ; Write to Program memory
406       P:6221 P:6221 0EF080            JLE     <DLY_ROM                          ; Jump to delay routine if needed
407       P:6222 P:6222 0C0075            JMP     <FINISH
408       P:6223 P:6223 0AC415  WRX       JCLR    #21,X0,WRY                        ; Test address bit for X: memory
                        006227
409       P:6225 P:6225 456000            MOVE              X1,X:(R0)               ; Write to X: memory
410       P:6226 P:6226 0C0075            JMP     <FINISH
411       P:6227 P:6227 0AC416  WRY       JCLR    #22,X0,WRR                        ; Test address bit for Y: memory
                        00622B
412       P:6229 P:6229 4D6000            MOVE                          X1,Y:(R0)   ; Write to Y: memory
413       P:622A P:622A 0C0075            JMP     <FINISH
414       P:622B P:622B 0AC417  WRR       JCLR    #23,X0,ERROR                      ; Test address bit for ROM memory
                        000073
415       P:622D P:622D 0503BA            MOVE              #3,OMR                  ; Development mode - disable internal P: memory
416       P:622E P:622E 000000            NOP
417       P:622F P:622F 076085            MOVE              X1,P:(R0)               ; Write to EEPROM
418       P:6230 P:6230 0502BA            MOVE              #2,OMR                  ; Normal mode - enable internal P: memory
419       P:6231 P:6231 000000            NOP
420       P:6232 P:6232 0C0080            JMP     <DLY_ROM                          ; Delay 10 milliseconds for EEPROM write
421    
422                             ; Read EEPROM code into DSP locations starting at P:APL_ADR
423       P:6233 P:6233 0003F8  LDA       ORI     #$03,MR                           ; Temporarily mask interrupts
424       P:6234 P:6234 44DC00            MOVE              X:(R4)+,X0              ; Number of application program
425       P:6235 P:6235 568400            MOVE              X:<ZERO,A
426       P:6236 P:6236 458D45            CMP     X0,A      X:<C300,X1
427       P:6237 P:6237 0AF0AA            JEQ     LDA_0                             ; Application #0 is a special case
                        006243
428       P:6239 P:6239 4584A0            MPY     X0,X1,A   X:<ZERO,X1
429       P:623A P:623A 448922            ASR     A         X:<C1D00,X0
430       P:623B P:623B 359020            ADD     X,A       #APL_ADR,R5
431       P:623C P:623C 211000            MOVE              A0,R0                   ; EEPROM address = # x $300 + $1D00
432       P:623D P:623D 067081            DO      #$200-APL_ADR,LD_LA0              ;  Thus  ( 1 <= # <= 10 )
                        006240
433       P:623F P:623F 07D88E            MOVE              P:(R0)+,A               ; Read from EEPROM
434       P:6240 P:6240 075D8E            MOVE              A,P:(R5)+               ; Write to DSP
435                             LD_LA0
436       P:6241 P:6241 0AF080            JMP     LD_X                              ; Keep R0 value
                        00624E
437    
438                             ; Special case - application #0 can spill from internal P: DSP to EEPROM memory
439       P:6243 P:6243 309000  LDA_0     MOVE              #APL_ADR,R0
440       P:6244 P:6244 067081            DO      #$200-APL_ADR,LD_LA1
                        00624B
441       P:6246 P:6246 0503BA            MOVE              #3,OMR                  ; Development mode - disable internal P: memory
442       P:6247 P:6247 000000            NOP
443       P:6248 P:6248 07E08E            MOVE              P:(R0),A                ; Read from EEPROM
444       P:6249 P:6249 0502BA            MOVE              #2,OMR                  ; Normal mode - enable internal P: memory
445       P:624A P:624A 000000            NOP
446       P:624B P:624B 07588E            MOVE              A,P:(R0)+               ; Write to DSP
447                             LD_LA1
448    
449                             ; Load in the application command table into X:CMD_TBL
450       P:624C P:624C 60F400            MOVE              #APL_XY,R0
                        001EE0
451       P:624E P:624E 35C000  LD_X      MOVE              #COM_TBL,R5
452       P:624F P:624F 062080            DO      #32,LD_LA2                        ; 16 application commands
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  utilboot2.asm  Page 9



                        006252
453       P:6251 P:6251 07D88E            MOVE              P:(R0)+,A
454       P:6252 P:6252 565D00            MOVE              A,X:(R5)+
455                             LD_LA2
456    
457                             ; Load the Y: data memory contents
458       P:6253 P:6253 350000            MOVE              #0,R5                   ; Start at bottom of Y: memory
459       P:6254 P:6254 060081            DO      #$100,LD_LA3                      ; Read from EEPROM and write
                        006257
460       P:6256 P:6256 07D88E            MOVE              P:(R0)+,A               ;   them to Y: memory
461       P:6257 P:6257 5E5D00            MOVE                          A,Y:(R5)+
462                             LD_LA3
463       P:6258 P:6258 00FCB8            ANDI    #$FC,MR                           ; Unmask interrupts
464       P:6259 P:6259 0C0075            JMP     <FINISH                           ; Send 'DON' message
465    
466                             ; Parameter definitions in X: memory space
467       X:0000 P:6100                   ORG     X:0,P:X_OFF
468       X:0000 P:6100         STATUS    DC      0                                 ; Status word
469       X:0001 P:6101         OPTIONS   DC      0                                 ; Software options
470       X:0002 P:6102         NWORDS    DC      0                                 ; Number of words in destination command packet
471       X:0003 P:6103         HDR_ID    DC      0                                 ; 24-bit header containing board ID's
472    
473                             ; Constant definitions, useful for saving program memory space
474       X:0004 P:6104         ZERO      DC      0
475       X:0005 P:6105         ONE       DC      1
476       X:0006 P:6106         TWO       DC      2
477       X:0007 P:6107         C32       DC      32
478       X:0008 P:6108         C512      DC      512                               ; Boundary between DSP and EEPROM P: memory
479       X:0009 P:6109         C1D00     DC      $1D00                             ; Offset for loading application programs
480       X:000A P:610A         MASK1     DC      $FCFCF8                           ; Mask for checking header ID
481       X:000B P:610B         MASK2     DC      $030300                           ; Mask for checking header ID
482       X:000C P:610C         CFFF      DC      $FFF                              ; Mask for 12-bit A/D converter
483       X:000D P:610D         C300      DC      $300                              ; Constant for resetting the DSP
484       X:000E P:610E         C50000    DC      50000                             ; Delay for +/- 15v and EEPROM settling
485       X:000F P:610F         SBRDID    DC      $030000                           ; Source Identification number
486       X:0010 P:6110         DBRDID    DC      $000300                           ; Destination Identification number
487       X:0011 P:6111         DMASK     DC      $00FF00                           ; Mask to get destination board number out
488       X:0012 P:6112         SMASK     DC      $FF0000                           ; Mask to get source board number out
489       X:0013 P:6113         VME       DC      $030102                           ; Header to VME interface board
490       X:0014 P:6114         HOST      DC      $030002                           ; Header to host computer
491       X:0015 P:6115         TIMING    DC      $030202                           ; Header to timing board
492       X:0016 P:6116         UTIL      DC      $030302                           ; Header to utility board
493       X:0017 P:6117         ERR       DC      'ERR'                             ; For sending error messages
494       X:0018 P:6118         DON       DC      'DON'                             ; For sending completion messages
495       X:0019 P:6119         RCV_ERR   DC      0                                 ; Dummy location for receiver clearing
496       X:001A P:611A         ACK_DLY   DC      $1000                             ; Delay to receive acknowledgment from timing bo
ard
497                                                                                 ;   of 2 milliseconds
498    
499                             ; Miscellaneous
500       X:001B P:611B         UTL_REQ   DC      $555555                           ; Word for utility requesting SSI service
501       X:001C P:611C         TIM_ACK   DC      $AAAAAA                           ; Word for timing acknowledging SSI service
502    
503                             ; The last part of the command table is not defined for "bootrom"
504                             ;  The command table is resident in X: data memory; 32 entries maximum
505       X:00C0 P:61C0                   ORG     X:COM_TBL,P:COM_TBL+X_OFF
506       X:00C0 P:61C0                   DC      0,START,0,START,0,START,0,START   ; This is where application
507       X:00C8 P:61C8                   DC      0,START,0,START,0,START,0,START   ;    commands go
508       X:00D0 P:61D0                   DC      0,START,0,START,0,START,0,START
509       X:00D8 P:61D8                   DC      0,START,0,START,0,START,0,START
510       X:00E0 P:61E0                   DC      'TDL',TDL                         ; Test Data Link
511       X:00E2 P:61E2                   DC      'RDM',RDMEM                       ; Read DSP or EEPROM memory
Motorola DSP56000 Assembler  Version 6.3.0   112-08-19  10:38:34  utilboot2.asm  Page 10



512       X:00E4 P:61E4                   DC      'WRM',WRMEM                       ; Write DSP or EEPROM memory
513       X:00E6 P:61E6                   DC      'LDA',LDA                         ; Load application program from EEPROM
514       X:00E8 P:61E8                   DC      'ERR',START                       ; Do nothing
515       X:00EA P:61EA                   DC      0,START,0,START,0,START
516    
517                             ; End of program
518                                       END

0    Errors
0    Warnings


