; CDS integrate on signal
		DC	VIDS+%0011011  		; Delay for Pgnal to settle
		DC	VIDEO+DWELL+%0001011	; Integrate signal
		DC	VIDS+%0011011  		; Stop integrate, clamp, reset, A/D is sampling
