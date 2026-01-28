#
# Makefile
#   Universal Monitor for IM6100
#

.SUFFIXES: .asm .p .hex .sr .bin .v

devs=dev/dev_tangnano.asm

all:	unimon_im6100.hex unimon_im6100.bin unimon_im6100.v

.p.hex:
	p2hex -F Intel $*.p $*.hex

.p.sr:
	p2hex -F Moto $*.p $*.sr

.asm.p:
	asl -L -listradix 8 $*.asm

.p.bin:
	p2bin -l 0 $*.p $*.bin 

.bin.v:
	./bin2v.pl $*.bin > $*.v

config.inc:
	[ -e config.inc ] || ln -s config/config.inc config.inc

clean:
	rm -f *.p *.hex *.sr *.lst *.bin *.v
