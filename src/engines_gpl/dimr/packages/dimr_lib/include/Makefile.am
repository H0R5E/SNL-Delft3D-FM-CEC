#-------------------------------------------------------------------------------
#   Makefile for delftflow
#
#   Irv.Elshoff@deltares.nl
#   Adri.Mourits@deltares.nl
#   Fedor.Baart@deltares.nl
#   11 jan 2007
#
#   Copyright (C)  Stichting Deltares, 2011-2013.
#-------------------------------------------------------------------------------

include $(top_srcdir)/common.am
#-------------------------------------------------------------------------------
#Includes
dist_noinst_HEADERS = \
	clock.h \
        component.h \
        dimr.h \
        exception.h \
        getopt.h \
        log.h \
        stringutils.h \
        dimr_lib_version.h \
        xmltree.h

REGENERATE_VN=yes

# (the space before ifeq is intentional to fool Automake, and leave this conditional to Make)
 ifeq ($(REGENERATE_VN),yes)
#  # We're in a working copy build dir, so always update the *version.h
dimr_lib_version.h: dimr_lib_version.h.svn ./always
        $(top_srcdir)/scripts_lgpl/linux/update_version.sh dimr_lib_version.h $(srcdir) version_number.ini $(top_builddir)
./always:
	rm -rf dimr_lib_version.h
 else
# Do not force regeneration of *version.h, because it is already shipped in a source distribution archive.
dimr_lib_version.h:
	./always:
 endif
#
#
