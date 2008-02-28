PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
NAME = hem
VERS = 0.1

install = install
mkdir = mkdir -p
tar = gnutar

BINFILES = $(NAME) $(NAME)-init $(NAME)-info $(NAME)-up \
		   $(NAME)-down $(NAME)-bounce $(NAME)-status $(NAME)-config.sh
DOCFILES = doc/$(NAME).1.txt
XMLFILES = doc/$(NAME).1.xml
MANFILES = man/$(NAME).1
HTMLFILES = doc/$(NAME).1.html
CLEAN = $(MANFILES) $(HTMLFILES) $(XMLFILES) man
DISTCLEAN = $(XMLFILES)
DISTFILES = $(BINFILES) $(DOCFILES) $(MANFILES) $(HTMLFILES)

.PHONY : all clean dist check-sh-syntax doc

all: $(BINFILES) $(MANFILES) $(HTMLFILES)

dist: dist/$(NAME)-$(VERS).tar.gz

dist/$(NAME)-$(VERS).tar.gz: $(DISTFILES)
	$(mkdir) dist
	$(tar) cvzf $@ $(DISTFILES)

check-sh-syntax: $(BINFILES)
	for f in $(BINFILES) ; do bash -t $f ; done

doc: $(MANFILES) $(HTMLFILES)

manpages: man $(MANFILES)

man:
	mkdir -p man

$(MANFILES): man/%.1: doc/%.1.txt man
	a2x -d manpage -f manpage -D man $<

$(HTMLFILES): %.1.html: %.1.txt
	asciidoc -d manpage $<

clean:
	rm -rf $(CLEAN)

distclean:
	rm -rf $(DISTCLEAN)

FORCE:
