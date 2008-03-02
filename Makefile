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
	BASH = $(shell test -x /usr/local/bin/bash && echo "/usr/local/bin/bash")
endif

ifeq ($(uname_S),Darwin)
	BASH = /bin/sh
	SHELL_PATH = $(BASH)
endif

ifeq ($(uname_S),SunOS)
	BASH = /bin/bash
	SHELL_PATH = $(BASH)
	INSTALL = ginstall
	TAR = gtar
endif

ifeq ($(uname_S),Linux)
endif

ifneq ($(findstring $(MAKEFLAGS),s),s)
ifndef V
	QUIET_SH       = @echo '   ' SH $@;
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
SCRIPT_SH = \
	hem-bounce.sh \
	hem-down.sh \
	hem-info.sh \
	hem-init.sh \
	hem-push-keys.sh \
	hem-sh-setup.sh \
	hem-status.sh \
	hem-up.sh

SCRIPTS = $(patsubst %.sh,%,$(SCRIPT_SH))

PROGRAM_SH = hem.sh
PROGRAMS = $(patsubst %.sh,%,$(PROGRAM_SH))

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

DOCFILES = README INSTALL VERSION

install: all
	$(INSTALL) -d -m 755 '$(DESTDIR)$(bindir)'
	$(INSTALL) -d -m 755 '$(DESTDIR)$(libexecdir)'
	$(INSTALL) $(SCRIPTS) '$(DESTDIR)$(libexecdir)'
	$(INSTALL) $(PROGRAMS) '$(DESTDIR)$(bindir)'
	$(INSTALL) -d -m 755 '$(DESTDIR)$(docdir)'
	$(INSTALL) $(DOCFILES) '$(DESTDIR)$(docdir)'

# ---- PACKAGING AND DIST TARGETS ----

DIST_TAR_GZ = hem-$(HEM_VERSION).tar.gz

DISTFILES = \
	$(SCRIPT_SH) $(PROGRAM_SH) \
	$(DOCFILES) \
	Makefile

$(DIST_TAR_GZ): $(SCRIPTS)
	$(TAR) czf $@ $(DISTFILES)

dist: $(DIST_TAR_GZ)


# ---- MISC TARGETS ----

# make all repeatedly (useful for development)
auto:
	@while true ; do $(MAKE) | grep -v 'Nothing to be done' ; sleep 1 ; done

clean:
	$(RM) $(SCRIPTS)
	$(RM) $(patsubst %.sh,%+,$(SCRIPT_SH))
	$(RM) $(DIST_TAR_GZ)

config:
	@echo prefix = $(prefix)
	@echo perl = $(PERL)
	@echo BUILD_AUTOSSH = $(BUILD_AUTOSSH)

.PHONY : all clean dist install auto config

FORCE:

# vim: set ts=8
