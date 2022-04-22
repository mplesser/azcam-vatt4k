rem Create .lod file for Gen2 timing board
set DSPROOT= \AzCam\MotorolaDSPTools\MotorolaDSPTools\
set ROOT3= %DSPROOT%CLAS563\BIN\
set ROOT0= %DSPROOT%CLAS56\BIN\
%ROOT0%asm56000 -b -ltim2_boot.ls tim2_boot.asm
%ROOT0%asm56000 -b -ltim2.ls -d DOWNLOAD HOST tim2.asm
%ROOT0%dsplnk -b tim2.cld -v tim2_boot.cln tim2.cln 
del tim2_boot.cln
del tim2.cln
%ROOT0%cldlod tim2.cld > tim2.lod
del tim2.cld

rem pause
