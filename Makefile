# $DragonFly: src/nrelease/Makefile,v 1.25 2005/02/17 12:22:24 joerg Exp $
#

ISODIR ?= /usr/release
ISOFILE ?= ${ISODIR}/dfly.iso
ISOROOT = ${ISODIR}/root
OBJSYS= ${.OBJDIR}/../sys
KERNCONF ?= GENERIC

# Specify which packages are required on the ISO, and let the user
# specify additional packages to include.  During the `pkgaddiso'
# target, the packages are obtained from PACKAGES_LOC.
#
REQ_PACKAGES= cdrtools-2.0.3_3 cvsup-without-gui-16.1h
REL_PACKAGES?= ${REQ_PACKAGES} ${EXTRA_PACKAGES}
.if defined(PACKAGES)
PACKAGES_LOC?= ${PACKAGES}/All
.else
PACKAGES_LOC?= /usr/ports/packages/All
.endif

# Specify which root skeletons are required, and let the user include
# their own.  They are copied into ISODIR during the `pkgcustomizeiso'
# target; each overwrites the last.
#
REQ_ROOTSKELS= ${.CURDIR}/root
ROOTSKELS?= ${REQ_ROOTSKELS} ${EXTRA_ROOTSKELS}

# note: we use the '${NRLOBJDIR}/nrelease' construct, that is we add
# the additional '/nrelease' manually, as a safety measure.
#
NRLOBJDIR?= /usr/obj

WORLD_CCVER ?= ${CCVER}
KERNEL_CCVER ?= ${CCVER}

#########################################################################
#				BASE ISO TARGETS 			#
#########################################################################

release:	check clean buildworld1 buildkernel1 \
		buildiso customizeiso pkgaddiso mkiso

quickrel:	check clean buildworld2 buildkernel2 \
		buildiso customizeiso pkgaddiso mkiso

realquickrel:	check clean \
		buildiso customizeiso pkgaddiso mkiso

#########################################################################
#			ISO TARGETS WITH INSTALLER			#
#########################################################################

INSTALLER_PKGS= libaura-1.0 libdfui-2.0 libinstaller-2.0 \
		dfuibe_installer-1.1.2 dfuife_curses-1.1 \
		thttpd-notimeout-2.24 dfuife_cgi-1.1
INSTALLER_SKELS= installer

INSTALLER_ENV= EXTRA_PACKAGES="${INSTALLER_PKGS} ${EXTRA_PACKAGES}" \
		EXTRA_ROOTSKELS="${INSTALLER_SKELS} ${EXTRA_ROOTSKELS}"

installer_check:
		@${INSTALLER_ENV} ${MAKE} check

installer_fetchpkgs:
		@${INSTALLER_ENV} ${MAKE} fetchpkgs

installer_release:
		${INSTALLER_ENV} ${MAKE} release

installer_quickrel:
		${INSTALLER_ENV} ${MAKE} quickrel

installer_realquickrel:
		${INSTALLER_ENV} ${MAKE} realquickrel

#########################################################################
#				HELPER TARGETS				#
#########################################################################

check:
	@if [ ! -f /usr/local/bin/mkisofs ]; then \
		echo "You need to install the sysutils/cdrtools port for"; \
		echo "this target"; \
		exit 1; \
	fi
.for PKG in ${REL_PACKAGES}
	@if [ ! -f ${PACKAGES_LOC}/${PKG}.tgz ]; then \
		echo "Unable to find ${PACKAGES_LOC}/${PKG}.tgz.  This is"; \
		echo "typically accomplished by cd'ing into the appropriate"; \
		echo "port and typing 'make installer_fetchpkgs'"; \
		echo ""; \
		echo "If you are trying to build the installer, the"; \
		echo "required packages can be obtained from:"; \
		echo "http://www.bsdinstaller.org/packages/"; \
		exit 1; \
	fi
.endfor
	@echo "check: all preqs found"

fetchpkgs:
.for PKG in ${REL_PACKAGES}
	@if [ ! -f ${PACKAGES_LOC}/${PKG}.tgz ]; then \
		cd ${PACKAGES_LOC} && \
		echo "fetching ${PKG}..." && \
		fetch http://www.bsdinstaller.org/packages/${PKG}.tgz; \
	fi
.endfor

buildworld1:
	( cd ${.CURDIR}/..; CCVER=${WORLD_CCVER} make buildworld )

