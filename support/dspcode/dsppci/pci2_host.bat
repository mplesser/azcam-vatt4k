rem Create .lod file for Gen 2 PCI board
rem MPL 01Jan06

rem Directories - change as needed
set ROOT=\azcam\systems\MotorolaDSPTools\
set ROOT3=%ROOT%CLAS563\BIN\
set ROOT0=%ROOT%CLAS56\BIN\

%ROOT3%asm56300 -b -lpci2boot.ls -d DOWNLOAD HOST -d MASTER TIMING pci2boot.asm

%ROOT3%dsplnk -b pci2.cld -v pci2boot.cln

del pci2boot.cln

%ROOT3%cldlod pci2.cld > pci2.lod

del pci2.cld

pause
