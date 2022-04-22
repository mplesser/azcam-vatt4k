; parallels_rev

; define default states
; PDEF is frame or frame+image parallel clocks state during serial transfer
; QDEF is image clocks state during serial transfer, if FT


	DC	CLK2+P_DELAY+SDEF+P1H+P2L+P3H+Q1H+Q2L+Q3H
	DC	CLK2+P_DELAY+SDEF+P1L+P2L+P3H+Q1L+Q2L+Q3H
	DC	CLK2+P_DELAY+SDEF+P1L+P2H+P3H+Q1L+Q2H+Q3H
	DC	CLK2+P_DELAY+SDEF+P1L+P2H+P3L+Q1L+Q2H+Q3L
	DC	CLK2+P_DELAY+SDEF+P1H+P2H+P3L+Q1H+Q2H+Q3L
	DC	CLK2+P_DELAY+SDEF+P1H+P2L+P3L+Q1H+Q2L+Q3L