buildworld2:
	( cd ${.CURDIR}/..; CCVER=${WORLD_CCVER} make -DNOTOOLS -DNOCLEAN buildworld )

buildkernel1:
	( cd ${.CURDIR}/..; CCVER=${KERNEL_CCVER} make buildkernel KERNCONF=${KERNCONF} )

buildkernel2:
	( cd ${.CURDIR}/..; CCVER=${KERNEL_CCVER} make -DNOCLEAN buildkernel KERNCONF=${KERNCONF} )

# note that we do not want to mess with any /usr/obj directories not related
# to buildworld, buildkernel, or nrelease, so we must supply the proper
# MAKEOBJDIRPREFIX for targets that are not run through the buildworld and 
# buildkernel mechanism.
#
buildiso:
	if [ ! -d ${ISOROOT} ]; then mkdir -p ${ISOROOT}; fi
	if [ ! -d ${NRLOBJDIR}/nrelease ]; then mkdir -p ${NRLOBJDIR}/nrelease; fi
	( cd ${.CURDIR}/..; make DESTDIR=${ISOROOT} installworld )
	( cd ${.CURDIR}/../etc; MAKEOBJDIRPREFIX=${NRLOBJDIR}/nrelease make DESTDIR=${ISOROOT} distribution )
	cpdup ${ISOROOT}/etc ${ISOROOT}/etc.hdd
	( cd ${.CURDIR}/..; make DESTDIR=${ISOROOT} \
		installkernel KERNCONF=${KERNCONF} )
	ln -s kernel ${ISOROOT}/kernel.BOOTP
	mtree -deU -f ${.CURDIR}/../etc/mtree/BSD.local.dist -p ${ISOROOT}/usr/local/
	mtree -deU -f ${.CURDIR}/../etc/mtree/BSD.var.dist -p ${ISOROOT}/var
	dev_mkdb -f ${ISOROOT}/var/run/dev.db ${ISOROOT}/dev

customizeiso:
.for ROOTSKEL in ${ROOTSKELS}
	cpdup -X cpignore -o ${ROOTSKEL} ${ISOROOT}
.endfor
	rm -rf `find ${ISOROOT} -type d -name CVS -print`
	rm -rf ${ISOROOT}/usr/local/share/pristine
	pwd_mkdb -p -d ${ISOROOT}/etc ${ISOROOT}/etc/master.passwd

pkgcleaniso:
	rm -f ${ISOROOT}/tmp/chrootscript
	echo "#!/bin/sh" > ${ISOROOT}/tmp/chrootscript
.for PKG in ${REL_PACKAGES}
	echo "pkg_delete -f ${PKG}" >> ${ISOROOT}/tmp/chrootscript
.endfor
	chmod a+x ${ISOROOT}/tmp/chrootscript
	chroot ${ISOROOT}/ /tmp/chrootscript || exit 0
	rm ${ISOROOT}/tmp/chrootscript

pkgaddiso:
	rm -f ${ISOROOT}/tmp/chrootscript
	echo "#!/bin/sh" > ${ISOROOT}/tmp/chrootscript
.for PKG in ${REL_PACKAGES}
	cp ${PACKAGES_LOC}/${PKG}.tgz ${ISOROOT}/tmp/${PKG}.tgz
	echo "echo 'Installing package ${PKG}...'" >> ${ISOROOT}/tmp/chrootscript
	echo "pkg_add /tmp/${PKG}.tgz" >> ${ISOROOT}/tmp/chrootscript
.endfor
	chmod a+x ${ISOROOT}/tmp/chrootscript
	chroot ${ISOROOT}/ /tmp/chrootscript
	rm ${ISOROOT}/tmp/chrootscript
.for PKG in ${REL_PACKAGES}
	rm -f ${ISOROOT}/tmp/${PKG}.tgz
.endfor

mkiso:
	( cd ${ISOROOT}; mkisofs -b boot/cdboot -no-emul-boot \
		-R -J -V DragonFly -o ${ISOFILE} . )

clean:
	if [ -d ${ISOROOT} ]; then chflags -R noschg ${ISOROOT}; fi
	if [ -d ${ISOROOT} ]; then rm -rf ${ISOROOT}/*; fi
	if [ -d ${NRLOBJDIR}/nrelease ]; then rm -rf ${NRLOBJDIR}/nrelease; fi

realclean:	clean
	rm -rf ${OBJSYS}/${KERNCONF}

.include <bsd.prog.mk>
