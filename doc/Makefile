DOCFILES = doc/hem.1.txt

XMLFILES = doc/hem.1.xml

MANFILES = man/hem.1

HTMLFILES = doc/hem.1.html

CLEAN = $(MANFILES) $(HTMLFILES) $(XMLFILES) man

DISTCLEAN = $(XMLFILES)

DISTFILES = $(BINFILES) $(DOCFILES) $(MANFILES) $(HTMLFILES)

.PHONY : all clean dist check-sh-syntax doc

all:: $(BINFILES) $(MANFILES) $(HTMLFILES)

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

# vim: set ts=8
