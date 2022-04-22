rem Create .lod file for utility board
rem MPL 01Jan06
rem Directories - change as needed
set ROOT=\azcam\MotorolaDSPTools\
set ROOT3=%ROOT%CLAS563\BIN\
set ROOT0=%ROOT%CLAS56\BIN\
%ROOT0%asm56000 -b -lutilboot2.ls utilboot2.asm
%ROOT0%asm56000 -b -lutil2.ls -d DOWNLOAD HOST -d POWER R6 util2.asm 
%ROOT0%dsplnk -b util2.cld -v utilboot2.cln util2.cln
rem del util2.lod
del utilboot2.cln
del util2.cln
%ROOT0%cldlod util2.cld > util2.lod
del util2.cld
pause
