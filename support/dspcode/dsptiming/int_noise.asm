; CDS integrate on noise
		DC	VIDS+%1110111  		; Stop resetting integrator
     	   	DC	VIDS+%1110111  		; Delay for Pgnal to settle
		DC	VIDEO+DWELL+%0000111	; Integrate noise
		DC	VIDS+%0011011  		; Stop Integrate, switch POL
