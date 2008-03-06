all::

# Read version in from VERSION file.
HEM_VERSION := $(shell cat ../VERSION)

DOCFILES =      hem.1.txt index.txt
MANFILES =      hem.1
MANXMLFILES =   hem.1.xml
MANHTMLFILES =  hem.1.html
SITEHTMLFILES = index.html

HTMLFILES =     $(MANHTMLFILES) $(SITEHTMLFILES)

SRCS =          $(DOCFILES)
TARGETS =       $(MANFILES) $(HTMLFILES)
AUX =           $(XMLFILES)

ASCIIDOC = asciidoc --unsafe \
		     -a stylesdir=./stylesheets \
		     -a linkcss= \
		     -a theme=bare \
		     -a hem_version=$(HEM_VERSION)

A2X = a2x --xsltproc-opts='--catalogs --nonet --novalid'


man: $(MANFILES)

html: $(HTMLFILES)

doc: man html

all:: doc

$(MANFILES): %.1: %.1.txt
	$(A2X) -d manpage -f manpage -D . $<

$(MANHTMLFILES): %.1.html: %.1.txt
	$(ASCIIDOC) -d manpage $<

$(SITEHTMLFILES): %.html: %.txt
	$(ASCIIDOC) -o $@ $<

$(MANFILES) $(HTMLFILES): asciidoc.conf

$(SITEHTMLFILES): xhtml11-article.conf

clean:
	rm -rf $(HTMLFILES) $(XMLFILES) $(MANFILES)

FORCE:

.PHONY: clean manpages doc html all

# vim: set ts=8
