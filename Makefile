.PHONY: DEFAULT

DEFAULT:
	cat Makefile

README: lib/SSS.pm
	pod2readme lib/SSS.pm

clean:
	rm README*

install:
	install -m 0644 ./lib/SSS.pm /usr/lib/perl5
