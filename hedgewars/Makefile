fpc-compile: 
	ppc386 -Fl/usr/local/lib getrevnum.dpr
	./getrevnum < /dev/null > revision.inc
	ppc386 -B -Sd -Xs -OG -Or -O2 -Fl/usr/local/lib hwengine.dpr
