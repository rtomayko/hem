# The default target...
all::

# Modify these on the command line or directly in this file to install things
# somewhere else.
prefix = $(HOME)
bindir = $(prefix)/bin
libexecdir = $(bindir)
sharedir = $(prefix)/share
mandir = $(sharedir)/man
docdir = $(sharedir)/doc/hem

export prefix bindir libexecdir sharedir mandir htmldir

SHELL = /bin/sh
RM = rm -f
TAR = tar
FIND = find
INSTALL = install
SHELL_PATH = /bin/sh
PERL = perl
SSH = ssh
AUTOSSH = autossh

# ---- END OF CONFIGURATION ----

# Figure out a bit about the system ...
uname_S := $(shell sh -c 'uname -s 2>/dev/null || echo not')

# Read version in from VERSION file.
HEM_VERSION := $(shell cat VERSION)

# ---- PLATFORM TWEAKS ----

ifeq ($(uname_S),FreeBSD)
endif

ifeq ($(uname_S),Darwin)
	SHELL_PATH = $(BASH)
endif

ifeq ($(uname_S),SunOS)
	SHELL_PATH = $(BASH)
	INSTALL = ginstall
	TAR = gtar
endif

ifeq ($(uname_S),Linux)
endif

ifneq ($(findstring $(MAKEFLAGS),s),s)
ifndef V
	Q              = @
	QUIET_SH       = @echo '   ' SH $@;
	QUIET_GEN      = @echo '   ' GEN $@;
	QUIET_TEST     = @echo '   ' TEST;
	QUIET_TAR      = @echo '   ' TAR $@;$(TAR)
	QUIET_SUBDIR0  = +@subdir=
	QUIET_SUBDIR1  = ;$(NO_SUBDIR) echo '   ' SUBDIR $$subdir; \
			 $(MAKE) $(PRINT_DIR) -C $$subdir
	export V
	export QUIET_GEN
endif
endif

# bring in configure generated make stuff if present
-include config.mak

# These are all currently installed to $(bindir) but the hem-XXX scripts will
# probably move to a libexec directory, eventually.
SCRIPT_SH =  hem-bounce.sh hem-down.sh \
             hem-info.sh hem-init.sh hem-list.sh \
             hem-manage.sh hem-push-keys.sh hem-sh-setup.sh \
             hem-status.sh hem-up.sh
PROGRAM_SH = hem.sh
SCRIPTS =    $(patsubst %.sh,%,$(SCRIPT_SH))
PROGRAMS =   $(patsubst %.sh,%,$(PROGRAM_SH))
SRCS =       $(SCRIPT_SH) $(PROGRAM_SH)
AUX =        Makefile configure work-sh test-sh
DOCFILES =   README INSTALL VERSION COPYING


all:: $(SCRIPTS) $(PROGRAMS)

# Build all hem-XXX scripts by substituting build time variables and
#
$(SCRIPTS) $(PROGRAMS): % : %.sh
	$(QUIET_SH)$(RM) $@ $@+ && \
	sed -e '1s|#!.*/sh|#!$(SHELL_PATH)|' \
	    -e 's|@@HEM_VERSION@@|$(HEM_VERSION)|g' \
	    -e 's|@@HEM_EXEC_DIR@@|$(libexecdir)|g' \
	    $@.sh >$@+ && \
	chmod +x $@+ && \
	chmod -w $@+ && \
	mv $@+ $@ && \
	sh -n $@

$(SCRIPTS) $(PROGRAMS): config.mak Makefile

# ---- INSTALL TARGETS ----


install: all
	$(INSTALL) -d -m 755 '$(DESTDIR)$(bindir)'
	$(INSTALL) -d -m 755 '$(DESTDIR)$(libexecdir)'
	$(INSTALL) $(SCRIPTS) '$(DESTDIR)$(libexecdir)'
	$(INSTALL) $(PROGRAMS) '$(DESTDIR)$(bindir)'
	$(INSTALL) -d -m 755 '$(DESTDIR)$(docdir)'
	$(INSTALL) $(DOCFILES) '$(DESTDIR)$(docdir)'

uninstall:
	$(RM) $(foreach f,$(SCRIPTS),$(DESTDIR)$(libexecdir)/$(f)) \
	      $(foreach f,$(PROGRAMS),$(DESTDIR)$(bindir)/$(f)) \
	      $(foreach f,$(DOCFILES),$(DESTDIR)$(docdir)/$(f))
	-rmdir $(DESTDIR)/$(docdir)

# ---- PACKAGING AND DIST TARGETS ----

HEM_TAR_NAME = hem-$(HEM_VERSION)

$(HEM_TAR_NAME).tar.gz: $(SRCS) $(DOCFILES) $(AUX)
	$(Q)-rm -rf $(HEM_TAR_NAME)
	$(Q)-mkdir $(HEM_TAR_NAME)
	$(Q)ln $(SRCS) $(DOCFILES) $(AUX) $(HEM_TAR_NAME)
	$(QUIET_TAR) czf $@ $(HEM_TAR_NAME)
	$(Q)rm -rf $(HEM_TAR_NAME)

$(HEM_TAR_NAME).cksums: $(HEM_TAR_NAME).tar.gz
	$(QUIET_GEN)cksums $(HEM_TAR_NAME).tar.gz > $@

dist: $(HEM_TAR_NAME).tar.gz $(HEM_TAR_NAME).cksums

release: $(HEM_TAR_NAME).tar.gz $(HEM_TAR_NAME).cksums
	$(Q)ssh tomayko.com "mkdir -p /dist/hem"
	$(Q)rsync -aP $(HEM_TAR_NAME).tar.gz $(HEM_TAR_NAME).cksums \
	  tomayko.com:/dist/hem/

# ---- TESTING ----

test.out: $(SCRIPTS) $(PROGRAMS) test-sh
	$(QUIET_TEST) sh test-sh

test: test.out

# ---- MISC TARGETS ----

# make all repeatedly (useful for development)
auto:
	@while true ; do \
	  $(MAKE) test | grep -v 'Nothing to be done' ; \
	  sleep 1 ; \
	done

clean:
	$(Q)$(RM) $(SCRIPTS)
	$(Q)$(RM) $(PROGRAMS)
	$(Q)$(RM) $(patsubst %.sh,%+,$(SCRIPT_SH))
	$(Q)$(RM) test.out test.stdout test.stderr
	$(Q)$(RM) -r test

distclean: clean
	$(Q)$(RM) $(HEM_TAR_NAME)
	$(Q)$(RM) $(HEM_TAR_NAME).tar.gz

config:
	@echo prefix = $(prefix)
	@echo perl = $(PERL)
	@echo BUILD_AUTOSSH = $(BUILD_AUTOSSH)

.PHONY : all clean dist install uninstall auto config test

FORCE:

# vim: set ts=8
