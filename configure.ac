AC_INIT([Hem], [0.3.3], [r@tomayko.com], [hem])
AC_CONFIG_SRCDIR([README])

AC_ARG_WITH([autossh],
  [AS_HELP_STRING([--with-autossh], [install autossh with hem])],
  [],
  [with_autossh=no])

# Checks for programs.
AC_PROG_GREP
AC_PROG_FGREP
AC_PROG_MKDIR_P
AC_PROG_SED
AC_PROG_INSTALL

AC_PATH_PROG([SSH], [ssh])
AC_PATH_PROG([PERL], [perl])
AC_PATH_PROG([AUTOSSH], [autossh])

AC_CONFIG_FILES([Makefile doc/Makefile])

if test "X$with_autossh" != Xno; then
	AC_CONFIG_SUBDIRS([autossh])
fi

AC_OUTPUT
