all::

# Read version in from VERSION file.
HEM_VERSION := $(shell cat ../VERSION)

DOCFILES =   hem.1.txt
XMLFILES =   hem.1.xml
MANFILES =   hem.1
HTMLFILES =  hem.1.html

SRCS =       $(DOCFILES)
TARGETS =    $(MANFILES) $(HTMLFILES)
INTERS =     $(XMLFILES)

ASCIIDOC = asciidoc --unsafe \
		            -a stylesdir=$(shell pwd)/stylesheets \
		            -a theme=bare \
		            -a hem_version=$(HEM_VERSION)

A2X = a2x --xsltproc-opts='--catalogs --nonet --novalid'

man: $(MANFILES)

html: $(HTMLFILES)

doc: man html

all:: doc

$(MANFILES): %.1: %.1.txt
	$(A2X) -d manpage -f manpage -D . $<

$(HTMLFILES): %.1.html: %.1.txt
	$(ASCIIDOC) -d manpage -f manpage.conf $<

$(MANFILES) $(HTMLFILES): asciidoc.conf

clean:
	rm -rf $(MANFILES) $(HTMLFILES) $(XMLFILES)

FORCE:

.PHONY: clean manpages doc html all

# vim: set ts=8
