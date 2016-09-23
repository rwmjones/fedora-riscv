# Refer to the README file to understand how Fedora on RISC-V is
# bootstrapped.

# Absolute path to the current directory.
ROOT := $(shell pwd)

# You can set STAGE3_DISK in your environment in order to
# use multiple disks for doing builds of different packages
# in parallel.  eg.
# export STAGE3_DISK=systemd-disk.img
# make stage3   # builds systemd-disk.img
# make boot-stage3-in-qemu  # boots systemd-disk.img
STAGE3_DISK ?= stage3-disk.img

# Note these are chosen very specifically to ensure the different
# versions work together.  Don't blindly update to the latest
# versions.  See also:
# https://github.com/riscv/riscv-pk/issues/18#issuecomment-206115996
RISCV_QEMU_COMMIT               = 94f5eb73091fb4fe272db3e943f173ecc0f78ffd
RISCV_QEMU_SHORTCOMMIT          = 94f5eb73
RISCV_FESVR_COMMIT              = 0f34d7ad311f78455a674224225f5b3056efba1d
RISCV_FESVR_SHORTCOMMIT         = 0f34d7ad
RISCV_ISA_SIM_COMMIT            = 3bfc00ef2a1b1f0b0472a39a866261b00f67027e
RISCV_ISA_SIM_SHORTCOMMIT       = 3bfc00ef
RISCV_GNU_TOOLCHAIN_COMMIT      = 728afcddcb0526a0f6560c4032da82805f054d58
RISCV_GNU_TOOLCHAIN_SHORTCOMMIT = 728afcdd
RISCV_PK_COMMIT                 = 85ae17aa149b9ea114bdd70cc30ea7e73813fb48
RISCV_PK_SHORTCOMMIT            = 85ae17aa

# For the correct versions, see
# riscv-gnu-toolchain/Makefile.in *_version variables
BINUTILS_VERSION = 2.25.1
GLIBC_VERSION    = 2.22
GCC_VERSION      = 5.3.0
NEWLIB_VERSION   = 2.2.0

# https://github.com/riscv/riscv-linux
KERNEL_VERSION   = 4.1.26
KERNEL_BRANCH    = linux-4.1.y-riscv

# A local copy of Linux git repo so you don't have to keep downloading
# git commits (optional).
LOCAL_LINUX_GIT_COPY = $(HOME)/d/linux

# The root packages (plus their dependencies) that we want to in the
# stage 3 chroot.  This must include all the cross-compiled packages
# below, and may also include any noarch package we like.
STAGE3_PACKAGES = iso-codes \
ncurses-devel readline-devel bash coreutils gmp-devel \
mpfr-devel libmpc-devel binutils gcc gcc-c++ util-linux tar \
gzip zlib-devel file-devel popt-devel beecrypt-devel \
rpm rpm-build rpm-devel libdb-utils libdb-devel nano \
grep less strace bzip2-devel make diffutils findutils \
sed patch hostname gettext-devel lua-devel xz-devel gawk \
vim screen m4 flex bison autoconf automake elfutils \
git

# Versions of cross-compiled packages.
NCURSES_VERSION    = 6.0-20160910
READLINE_VERSION   = 6.3
BASH_VERSION       = 4.3
COREUTILS_VERSION  = 8.25
GMP_VERSION        = 6.1.1
MPFR_VERSION       = 3.1.4
MPC_VERSION        = 1.0.3
BINUTILS_X_VERSION = 2.27
GCC_X_VERSION      = 6.1.0
UTIL_LINUX_VERSION = 2.28
TAR_VERSION        = 1.29
GZIP_VERSION       = 1.8
ZLIB_VERSION       = 1.2.8
# Needs to match the version of 'file' installed (on host), otherwise:
#   "Cannot use the installed version of file (xx) to cross-compile file yy"
# Also note that 5.25 is definitely broken (segfaults in libmagic:magic_close).
FILE_VERSION       = 5.28
POPT_VERSION       = 1.16
BEECRYPT_VERSION   = 4.2.1
RPM_COMMIT         = 95712183458748ea6cafebac1bdd5daa097d9bee
RPM_SHORT_COMMIT   = 9571218
BDB_VERSION        = 4.5.20
NANO_VERSION       = 2.6.2
GREP_VERSION       = 2.25
LESS_VERSION       = 481
STRACE_COMMIT      = 4b69c4736cb9b44e0bd7bef16f7f8602b5d2f113
STRACE_SHORT_COMMIT = 4b69c473
BZIP2_VERSION      = 1.0.6
MAKE_VERSION       = 4.1
DIFFUTILS_VERSION  = 3.4
FINDUTILS_VERSION  = 4.6.0
SED_VERSION        = 4.2
PATCH_VERSION      = 2.7.5
HOSTNAME_VERSION   = 3.15
GETTEXT_VERSION    = 0.19.8
LUA_VERSION        = 5.3.3
XZ_VERSION         = 5.2.2
GAWK_VERSION       = 4.1.3
VIM_VERSION        = 7.4
SCREEN_VERSION     = 4.4.0
M4_VERSION         = 1.4.17
FLEX_VERSION       = 2.6.0
BISON_VERSION      = 3.0.4
AUTOCONF_VERSION   = 2.69
AUTOMAKE_VERSION   = 1.15
ELFUTILS_VERSION   = 0.166
GIT_VERSION        = 2.9.3
JSONCPP_VERSION    = 1.7.4

# There is no Tiny DNF (tdnf) RPM in Fedora, so we build our own
# starting from this version:
TDNF_VERSION       = 1.0.9

# When building the clean stage4, we don't have to build noarch RPMs,
# we can just download them from Koji (the Fedora build system).
#
# To construct this list, run:
#
# supermin -v -v -v --prepare -o /tmp/supermin.d $(STAGE3_PACKAGES) >&/tmp/log
#
# then find the full list of packages near the end of the log file,
# and cut out only the noarch packages.  Convert the names to source
# package names.  Some noarch packages can be dropped from this list
# if they are judged unnecessary, or if they pull in too many arch-ful
# dependencies.
STAGE4_KOJI_NOARCH_NAMES = \
	autoconf-archive \
	basesystem \
	ca-certificates \
	crypto-policies \
	elfutils \
	fedora-release \
	fedora-repos \
	fontawesome-fonts \
	fontawesome-fonts-web \
	fontpackages \
	fpc-srpm-macros \
	gettext \
	ghc-srpm-macros \
	gnat-srpm-macros \
	go-srpm-macros \
	help2man \
	intltool \
	iso-codes \
	lato-fonts \
	ncurses \
	ocaml-srpm-macros \
	perl-Archive-Tar \
	perl-Archive-Zip \
	perl-B-Debug \
	perl-CPAN \
	perl-CPAN-Meta \
	perl-CPAN-Meta-Requirements \
	perl-CPAN-Meta-YAML \
	perl-Carp \
	perl-Config-Perl-V \
	perl-Devel-CheckLib \
	perl-Digest \
	perl-Env \
	perl-Error \
	perl-Exporter \
	perl-ExtUtils-CBuilder \
	perl-ExtUtils-Command \
	perl-ExtUtils-Install \
	perl-ExtUtils-MM-Utils \
	perl-ExtUtils-MakeMaker \
	perl-ExtUtils-Manifest \
	perl-ExtUtils-ParseXS \
	perl-Fedora-VSP \
	perl-File-Fetch \
	perl-File-HomeDir \
	perl-File-Path \
	perl-File-Temp \
	perl-Filter-Simple \
	perl-Getopt-Long \
	perl-HTTP-Tiny \
	perl-IO-Compress \
	perl-IO-Socket-IP \
	perl-IPC-Cmd \
	perl-IPC-System-Simple \
	perl-JSON-PP \
	perl-Locale-Codes \
	perl-Locale-Maketext \
	perl-Math-BigInt \
	perl-Module-Load \
	perl-Module-Load-Conditional \
	perl-Module-Metadata \
	perl-Params-Check \
	perl-Perl-OSType \
	perl-PerlIO-via-QuotedPrint \
	perl-Pod-Escapes \
	perl-Pod-Parser \
	perl-Pod-Perldoc \
	perl-Pod-Simple \
	perl-Pod-Usage \
	perl-Term-ANSIColor \
	perl-Term-Cap \
	perl-Test-Harness \
	perl-Test-Simple \
	perl-Text-Balanced \
	perl-Text-Diff \
	perl-Text-Glob \
	perl-Text-ParseWords \
	perl-Text-Tabs+Wrap \
	perl-Text-Unidecode \
	perl-Thread-Queue \
	perl-Time-Local \
	perl-URI \
	perl-Unicode-EastAsianWidth \
	perl-autodie \
	perl-constant \
	perl-experimental \
	perl-generators \
	perl-libnet \
	perl-local-lib \
	perl-parent \
	perl-perlfaq \
	perl-podlators \
	perl-srpm-macros \
	publicsuffix-list \
	python-docutils \
	python-pip \
	python-pygments \
	python-rpm-macros \
	python-setuptools \
	python-sphinx \
	python-sphinx-locale \
	python2-imagesize \
	python2-mock \
	python2-snowballstemmer \
	python2-sphinx \
	python2-sphinx-theme-alabaster \
	python2-sphinx_rtd_theme \
	python3-babel \
	python3-docutils \
	python3-funcsigs \
	python3-imagesize \
	python3-mock \
	python3-pbr \
	python3-pygments \
	python3-snowballstemmer \
	python3-sphinx \
	python3-sphinx \
	python3-sphinx-theme-alabaster \
	python3-sphinx_rtd_theme \
	rpmdevtools \
	setup \
	sgml-common \
	tzdata \
	words

STAGE4_KOJI_FEDORA_RELEASE = f25

all: stage1 stage2 stage3 stage4

clean:
	find -name '*~' -delete
	rm -f stamp-*
	rm -f */*.spec
	rm -f fixed-gcc/*
	rm -f stage3-kernel/linux-$(KERNEL_VERSION)/vmlinux
	rm -rf stage3-chroot
	rm -f $(STAGE3_DISK)
	rm -f stage4-disk.img

# Stage 1

stage1: stage1-riscv-qemu/riscv-qemu-$(RISCV_QEMU_SHORTCOMMIT).tar.gz \
	stage1-riscv-qemu/riscv-qemu.spec \
	stamp-riscv-qemu-installed \
	stage1-riscv-fesvr/riscv-fesvr-$(RISCV_FESVR_SHORTCOMMIT).tar.gz \
	stage1-riscv-fesvr/riscv-fesvr.spec \
	stamp-riscv-fesvr-installed \
	stage1-riscv-isa-sim/riscv-isa-sim-$(RISCV_ISA_SIM_SHORTCOMMIT).tar.gz \
	stage1-riscv-isa-sim/riscv-isa-sim.spec \
	stamp-riscv-isa-sim-installed

stage1-riscv-qemu/riscv-qemu-$(RISCV_QEMU_SHORTCOMMIT).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t 'https://github.com/riscv/riscv-qemu/archive/$(RISCV_QEMU_COMMIT)/riscv-qemu-$(RISCV_QEMU_SHORTCOMMIT).tar.gz'
	mv $@-t $@

stage1-riscv-qemu/riscv-qemu.spec: stage1-riscv-qemu/riscv-qemu.spec.in
	sed -e 's/@COMMIT@/$(RISCV_QEMU_COMMIT)/g' \
	    -e 's/@SHORTCOMMIT@/$(RISCV_QEMU_SHORTCOMMIT)/g' \
	    < $^ > $@-t
	mv $@-t $@

stamp-riscv-qemu-installed:
	rm -f $@
	@rpm -q riscv-qemu >/dev/null || { \
	  echo "ERROR: You must install riscv-qemu:"; \
	  echo; \
	  echo "       dnf copr enable rjones/riscv"; \
	  echo "       dnf install riscv-qemu"; \
	  echo; \
	  echo "OR: you can build it yourself from the stage1-riscv-qemu directory."; \
	  echo; \
	  exit 1; \
	}
	@qemu-system-riscv --version || { \
	  echo "ERROR: qemu-system-riscv is not working."; \
	  echo "Make sure you installed the riscv-qemu package."; \
	  exit 1; \
	}
	touch $@

stage1-riscv-fesvr/riscv-fesvr-$(RISCV_FESVR_SHORTCOMMIT).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t 'https://github.com/riscv/riscv-fesvr/archive/$(RISCV_FESVR_COMMIT)/riscv-fesvr-$(RISCV_FESVR_SHORTCOMMIT).tar.gz'
	mv $@-t $@

stage1-riscv-fesvr/riscv-fesvr.spec: stage1-riscv-fesvr/riscv-fesvr.spec.in
	sed -e 's/@COMMIT@/$(RISCV_FESVR_COMMIT)/g' \
	    -e 's/@SHORTCOMMIT@/$(RISCV_FESVR_SHORTCOMMIT)/g' \
	    < $^ > $@-t
	mv $@-t $@

stamp-riscv-fesvr-installed:
	rm -f $@
	@rpm -q riscv-fesvr >/dev/null || { \
	  echo "ERROR: You must install riscv-fesvr:"; \
	  echo; \
	  echo "       dnf copr enable rjones/riscv"; \
	  echo "       dnf install riscv-fesvr"; \
	  echo; \
	  echo "OR: you can build it yourself from the stage1-riscv-fesvr directory."; \
	  echo; \
	  exit 1; \
	}
	touch $@

stage1-riscv-isa-sim/riscv-isa-sim-$(RISCV_ISA_SIM_SHORTCOMMIT).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t 'https://github.com/riscv/riscv-isa-sim/archive/$(RISCV_ISA_SIM_COMMIT)/riscv-isa-sim-$(RISCV_ISA_SIM_SHORTCOMMIT).tar.gz'
	mv $@-t $@

stage1-riscv-isa-sim/riscv-isa-sim.spec: stage1-riscv-isa-sim/riscv-isa-sim.spec.in
	sed -e 's/@COMMIT@/$(RISCV_ISA_SIM_COMMIT)/g' \
	    -e 's/@SHORTCOMMIT@/$(RISCV_ISA_SIM_SHORTCOMMIT)/g' \
	    < $^ > $@-t
	mv $@-t $@

stamp-riscv-isa-sim-installed:
	rm -f $@
	@rpm -q riscv-isa-sim >/dev/null || { \
	  echo "ERROR: You must install riscv-isa-sim:"; \
	  echo; \
	  echo "       dnf copr enable rjones/riscv"; \
	  echo "       dnf install riscv-isa-sim"; \
	  echo; \
	  echo "OR: you can build it yourself from the stage1-riscv-isa-sim directory."; \
	  echo; \
	  exit 1; \
	}
	touch $@

# Stage 2

stage2: stage2-riscv-gnu-toolchain/riscv-gnu-toolchain-$(RISCV_GNU_TOOLCHAIN_SHORTCOMMIT).tar.gz \
	stage2-riscv-gnu-toolchain/binutils-$(BINUTILS_VERSION).tar.gz \
	stage2-riscv-gnu-toolchain/gcc-$(GCC_VERSION).tar.gz \
	stage2-riscv-gnu-toolchain/glibc-$(GLIBC_VERSION).tar.gz \
	stage2-riscv-gnu-toolchain/newlib-$(NEWLIB_VERSION).tar.gz \
	stage2-riscv-gnu-toolchain/riscv-gnu-toolchain.spec \
	stamp-riscv-gnu-toolchain-installed \
	fixed-gcc/riscv64-unknown-linux-gnu-cc \
	fixed-gcc/riscv64-unknown-linux-gnu-gcc \
	fixed-gcc/riscv64-unknown-linux-gnu-c++ \
	fixed-gcc/riscv64-unknown-linux-gnu-g++ \
	stage2-riscv-pk/riscv-pk-$(RISCV_PK_SHORTCOMMIT).tar.gz \
	stage2-riscv-pk/riscv-pk.spec \
	stamp-riscv-pk-installed

stage2-riscv-gnu-toolchain/riscv-gnu-toolchain-$(RISCV_GNU_TOOLCHAIN_SHORTCOMMIT).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t https://github.com/lowRISC/riscv-gnu-toolchain/archive/$(RISCV_GNU_TOOLCHAIN_COMMIT)/riscv-gnu-toolchain-$(RISCV_GNU_TOOLCHAIN_SHORTCOMMIT).tar.gz
	mv $@-t $@

stage2-riscv-gnu-toolchain/binutils-$(BINUTILS_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://mirrors.kernel.org/gnu/binutils/binutils-$(BINUTILS_VERSION).tar.gz
	mv $@-t $@

# GCC 5 no longer compiles with GCC 6 unless we patch it.
# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=69959
stage2-riscv-gnu-toolchain/gcc-$(GCC_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://mirrors.kernel.org/gnu/gcc/gcc-$(GCC_VERSION)/gcc-$(GCC_VERSION).tar.gz
	zcat $@-t | tar xf -
	cd gcc-$(GCC_VERSION) && patch -p0 < ../stage2-riscv-gnu-toolchain/gcc-5-fix-compilation-with-gcc-6.patch
	tar zcf $@-t gcc-$(GCC_VERSION)
	rm -r gcc-$(GCC_VERSION)
	mv $@-t $@

stage2-riscv-gnu-toolchain/glibc-$(GLIBC_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://mirrors.kernel.org/gnu/glibc/glibc-$(GLIBC_VERSION).tar.gz
	mv $@-t $@

stage2-riscv-gnu-toolchain/newlib-$(NEWLIB_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t ftp://sourceware.org/pub/newlib/newlib-$(NEWLIB_VERSION).tar.gz
	mv $@-t $@

stage2-riscv-gnu-toolchain/riscv-gnu-toolchain.spec: stage2-riscv-gnu-toolchain/riscv-gnu-toolchain.spec.in
	sed -e 's/@COMMIT@/$(RISCV_GNU_TOOLCHAIN_COMMIT)/g' \
	    -e 's/@SHORTCOMMIT@/$(RISCV_GNU_TOOLCHAIN_SHORTCOMMIT)/g' \
	    -e 's/@BINUTILS_VERSION@/$(BINUTILS_VERSION)/g' \
	    -e 's/@GCC_VERSION@/$(GCC_VERSION)/g' \
	    -e 's/@GLIBC_VERSION@/$(GLIBC_VERSION)/g' \
	    -e 's/@NEWLIB_VERSION@/$(NEWLIB_VERSION)/g' \
	    < $^ > $@-t
	mv $@-t $@

stamp-riscv-gnu-toolchain-installed:
	rm -f $@
	@rpm -q riscv-gnu-toolchain >/dev/null || { \
	  echo "ERROR: You must install riscv-gnu-toolchain:"; \
	  echo; \
	  echo "       dnf copr enable rjones/riscv"; \
	  echo "       dnf install riscv-gnu-toolchain"; \
	  echo; \
	  echo "OR: you can build it yourself from the stage2-riscv-gnu-toolchain directory."; \
	  echo; \
	  exit 1; \
	}
	@riscv64-unknown-elf-gcc --version || { \
	  echo "ERROR: riscv64-unknown-elf-gcc (cross compiler) is not working."; \
	  echo "Make sure you installed the riscv-gnu-toolchain package."; \
	  exit 1; \
	}
	touch $@

# The versions of riscv64-unknown-linux-{gcc,g++} in the
# riscv-gnu-toolchain RPM are (possibly) broken in that they require an
# explicit --sysroot parameter.
#
# Work around that by setting $PATH to contain fixed-gcc subdirectory.
#
# Note this should only be used when building stage3.
fixed-gcc/riscv64-unknown-linux-gnu-cc:
	mkdir -p fixed-gcc
	echo '/usr/bin/riscv64-unknown-linux-gnu-gcc --sysroot=$(ROOT)/stage3-chroot "$$@"' > $@
	chmod 0755 $@

fixed-gcc/riscv64-unknown-linux-gnu-gcc:
	mkdir -p fixed-gcc
	echo '/usr/bin/riscv64-unknown-linux-gnu-gcc --sysroot=$(ROOT)/stage3-chroot "$$@"' > $@
	chmod 0755 $@

fixed-gcc/riscv64-unknown-linux-gnu-c++:
	mkdir -p fixed-gcc
	echo '/usr/bin/riscv64-unknown-linux-gnu-g++ --sysroot=$(ROOT)/stage3-chroot "$$@"' > $@
	chmod 0755 $@

fixed-gcc/riscv64-unknown-linux-gnu-g++:
	mkdir -p fixed-gcc
	echo '/usr/bin/riscv64-unknown-linux-gnu-g++ --sysroot=$(ROOT)/stage3-chroot "$$@"' > $@
	chmod 0755 $@

stage2-riscv-pk/riscv-pk-$(RISCV_PK_SHORTCOMMIT).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t https://github.com/lowRISC/riscv-pk/archive/$(RISCV_PK_COMMIT)/riscv-pk-$(RISCV_PK_SHORTCOMMIT).tar.gz
	mv $@-t $@

stage2-riscv-pk/riscv-pk.spec: stage2-riscv-pk/riscv-pk.spec.in
	sed -e 's/@COMMIT@/$(RISCV_PK_COMMIT)/g' \
	    -e 's/@SHORTCOMMIT@/$(RISCV_PK_SHORTCOMMIT)/g' \
	    < $^ > $@-t
	mv $@-t $@

stamp-riscv-pk-installed:
	rm -f $@
	@rpm -q riscv-pk >/dev/null || { \
	  echo "ERROR: You must install riscv-pk:"; \
	  echo; \
	  echo "       dnf copr enable rjones/riscv"; \
	  echo "       dnf install riscv-pk"; \
	  echo; \
	  echo "OR: you can build it yourself from the stage2-riscv-pk directory."; \
	  echo; \
	  exit 1; \
	}
	touch $@

# Stage 3

stage3: stage3-kernel/linux-$(KERNEL_VERSION)/vmlinux \
	stage3-chroot-original/etc/fedora-release \
	stage3-chroot/etc/fedora-release \
	stage3-chroot/lib64/libc.so.6 \
	stage3-chroot/usr/include/asm/ptrace.h \
	stage3-chroot/usr/bin/tic \
	stage3-chroot/usr/lib64/libhistory.so.6 \
	stage3-chroot/bin/bash \
	stage3-chroot/bin/ls \
	stage3-chroot/usr/lib64/libgmp.so.10 \
	stage3-chroot/usr/lib64/libmpfr.so.4 \
	stage3-chroot/usr/lib64/libmpc.so.3 \
	stage3-chroot/usr/bin/as \
	stage3-chroot/usr/bin/gcc \
	stage3-chroot/usr/lib64/libstdc++.so \
	stage3-chroot/usr/lib64/libgomp.so \
	stage3-chroot/usr/lib64/libatomic.so \
	stage3-chroot/usr/bin/mount \
	stage3-chroot/usr/bin/tar \
	stage3-chroot/usr/bin/gzip \
	stage3-chroot/usr/lib64/libz.so \
	stage3-chroot/usr/bin/file \
	stage3-chroot/usr/lib64/libpopt.so \
	stage3-chroot/usr/lib64/libbeecrypt.so \
	stage3-chroot/usr/bin/nano \
	stage3-chroot/usr/bin/grep \
	stage3-chroot/usr/bin/less \
	stage3-chroot/usr/bin/strace \
	stage3-chroot/usr/bin/bzip2 \
	stage3-chroot/usr/bin/make \
	stage3-chroot/usr/bin/diff \
	stage3-chroot/usr/bin/find \
	stage3-chroot/usr/bin/sed \
	stage3-chroot/usr/bin/patch \
	stage3-chroot/usr/bin/hostname \
	stage3-chroot/usr/bin/gettext \
	stage3-chroot/usr/bin/lua \
	stage3-chroot/usr/bin/xz \
	stage3-chroot/usr/bin/eu-readelf \
	stage3-chroot/usr/bin/rpm \
	stage3-chroot/usr/bin/gawk \
	stage3-chroot/usr/bin/vim \
	stage3-chroot/usr/bin/screen \
	stage3-chroot/usr/bin/m4 \
	stage3-chroot/usr/bin/flex \
	stage3-chroot/usr/bin/bison \
	stage3-chroot/usr/bin/poweroff \
	stage3-chroot/usr/bin/autoconf \
	stage3-chroot/usr/bin/automake \
	stage3-chroot/usr/bin/git \
	stage3-chroot/usr/lib64/libjsoncpp.so \
	stage3-chroot/etc/profile.d/aliases.sh \
	stage3-chroot/usr/lib/rpm/config.guess \
	stage3-chroot/usr/lib/rpm/config.sub \
	stage3-chroot/rpmbuild \
	stage3-chroot/rpmbuild/RPMS/noarch/kernel-headers-$(KERNEL_VERSION)-1.fc25.noarch.rpm \
	stage3-tdnf/tdnf-$(TDNF_VERSION)-1.fc25.src.rpm \
	stage3-chroot/etc/yum.repos.d/local.repo \
	$(STAGE3_DISK)

stage3-kernel/linux-$(KERNEL_VERSION)/vmlinux: linux-$(KERNEL_VERSION).tar.xz
	rm -rf stage3-kernel/linux-$(KERNEL_VERSION)
	cd stage3-kernel && tar -Jxf ../$^
	cd stage3-kernel/linux-$(KERNEL_VERSION) && \
	git init && \
	git remote add -t $(KERNEL_BRANCH) origin https://github.com/riscv/riscv-linux.git && \
	( git remote add local $(LOCAL_LINUX_GIT_COPY); git fetch local; : ) && \
	git fetch && \
	git checkout -f -t origin/$(KERNEL_BRANCH)
	cd stage3-kernel/linux-$(KERNEL_VERSION) && \
	make mrproper
# So we can build with ARCH=riscv64:
# https://github.com/palmer-dabbelt/riscv-gentoo-infra/blob/master/patches/linux/0001-riscv64_makefile.patch
	cd stage3-kernel/linux-$(KERNEL_VERSION) && \
	patch -p1 < ../0001-riscv64_makefile.patch
# Fix infinite loop when clearing memory
# https://github.com/riscv/riscv-linux/commit/77148ef248f72bb96b5cacffc0a69bca445de214
	cd stage3-kernel/linux-$(KERNEL_VERSION) && \
	patch -p1 < ../0001-Fix-infinite-loop-in-__clear_user.patch
	cd stage3-kernel/linux-$(KERNEL_VERSION) && \
	make ARCH=riscv64 defconfig
	( \
	echo CONFIG_CMDLINE=\"root=/dev/htifblk0 init=/init\"; \
	echo CONFIG_CROSS_COMPILE=riscv64-unknown-elf-; \
	echo CONFIG_FILE_LOCKING=y; \
	echo CONFIG_NET_CORE=y; \
	echo CONFIG_NETDEVICES=y; \
	echo CONFIG_VIRTIO=y; \
	echo CONFIG_VIRTIO_MMIO=y; \
	echo CONFIG_VIRTIO_MMIO_CMDLINE_DEVICES=y; \
	echo CONFIG_VIRTIO_NET=y; \
	echo CONFIG_VIRTIO_BLK=y; \
	echo CONFIG_VIRTIO_CONSOLE=y; \
	echo CONFIG_SCSI_VIRTIO=y; \
	echo CONFIG_SYSFS=y; \
	echo CONFIG_BLK_DEV=y; \
	echo CONFIG_BLK_DEV_LOOP=y; \
	echo CONFIG_EXT4_FS=y; \
	) >> stage3-kernel/linux-$(KERNEL_VERSION)/.config
	cd stage3-kernel/linux-$(KERNEL_VERSION) && \
	make ARCH=riscv64 olddefconfig
	cd stage3-kernel/linux-$(KERNEL_VERSION) && \
	$(MAKE) ARCH=riscv64 vmlinux
	cd stage3-kernel/linux-$(KERNEL_VERSION) && \
	make ARCH=riscv64 headers_install INSTALL_HDR_PATH=$(ROOT)/stage3-chroot/usr
	ls -l $@

linux-$(KERNEL_VERSION).tar.xz:
	rm -f $@ $@-t
	wget -O $@-t https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-$(KERNEL_VERSION).tar.xz
	mv $@-t $@

# Build the phony kernel-headers RPM.
stage3-chroot/rpmbuild/RPMS/noarch/kernel-headers-$(KERNEL_VERSION)-1.fc25.noarch.rpm: stage3-kernel/linux-$(KERNEL_VERSION)/vmlinux
	rm -rf kernel-headers
	mkdir -p kernel-headers/usr
	cd stage3-kernel/linux-$(KERNEL_VERSION) && \
	make ARCH=riscv64 headers_install INSTALL_HDR_PATH=$(ROOT)/kernel-headers/usr
	sed -e 's,@ROOT@,$(ROOT),g' -e 's,@KERNEL_VERSION@,$(KERNEL_VERSION),g' < kernel-headers.spec.in > kernel-headers.spec
	mkdir -p stage3-chroot/rpmbuild/RPMS/noarch
	rpmbuild -ba kernel-headers.spec --define "_topdir $(ROOT)/stage3-chroot/rpmbuild"
	rm -rf kernel-headers

# Tiny DNF, not in Fedora.
stage3-tdnf/tdnf-$(TDNF_VERSION)-1.fc25.src.rpm: stage3-tdnf/tdnf.spec stage3-tdnf/tdnf-$(TDNF_VERSION).tar.gz
	rm -f $@
	cd stage3-tdnf && rpmbuild -bs --define "_sourcedir `pwd`" --define "_srcrpmdir `pwd`" tdnf.spec

stage3-tdnf/tdnf.spec: stage3-tdnf/tdnf.spec.in
	rm -f $@ $@-t
	sed 's/@TDNF_VERSION@/$(TDNF_VERSION)/g' < $^ > $@-t
	mv $@-t $@

stage3-tdnf/tdnf-$(TDNF_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t https://github.com/vmware/tdnf/archive/v$(TDNF_VERSION).tar.gz
	mv $@-t $@

# Build an original (x86-64) chroot using supermin.  We then aim to
# rebuild (using cross-compiled versions) every ELF binary in this
# chroot.
stage3-chroot-original/etc/fedora-release:
	rm -rf stage3-chroot-original-t stage3-chroot-original tmp-supermin.d
	supermin --prepare $(STAGE3_PACKAGES) -o tmp-supermin.d
	supermin --build -f chroot tmp-supermin.d -o stage3-chroot-original-t
	rm -r tmp-supermin.d
	mv stage3-chroot-original-t stage3-chroot-original
	@echo -n "Total files in chroot: "
	@find stage3-chroot-original -type f | wc -l
	@echo -n "ELF files to be rebuilt: "
	@find stage3-chroot-original -type f | xargs file -N | grep -E '\bELF.*LSB\b' | wc -l

# Copy the original chroot to the final chroot, remove all the ELF
# files.
stage3-chroot/etc/fedora-release: stage3-chroot-original/etc/fedora-release
	rm -rf stage3-chroot-t stage3-chroot
	cp -a stage3-chroot-original stage3-chroot-t
	find stage3-chroot-t -type d -print0 | xargs -0 chmod u+w
	find stage3-chroot-t -type f -print0 | xargs -0 chmod u+w
	find stage3-chroot-t -type f -print0 | xargs -0 file -N | grep -E '\bELF.*LSB\b' | awk -F: '{print $$1}' | xargs rm -f
	rm -f stage3-chroot-t/lib64/libc.so.6
	mv stage3-chroot-t stage3-chroot
	rm -f stage3-chroot/usr/include/asm/ptrace.h

# Copy in compiled glibc from the riscv-gnu-toolchain sysroot.  Only
# copy files and symlinks, leave the target directory structure
# intact.
stage3-chroot/lib64/libc.so.6:
	mkdir -p stage3-chroot/usr/lib/audit
	mkdir -p stage3-chroot/usr/lib/gconv
	for f in `cd /usr/sysroot && find -type f -o -type l`; do \
	    cp -d /usr/sysroot/$$f stage3-chroot/$$f; \
	done
	cd stage3-chroot/lib64 && for f in ../lib/*; do ln -sf $$f; done
	rm -f stage3-chroot/usr/include/asm/ptrace.h

# Copy in the correct Linux header files.
stage3-chroot/usr/include/asm/ptrace.h: stage3-kernel/linux-$(KERNEL_VERSION)/vmlinux
	cd stage3-kernel/linux-$(KERNEL_VERSION) && \
	make ARCH=riscv64 headers_install INSTALL_HDR_PATH=$(ROOT)/stage3-chroot/usr

# Cross-compile ncurses.
stage3-chroot/usr/bin/tic: ncurses-$(NCURSES_VERSION).tgz
	tar zxf $^
	cd ncurses-$(NCURSES_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64 \
	    --with-shared \
	    --with-termlib=tinfo \
	    --enable-widec
	cd ncurses-$(NCURSES_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd ncurses-$(NCURSES_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH make install DESTDIR=$(ROOT)/stage3-chroot

ncurses-$(NCURSES_VERSION).tgz:
	rm -f $@ $@-t
	wget -O $@-t ftp://invisible-island.net/ncurses/current/ncurses-$(NCURSES_VERSION).tgz
	mv $@-t $@

# Cross-compile readline.
stage3-chroot/usr/lib64/libhistory.so.6: readline-$(READLINE_VERSION).tar.gz
	tar zxf $^
	cd readline-$(READLINE_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	bash_cv_wcwidth_broken=no \
	./configure --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd readline-$(READLINE_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd readline-$(READLINE_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot
	rm -f stage3-chroot/usr/lib64/*.la

readline-$(READLINE_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t ftp://ftp.gnu.org/gnu/readline/readline-$(READLINE_VERSION).tar.gz
	mv $@-t $@

# Cross-compile bash.
stage3-chroot/bin/bash: bash-$(BASH_VERSION).tar.gz
	tar zxf $^
	cd bash-$(BASH_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd bash-$(BASH_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd bash-$(BASH_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

bash-$(BASH_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t ftp://ftp.gnu.org/gnu/bash/bash-$(BASH_VERSION).tar.gz
	mv $@-t $@

# Cross-compile coreutils.  Bleah, coreutils cross-compilation is
# known-broken and upstream don't care, hence the 'touch' command.

COREUTILS_PROGRAMS = arch base32 base64 basename cat chcon chgrp chmod chown chroot cksum comm cp csplit cut date dd df dir dircolors dirname du echo env expand expr factor false fmt fold ginstall groups head hostid hostname id install join kill link ln logname ls md5sum mkdir mkfifo mknod mktemp mv nice nl nohup nproc numfmt od paste pathchk pinky pr printenv printf ptx pwd readlink realpath rm rmdir runcon seq sha1sum sha224sum sha256sum sha384sum sha512sum shred shuf sleep sort split stat stdbuf stty sum sync tac tail tee test timeout touch tr true truncate tsort tty uname unexpand uniq unlink uptime users vdir wc who whoami yes

stage3-chroot/bin/ls: coreutils-$(COREUTILS_VERSION).tar.xz
	rm -rf coreutils-$(COREUTILS_VERSION)
	tar Jxf $^
	cd coreutils-$(COREUTILS_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	-cd coreutils-$(COREUTILS_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH make -j1 -k
	cd coreutils-$(COREUTILS_VERSION)/man && \
	for f in $(COREUTILS_PROGRAMS); do touch $$f.1; done
	cd coreutils-$(COREUTILS_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd coreutils-$(COREUTILS_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

coreutils-$(COREUTILS_VERSION).tar.xz:
	rm -f $@ $@-t
	wget -O $@-t ftp://ftp.gnu.org/gnu/coreutils/coreutils-$(COREUTILS_VERSION).tar.xz
	mv $@-t $@

# Cross-compile binutils.
stage3-chroot/usr/bin/as: binutils-$(BINUTILS_X_VERSION).tar.gz
# This file coming from host glibc-headers breaks the build.
	rm -f stage3-chroot/usr/include/proc_service.h
	rm -rf riscv-binutils-gdb-riscv-binutils-$(BINUTILS_X_VERSION)
	zcat $^ | tar xf -
	mkdir riscv-binutils-gdb-riscv-binutils-$(BINUTILS_X_VERSION)/build
	cd riscv-binutils-gdb-riscv-binutils-$(BINUTILS_X_VERSION)/build && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	../configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd riscv-binutils-gdb-riscv-binutils-$(BINUTILS_X_VERSION)/build && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd riscv-binutils-gdb-riscv-binutils-$(BINUTILS_X_VERSION)/build && make DESTDIR=$(ROOT)/stage3-chroot install

binutils-$(BINUTILS_X_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t https://github.com/riscv/riscv-binutils-gdb/archive/riscv-binutils-$(BINUTILS_X_VERSION).tar.gz
	mv $@-t $@

# Cross-compile GMP, MPFR and MPC (deps of GCC).
stage3-chroot/usr/lib64/libgmp.so.10: gmp-$(GMP_VERSION).tar.lz
	rm -rf gmp-$(GMP_VERSION)
	tar --lzip -xf gmp-$(GMP_VERSION).tar.lz
	cd gmp-$(GMP_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd gmp-$(GMP_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd gmp-$(GMP_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot
	cd stage3-chroot/usr/lib && ln -s ../lib64/libgmp.so

gmp-$(GMP_VERSION).tar.lz:
	rm -f $@ $@-t
	wget -O $@-t https://gmplib.org/download/gmp/gmp-$(GMP_VERSION).tar.lz
	mv $@-t $@

stage3-chroot/usr/lib64/libmpfr.so.4: mpfr-$(MPFR_VERSION).tar.gz
	rm -rf mpfr-$(MPFR_VERSION)
	tar -zxf mpfr-$(MPFR_VERSION).tar.gz
	cd mpfr-$(MPFR_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64 \
	    --with-gmp=$(ROOT)/stage3-chroot/usr
	cd mpfr-$(MPFR_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd mpfr-$(MPFR_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot
	cd stage3-chroot/usr/lib && ln -s ../lib64/libmpfr.so
	rm -f stage3-chroot/usr/lib64/*.la

mpfr-$(MPFR_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://www.mpfr.org/mpfr-current/mpfr-$(MPFR_VERSION).tar.gz
	mv $@-t $@

stage3-chroot/usr/lib64/libmpc.so.3: mpc-$(MPC_VERSION).tar.gz
	rm -rf mpc-$(MPC_VERSION)
	tar -zxf mpc-$(MPC_VERSION).tar.gz
	cd mpc-$(MPC_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64 \
	    --with-gmp=$(ROOT)/stage3-chroot/usr \
	    --with-mpfr=$(ROOT)/stage3-chroot/usr
	cd mpc-$(MPC_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd mpc-$(MPC_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot
	cd stage3-chroot/usr/lib && ln -s ../lib64/libmpc.so
	rm -f stage3-chroot/usr/lib64/*.la

mpc-$(MPC_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t ftp://ftp.gnu.org/gnu/mpc/mpc-$(MPC_VERSION).tar.gz
	mv $@-t $@

# Cross-compile GCC.
stage3-chroot/usr/bin/gcc: gcc-$(GCC_X_VERSION).tar.gz
	rm -rf riscv-gcc-riscv-gcc-$(GCC_X_VERSION)
	zcat $^ | tar xf -
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION) && \
	patch -p1 < ../0001-HACKS-TO-GET-GCC-TO-COMPILE.patch
	mkdir riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build && \
	gcc_cv_as_leb128=no \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	../configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64 \
	    --enable-shared \
	    --enable-tls \
	    --enable-languages=c,c++ \
	    --disable-libmudflap \
	    --disable-libssp \
	    --disable-libquadmath \
	    --disable-nls \
	    --disable-multilib \
	    --enable-__cxa_atexit \
	    --disable-libunwind-exceptions \
	    --enable-gnu-unique-object \
	    --enable-linker-build-id \
	    --with-linker-hash-style=gnu \
	    --enable-initfini-array \
	    --disable-libgcj
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build && gcc_cv_as_leb128=no PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build && make install DESTDIR=$(ROOT)/stage3-chroot
	rm -f stage3-chroot/usr/lib64/*.la
# See next rule for why we do this ...
	rm -f stage3-chroot/usr/lib64/libstdc++*
	rm -f stage3-chroot/usr/lib64/libgomp*
	rm -f stage3-chroot/usr/lib64/libatomic*

# libstdc++ isn't built correctly.  I believe it installs an x86
# executable into /usr/lib64 and ignores the --libdir parameter
# entirely.  Fix this mess.
stage3-chroot/usr/lib64/libstdc++.so: stage3-chroot/usr/bin/gcc
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build/riscv64-unknown-linux-gnu/libstdc++-v3 && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	../../../libstdc++-v3/configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build/riscv64-unknown-linux-gnu/libstdc++-v3 && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	make clean
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build/riscv64-unknown-linux-gnu/libstdc++-v3 && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	$(MAKE)
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build/riscv64-unknown-linux-gnu/libstdc++-v3 && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	make install DESTDIR=$(ROOT)/stage3-chroot
# make install ignores --libdir, so we have to do this:
	mv $(ROOT)/stage3-chroot/usr/lib/libstdc++* $(ROOT)/stage3-chroot/usr/lib64/

# libgomp isn't built correctly.
stage3-chroot/usr/lib64/libgomp.so: stage3-chroot/usr/bin/gcc
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build/riscv64-unknown-linux-gnu/libgomp && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	../../../libgomp/configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build/riscv64-unknown-linux-gnu/libgomp && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	make clean
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build/riscv64-unknown-linux-gnu/libgomp && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	$(MAKE)
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build/riscv64-unknown-linux-gnu/libgomp && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	make install DESTDIR=$(ROOT)/stage3-chroot

# We don't have cross-compiled libatomic for riscv64, but libgcc_s.so refers to symbols from this library
stage3-chroot/usr/lib64/libatomic.so: stage3-chroot/usr/bin/gcc
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build/riscv64-unknown-linux-gnu/libatomic && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	../../../libatomic/configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build/riscv64-unknown-linux-gnu/libatomic && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	make clean
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build/riscv64-unknown-linux-gnu/libatomic && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	$(MAKE)
	cd riscv-gcc-riscv-gcc-$(GCC_X_VERSION)/build/riscv64-unknown-linux-gnu/libatomic && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	make install DESTDIR=$(ROOT)/stage3-chroot

gcc-$(GCC_X_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t https://github.com/riscv/riscv-gcc/archive/riscv-gcc-$(GCC_X_VERSION).tar.gz
	mv $@-t $@

# Cross-compile util-linux.
stage3-chroot/usr/bin/mount: util-linux-$(UTIL_LINUX_VERSION).tar.xz
	rm -rf util-linux-$(UTIL_LINUX_VERSION)
	tar -Jxf $^
	cd util-linux-$(UTIL_LINUX_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	LDFLAGS=-L$(ROOT)/stage3-chroot/usr/lib64 \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64 \
	    --without-python \
	    --without-systemd \
	    --disable-makeinstall-chown \
	    --disable-eject \
	    --enable-static-programs=mount
	cd util-linux-$(UTIL_LINUX_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd util-linux-$(UTIL_LINUX_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH make install DESTDIR=$(ROOT)/stage3-chroot
	rm -f stage3-chroot/usr/lib64/*.la

util-linux-$(UTIL_LINUX_VERSION).tar.xz:
	rm -f $@ $@-t
	wget -O $@-t ftp://ftp.kernel.org/pub/linux/utils/util-linux/v$(UTIL_LINUX_VERSION)/util-linux-$(UTIL_LINUX_VERSION).tar.xz
	mv $@-t $@

# Cross-compile GNU tar.
stage3-chroot/usr/bin/tar: tar-$(TAR_VERSION).tar.xz
	rm -rf tar-$(TAR_VERSION)
	tar -Jxf $^
	cd tar-$(TAR_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd tar-$(TAR_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd tar-$(TAR_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

tar-$(TAR_VERSION).tar.xz:
	rm -f $@ $@-t
	wget -O $@-t https://ftp.gnu.org/gnu/tar/tar-$(TAR_VERSION).tar.xz
	mv $@-t $@

# Cross-compile GNU gzip.
stage3-chroot/usr/bin/gzip: gzip-$(GZIP_VERSION).tar.gz
	rm -rf gzip-$(GZIP_VERSION)
	tar -zxf $^
	cd gzip-$(GZIP_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd gzip-$(GZIP_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd gzip-$(GZIP_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

gzip-$(GZIP_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t https://ftp.gnu.org/gnu/gzip/gzip-$(GZIP_VERSION).tar.gz
	mv $@-t $@

# Cross-compile zlib.
stage3-chroot/usr/lib64/libz.so: zlib-$(ZLIB_VERSION).tar.gz
	rm -rf zlib-$(ZLIB_VERSION)
	tar -zxf $^
	cd zlib-$(ZLIB_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	CC=riscv64-unknown-linux-gnu-gcc \
	CFLAGS="-I$(ROOT)/stage3-chroot/usr/include -L$(ROOT)/stage3-chroot/usr/lib" \
	./configure \
	    --prefix=/usr --libdir=/usr/lib64
	cd zlib-$(ZLIB_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE) shared
	cd zlib-$(ZLIB_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

zlib-$(ZLIB_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://zlib.net/zlib-$(ZLIB_VERSION).tar.gz
	mv $@-t $@

# Cross-compile file/libmagic.
stage3-chroot/usr/bin/file: file-$(FILE_VERSION).tar.gz
	rm -rf file-$(FILE_VERSION)
	tar -zxf $^
	cd file-$(FILE_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	LDFLAGS=-L$(ROOT)/stage3-chroot/usr/lib64 \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64 \
	    --disable-static --enable-shared
	cd file-$(FILE_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE) V=1
	cd file-$(FILE_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot
	rm -f stage3-chroot/usr/lib64/*.la

file-$(FILE_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t ftp://ftp.astron.com/pub/file/file-$(FILE_VERSION).tar.gz
	mv $@-t $@

# Cross-compile popt.
stage3-chroot/usr/lib64/libpopt.so: popt-$(POPT_VERSION).tar.gz
	rm -rf popt-$(POPT_VERSION)
	tar -zxf $^
	cd popt-$(POPT_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	LDFLAGS=-L$(ROOT)/stage3-chroot/usr/lib64 \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64 \
	    --disable-static --enable-shared
	cd popt-$(POPT_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE) V=1
	cd popt-$(POPT_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot
	rm -f stage3-chroot/usr/lib64/*.la

popt-$(POPT_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://rpm5.org/files/popt/popt-$(POPT_VERSION).tar.gz
	mv $@-t $@

# Cross-compile beecrypt.
stage3-chroot/usr/lib64/libbeecrypt.so: beecrypt-$(BEECRYPT_VERSION).tar.gz
	rm -rf beecrypt-$(BEECRYPT_VERSION)
	tar -zxf $^
	cd beecrypt-$(BEECRYPT_VERSION) && patch -p0 < ../beecrypt-disable-cplusplus.patch
	cd beecrypt-$(BEECRYPT_VERSION) && autoreconf -i
	cd beecrypt-$(BEECRYPT_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	LDFLAGS=-L$(ROOT)/stage3-chroot/usr/lib64 \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64 \
	    --without-cplusplus \
	    --without-java \
	    --disable-openmp \
	    --disable-static \
	    --enable-shared
	cd beecrypt-$(BEECRYPT_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE) V=1
	cd beecrypt-$(BEECRYPT_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH make install DESTDIR=$(ROOT)/stage3-chroot V=1
	chrpath -d stage3-chroot/usr/lib64/libbeecrypt.so.*
	rm -f stage3-chroot/usr/lib64/*.la

beecrypt-$(BEECRYPT_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://downloads.sourceforge.net/sourceforge/beecrypt/beecrypt-$(BEECRYPT_VERSION).tar.gz
	mv $@-t $@

# Cross-compile GNU nano (editor).
stage3-chroot/usr/bin/nano: nano-$(NANO_VERSION).tar.gz
	rm -rf nano-$(NANO_VERSION)
	tar -zxf $^
	cd nano-$(NANO_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	LDFLAGS=-L$(ROOT)/stage3-chroot/usr/lib64 \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd nano-$(NANO_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd nano-$(NANO_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

nano-$(NANO_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t https://www.nano-editor.org/dist/v2.6/nano-$(NANO_VERSION).tar.gz
	mv $@-t $@

# Cross-compile GNU grep.
stage3-chroot/usr/bin/grep: grep-$(GREP_VERSION).tar.xz
	rm -rf grep-$(GREP_VERSION)
	tar -Jxf $^
	cd grep-$(GREP_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd grep-$(GREP_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd grep-$(GREP_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

grep-$(GREP_VERSION).tar.xz:
	rm -f $@ $@-t
	wget -O $@-t https://ftp.gnu.org/gnu/grep/grep-$(GREP_VERSION).tar.xz
	mv $@-t $@

# Cross-compile less.
stage3-chroot/usr/bin/less: less-$(LESS_VERSION).tar.gz
	rm -rf less-$(LESS_VERSION)
	tar -zxf $^
	cd less-$(LESS_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	LDFLAGS=-L$(ROOT)/stage3-chroot/usr/lib64 \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd less-$(LESS_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd less-$(LESS_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

less-$(LESS_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://www.greenwoodsoftware.com/less/less-$(LESS_VERSION).tar.gz
	mv $@-t $@

# Cross-compile strace.
stage3-chroot/usr/bin/strace: strace-$(STRACE_SHORT_COMMIT).tar.gz stage3-chroot/usr/include/asm/ptrace.h
	rm -rf strace-$(STRACE_COMMIT)
	tar -zxf $<
	cd strace-$(STRACE_COMMIT) && patch -p1 < ../0001-Build-strace-for-RISC-V.patch
	cd strace-$(STRACE_COMMIT) && ./bootstrap
	cd strace-$(STRACE_COMMIT) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	LDFLAGS=-L$(ROOT)/stage3-chroot/usr/lib64 \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd strace-$(STRACE_COMMIT) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd strace-$(STRACE_COMMIT) && make install DESTDIR=$(ROOT)/stage3-chroot

strace-$(STRACE_SHORT_COMMIT).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t 'https://github.com/strace/strace/archive/$(STRACE_COMMIT)/strace-$(STRACE_SHORTCOMMIT).tar.gz'
	mv $@-t $@

# Cross-compile bzip2.
stage3-chroot/usr/bin/bzip2: bzip2-$(BZIP2_VERSION).tar.gz
	rm -rf bzip2-$(BZIP2_VERSION)
	tar -zxf $^
	cd bzip2-$(BZIP2_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	$(MAKE) libbz2.a bzip2 bzip2recover \
	PREFIX=/usr \
	CC=riscv64-unknown-linux-gnu-gcc \
	AR=riscv64-unknown-linux-gnu-ar \
	RANLIB=riscv64-unknown-linux-gnu-ranlib \
	CFLAGS="-Wall -Winline -O2 -g -D_FILE_OFFSET_BITS=64 -fPIC"
	cd bzip2-$(BZIP2_VERSION) && \
	make install PREFIX=$(ROOT)/stage3-chroot/usr

bzip2-$(BZIP2_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://www.bzip.org/1.0.6/bzip2-$(BZIP2_VERSION).tar.gz
	mv $@-t $@

# Cross-compile GNU make.
stage3-chroot/usr/bin/make: make-$(MAKE_VERSION).tar.gz
	rm -rf make-$(MAKE_VERSION)
	tar -zxf $^
	cd make-$(MAKE_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --without-guile \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd make-$(MAKE_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd make-$(MAKE_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

make-$(MAKE_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t https://ftp.gnu.org/gnu/make/make-$(MAKE_VERSION).tar.gz
	mv $@-t $@

# Cross-compile GNU diffutils.
stage3-chroot/usr/bin/diff: diffutils-$(DIFFUTILS_VERSION).tar.xz
	rm -rf diffutils-$(DIFFUTILS_VERSION)
	tar -Jxf $^
	cd diffutils-$(DIFFUTILS_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd diffutils-$(DIFFUTILS_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd diffutils-$(DIFFUTILS_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

diffutils-$(DIFFUTILS_VERSION).tar.xz:
	rm -f $@ $@-t
	wget -O $@-t https://ftp.gnu.org/gnu/diffutils/diffutils-$(DIFFUTILS_VERSION).tar.xz
	mv $@-t $@

# Cross-compile GNU findutils.
stage3-chroot/usr/bin/find: findutils-$(FINDUTILS_VERSION).tar.gz
	rm -rf findutils-$(FINDUTILS_VERSION)
	tar -zxf $^
	cd findutils-$(FINDUTILS_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd findutils-$(FINDUTILS_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd findutils-$(FINDUTILS_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

findutils-$(FINDUTILS_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t https://ftp.gnu.org/gnu/findutils/findutils-$(FINDUTILS_VERSION).tar.gz
	mv $@-t $@

# Cross-compile GNU sed.
stage3-chroot/usr/bin/sed: sed-$(SED_VERSION).tar.gz
	rm -rf sed-$(SED_VERSION)
	tar -zxf $^
	cd sed-$(SED_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd sed-$(SED_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd sed-$(SED_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

sed-$(SED_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t https://ftp.gnu.org/gnu/sed/sed-$(SED_VERSION).tar.gz
	mv $@-t $@

# Cross-compile patch.
stage3-chroot/usr/bin/patch: patch-$(PATCH_VERSION).tar.gz
	rm -rf patch-$(PATCH_VERSION)
	tar -zxf $^
	cd patch-$(PATCH_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd patch-$(PATCH_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd patch-$(PATCH_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

patch-$(PATCH_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t https://ftp.gnu.org/gnu/patch/patch-$(PATCH_VERSION).tar.gz
	mv $@-t $@

# Cross-compile hostname.
stage3-chroot/usr/bin/hostname: hostname-$(HOSTNAME_VERSION).tar.gz
	rm -rf hostname-$(HOSTNAME_VERSION)
	tar -zxf $^
	cd hostname && patch -p1 < ../hostname-rh.patch
	cd hostname && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	$(MAKE) \
	CC=riscv64-unknown-linux-gnu-gcc \
	CFLAGS="-O2 -g"
	cd hostname && make install BASEDIR=$(ROOT)/stage3-chroot

hostname-$(HOSTNAME_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://ftp.de.debian.org/debian/pool/main/h/hostname/hostname_$(HOSTNAME_VERSION).tar.gz
	mv $@-t $@

# Cross-compile GNU gettext.
stage3-chroot/usr/bin/gettext: gettext-$(GETTEXT_VERSION).tar.gz
	rm -rf gettext-$(GETTEXT_VERSION)
	tar -zxf $^
	cd gettext-$(GETTEXT_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd gettext-$(GETTEXT_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd gettext-$(GETTEXT_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH make install DESTDIR=$(ROOT)/stage3-chroot
	rm -f stage3-chroot/usr/lib64/*.la

gettext-$(GETTEXT_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t https://ftp.gnu.org/gnu/gettext/gettext-$(GETTEXT_VERSION).tar.gz
	mv $@-t $@

# Cross-compile lua.
stage3-chroot/usr/bin/lua: lua-$(LUA_VERSION).tar.gz
	rm -rf lua-$(LUA_VERSION)
	tar -zxf $^
	cd lua-$(LUA_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE) PLAT=linux INSTALL_TOP=/usr CC=riscv64-unknown-linux-gnu-gcc AR="riscv64-unknown-linux-gnu-ar rcu" RANLIB="riscv64-unknown-linux-gnu-ranlib" MYLDFLAGS=-L$(ROOT)/stage3-chroot/usr/lib64 MYLIBS=-ltinfo MYCFLAGS="-fPIC -DLUA_COMPAT_5_1"
	cd lua-$(LUA_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH make install INSTALL_TOP=$(ROOT)/stage3-chroot/usr INSTALL_LIB=$(ROOT)/stage3-chroot/usr/lib64

lua-$(LUA_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t https://www.lua.org/ftp/lua-$(LUA_VERSION).tar.gz
	mv $@-t $@

# Cross-compile xz.
stage3-chroot/usr/bin/xz: xz-$(XZ_VERSION).tar.gz
	rm -rf xz-$(XZ_VERSION)
	tar -zxf $^
	cd xz-$(XZ_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd xz-$(XZ_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd xz-$(XZ_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH make install DESTDIR=$(ROOT)/stage3-chroot
	rm -f stage3-chroot/usr/lib64/*.la

xz-$(XZ_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://tukaani.org/xz/xz-$(XZ_VERSION).tar.gz
	mv $@-t $@

# Cross-compile git.
stage3-chroot/usr/bin/git: git-$(GIT_VERSION).tar.gz
	rm -rf git-$(GIT_VERSION)
	tar -zxf $^
	cd git-$(GIT_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64 \
	    ac_cv_fread_reads_directories=no \
	    ac_cv_snprintf_returns_bogus=no \
	    LDFLAGS=-L$(ROOT)/stage3-chroot/usr/lib64
	cd git-$(GIT_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE) NO_PERL=1
	cd git-$(GIT_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot NO_PERL=1

git-$(GIT_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t https://www.kernel.org/pub/software/scm/git/git-$(GIT_VERSION).tar.gz
	mv $@-t $@

# Cross-compile GNU awk.
stage3-chroot/usr/bin/gawk: gawk-$(GAWK_VERSION).tar.gz
	rm -rf gawk-$(GAWK_VERSION)
	tar -zxf $^
	cd gawk-$(GAWK_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd gawk-$(GAWK_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd gawk-$(GAWK_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

gawk-$(GAWK_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t https://ftp.gnu.org/gnu/gawk/gawk-$(GAWK_VERSION).tar.gz
	mv $@-t $@

# Cross-compile vim.
stage3-chroot/usr/bin/vim: vim-$(VIM_VERSION).tar.gz
	rm -rf vim74
	bzcat $^ | tar xf -
	cd vim74/src && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	vim_cv_memmove_handles_overlap=yes \
	vim_cv_stat_ignores_slash=no \
	vim_cv_getcwd_broken=no \
	vim_cv_tty_group=world \
	vim_cv_terminfo=yes \
	vim_cv_toupper_broken=no \
	LDFLAGS=-L$(ROOT)/stage3-chroot/usr/lib64 \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64 \
	    --with-tlib=tinfo
	cd vim74/src && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd vim74/src && make install DESTDIR=$(ROOT)/stage3-chroot STRIP=riscv64-unknown-linux-gnu-strip

vim-$(VIM_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t ftp://ftp.vim.org/pub/vim/unix/vim-$(VIM_VERSION).tar.bz2
	mv $@-t $@

# Cross-compile screen.
stage3-chroot/usr/bin/screen: screen-$(SCREEN_VERSION).tar.gz
	rm -rf screen-$(SCREEN_VERSION)
	tar -zxf $^
	cd screen-$(SCREEN_VERSION) && patch -p1 < ../screen-cross-compile.patch
	cd screen-$(SCREEN_VERSION) && autoreconf -i
	cd screen-$(SCREEN_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64 \
	    --disable-pam \
	    --with-pty-mode=0620 \
	    --with-pty-group=5 \
	    --with-sys-screenrc="/etc/screenrc" \
	    --with-socket-dir="/var/run/screen"
	cd screen-$(SCREEN_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE) LDFLAGS=-L$(ROOT)/stage3-chroot/usr/lib64
	cd screen-$(SCREEN_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot
# If the user has a .screenrc, indicating local preferences, copy
# it into the chroot.  However don't fail if not found.
	-cp $(HOME)/.screenrc stage3-chroot/

screen-$(SCREEN_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t ftp://ftp.gnu.org/gnu/screen/screen-$(SCREEN_VERSION).tar.gz
	mv $@-t $@

# Cross-compile m4
stage3-chroot/usr/bin/m4: m4-$(M4_VERSION).tar.gz
	rm -rf m4-$(M4_VERSION)
	bzcat $^ | tar xf -
	cd m4-$(M4_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd m4-$(M4_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd m4-$(M4_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

m4-$(M4_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://ftp.gnu.org/gnu/m4/m4-$(M4_VERSION).tar.bz2
	mv $@-t $@

# Cross-compile flex.
stage3-chroot/usr/bin/flex: flex-$(FLEX_VERSION).tar.gz
	rm -rf flex-$(FLEX_VERSION)
	tar zxf $^
	cd flex-$(FLEX_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
# flex tries to build the tests during 'make all', by running the
# already-compiled flex binary.  Set SUBDIRS to prevent it from going
# into any directories except those needed to build flex itself.
	cd flex-$(FLEX_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE) SUBDIRS="lib src"
	cd flex-$(FLEX_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot SUBDIRS="lib src"

flex-$(FLEX_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://downloads.sourceforge.net/sourceforge/flex/flex-$(FLEX_VERSION).tar.gz
	mv $@-t $@

# Cross-compile bison.
stage3-chroot/usr/bin/bison: bison-$(BISON_VERSION).tar.gz
	rm -rf bison-$(BISON_VERSION)
	tar zxf $^
	cd bison-$(BISON_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd bison-$(BISON_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd bison-$(BISON_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

bison-$(BISON_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://ftp.gnu.org/gnu/bison/bison-$(BISON_VERSION).tar.gz
	mv $@-t $@

# Cross-compile autoconf
stage3-chroot/usr/bin/autoconf: autoconf-$(AUTOCONF_VERSION).tar.gz
	rm -rf autoconf-$(AUTOCONF_VERSION)
	tar zxf $^
	cd autoconf-$(AUTOCONF_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd autoconf-$(AUTOCONF_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd autoconf-$(AUTOCONF_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

autoconf-$(AUTOCONF_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://ftp.gnu.org/gnu/autoconf/autoconf-$(AUTOCONF_VERSION).tar.gz
	mv $@-t $@

# Cross-compile automake (note: requires Perl)
stage3-chroot/usr/bin/automake: automake-$(AUTOMAKE_VERSION).tar.gz automake-port-to-perl522.patch automake-port-to-future-gzip.patch
	rm -rf automake-$(AUTOMAKE_VERSION)
	tar zxf automake-$(AUTOMAKE_VERSION).tar.gz
	cd automake-$(AUTOMAKE_VERSION) && \
	patch -p1 < ../automake-port-to-future-gzip.patch && \
	patch -p1 < ../automake-port-to-perl522.patch && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64
	cd automake-$(AUTOMAKE_VERSION) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE)
	cd automake-$(AUTOMAKE_VERSION) && make install DESTDIR=$(ROOT)/stage3-chroot

automake-$(AUTOMAKE_VERSION).tar.gz:
	rm -rf $@ $@-t
	wget -O $@-t http://ftp.gnu.org/gnu/automake/automake-$(AUTOMAKE_VERSION).tar.gz
	mv $@-t $@

# Cross-compile elfutils.
stage3-chroot/usr/bin/eu-readelf: elfutils-$(ELFUTILS_VERSION).tar.bz2
	rm -rf elfutils-$(ELFUTILS_VERSION)
	bzcat $^ | tar xf -
	cd elfutils-$(ELFUTILS_VERSION) && patch -p1 < ../elfutils-fix-linking.patch
	cd elfutils-$(ELFUTILS_VERSION) && automake
	cd elfutils-$(ELFUTILS_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	LDFLAGS=-L$(ROOT)/stage3-chroot/usr/lib64 \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64 \
	    --program-prefix=eu-
	cd elfutils-$(ELFUTILS_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH && \
	$(MAKE) LDFLAGS=-L$(ROOT)/stage3-chroot/usr/lib64
	cd elfutils-$(ELFUTILS_VERSION) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH && \
	make install DESTDIR=$(ROOT)/stage3-chroot

elfutils-$(ELFUTILS_VERSION).tar.bz2:
	rm -f $@ $@-t
	wget -O $@-t https://fedorahosted.org/releases/e/l/elfutils/$(ELFUTILS_VERSION)/elfutils-0.166.tar.bz2
	mv $@-t $@

# Cross-compile jsoncpp.  This is a dependency of native cmake, but it
# requires cmake to build, so to break the circular dependency we need
# to cross-compile it first.
stage3-chroot/usr/lib64/libjsoncpp.so: jsoncpp-$(JSONCPP_VERSION).tar.gz
	rm -rf jsoncpp-$(JSONCPP_VERSION)
	zcat $^ | tar xf -
	cd jsoncpp-$(JSONCPP_VERSION) && mkdir build
	cd jsoncpp-$(JSONCPP_VERSION)/build && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	LDFLAGS=-L$(ROOT)/stage3-chroot/usr/lib64 \
	cmake .. \
	    -DCMAKE_C_COMPILER=riscv64-unknown-linux-gnu-gcc \
	    -DCMAKE_INSTALL_PREFIX:PATH=/usr \
	    -DINCLUDE_INSTALL_DIR:PATH=/usr/include \
	    -DJSONCPP_WITH_WARNING_AS_ERROR=OFF \
	    -DJSONCPP_WITH_PKGCONFIG_SUPPORT=ON \
	    -DBUILD_SHARED_LIBS=ON
#	    -DLIB_INSTALL_DIR:PATH=/usr/lib64
#	    -DBUILD_STATIC_LIBS=OFF
#	    -DJSONCPP_WITH_CMAKE_PACKAGE=ON
#	    -DSYSCONF_INSTALL_DIR:PATH=/etc
#	    -DSHARE_INSTALL_PREFIX:PATH=/usr/share
	cd jsoncpp-$(JSONCPP_VERSION)/build && \
	PATH=$(ROOT)/fixed-gcc:$$PATH && $(MAKE)
	cd jsoncpp-$(JSONCPP_VERSION)/build && \
	PATH=$(ROOT)/fixed-gcc:$$PATH && \
	make install DESTDIR=$(ROOT)/stage3-chroot
	mv stage3-chroot/usr/lib/libjsoncpp.{a,so}* stage3-chroot/usr/lib64/

jsoncpp-$(JSONCPP_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t 'https://github.com/open-source-parsers/jsoncpp/archive/$(JSONCPP_VERSION).tar.gz#/jsoncpp-$(JSONCPP_VERSION).tar.gz'
	mv $@-t $@

# Cross-compile RPM / rpmbuild.
# We build this from a git commit, with a few hacks to the configure
# script.
stage3-chroot/usr/bin/rpm: rpm-$(RPM_SHORT_COMMIT).tar.gz db-$(BDB_VERSION).tar.gz
	rm -rf rpm-$(RPM_SHORT_COMMIT)
	tar -zxf rpm-$(RPM_SHORT_COMMIT).tar.gz
	tar -zxf db-$(BDB_VERSION).tar.gz -C rpm-$(RPM_SHORT_COMMIT)
	cd rpm-$(RPM_SHORT_COMMIT) && ln -s db-$(BDB_VERSION) db
	cd rpm-$(RPM_SHORT_COMMIT) && \
	patch -p1 < ../0001-RISCV-64-bit-riscv64-support.patch && \
	patch -p1 < ../0002-rpmrc-Convert-uname.machine-riscv-to-riscv32-riscv64.patch && \
	patch -p1 < ../0003-build-fgetc-returns-int-not-char.patch && \
	patch -p1 < ../0001-HACKS-TO-GET-RPM-TO-CROSS-COMPILE.patch
	cd rpm-$(RPM_SHORT_COMMIT) && autoreconf -i
	cd rpm-$(RPM_SHORT_COMMIT) && \
	PATH=$(ROOT)/fixed-gcc:$$PATH \
	LDFLAGS=-L$(ROOT)/stage3-chroot/usr/lib64 \
	./configure \
	    --host=riscv64-unknown-linux-gnu \
	    --prefix=/usr --libdir=/usr/lib64 \
	    --sysconfdir=/etc --localstatedir=/var \
	    --sharedstatedir=/var/lib \
	    --disable-rpath \
	    --with-vendor=redhat \
	    --without-libarchive \
	    --with-lua \
	    --with-beecrypt \
	    --without-archive \
	    --without-external-db \
	    --enable-ndb \
	    --disable-plugins
	cd rpm-$(RPM_SHORT_COMMIT) && PATH=$(ROOT)/fixed-gcc:$$PATH $(MAKE) V=1
	cd rpm-$(RPM_SHORT_COMMIT) && PATH=$(ROOT)/fixed-gcc:$$PATH make install DESTDIR=$(ROOT)/stage3-chroot
	rm -f stage3-chroot/usr/lib64/*.la
# Fix optflags in redhat-specific RPM configuration.
	echo 'optflags: riscv64 %{__global_cflags}' >> $(ROOT)/stage3-chroot/usr/lib/rpm/redhat/rpmrc
# Hack /usr/lib/rpm/macros until we have a natively build RPM.
# These binaries might not be available in chroot, only in cross toolchain.
	sed -i \
            -e 's/riscv64-unknown-linux-gnu-ar/ar/g' \
            -e 's/riscv64-unknown-linux-gnu-gcc/gcc/g' \
            -e 's/riscv64-unknown-linux-gnu-g++/g++/g' \
            -e 's/riscv64-unknown-linux-gnu-ranlib/ranlib/g' \
            stage3-chroot/usr/lib/rpm/macros
# Kill build_ids.
	sed -i \
	    -e 's/^%_build_id_links.*/%_build_id_links none/' \
	    stage3-chroot/usr/lib/rpm/macros
# riscv64 toolchain has issues linking static binaries if hardedning is enabled.
# This is caused by '-pie' flag on gcc link command (e.g. bzip2)
# Until issue is resolved globally disable hardening.
	sed -i \
          -e 's/^%_hardened_build/#_hardened_build/' \
          -e 's/\(^%_configure_libtool_hardening_hack\).*/\1\t0/' \
          stage3-chroot/usr/lib/rpm/redhat/macros
# Make sure latest config.guess/config.sub get copied in (see below).
	rm -f stage3-chroot/usr/lib/rpm/config.guess
	rm -f stage3-chroot/usr/lib/rpm/config.sub

rpm-$(RPM_SHORT_COMMIT).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t 'http://rpm.org/gitweb?p=rpm.git;a=snapshot;h=$(RPM_COMMIT);sf=tgz'
	mv $@-t $@

db-$(BDB_VERSION).tar.gz:
	rm -f $@ $@-t
	wget -O $@-t http://download.oracle.com/berkeley-db/db-$(BDB_VERSION).tar.gz
	mv $@-t $@

# Add a custom poweroff program.
# For some reason this only works in qemu, not spike.
stage3-chroot/usr/bin/poweroff: poweroff.c
	$(ROOT)/fixed-gcc/riscv64-unknown-linux-gnu-gcc $^ -o $@

# Create a place to put useful command aliases.
stage3-chroot/etc/profile.d/aliases.sh: aliases.sh
	install -m 0755 $^ $@

# Create a yum repo pointing to the RPMs in /rpmbuild.
stage3-chroot/etc/yum.repos.d/local.repo: stage3-tdnf/local.repo
	install -m 0755 $^ $@

# Copy latest config.guess and config.sub into the RPM directory.
# Using the RPM %configure macro copies this into every build.
stage3-chroot/usr/lib/rpm/config.guess: config.guess
	install -m 0755 $^ $@
stage3-chroot/usr/lib/rpm/config.sub: config.sub
	install -m 0755 $^ $@

# Create /rpmbuild inside the stage3 chroot.
stage3-chroot/rpmbuild:
	mkdir -p $@/{BUILD,BUILDROOT,RPMS/noarch,RPMS/riscv64,SOURCES,SPECS,SRPMS}

INIT=init.sh

# Create the stage3 disk image.
# Note `-s +...' adds spare space to the disk image.
$(STAGE3_DISK):: stage3-chroot/rpmbuild stage3-chroot
	rm -f $@
	cp stage3-built-rpms/RPMS/riscv64/*.rpm stage3-chroot/rpmbuild/RPMS/riscv64/
	cp stage3-built-rpms/RPMS/noarch/*.rpm stage3-chroot/rpmbuild/RPMS/noarch/
	cp stage3-built-rpms/SRPMS/*.rpm stage3-chroot/rpmbuild/SRPMS/
# Re-download the noarch packages and copy them into the disk image too.
	rm -f stamp-koji-packages
	$(MAKE) stamp-koji-packages
	cp stage4-koji-noarch-rpms/*.noarch.rpm stage3-chroot/rpmbuild/RPMS/noarch/
	cp stage4-koji-noarch-rpms/*.src.rpm stage3-chroot/rpmbuild/SRPMS/
# Create a repository for use by tdnf.  This is pointed to by
# /etc/yum.repos.d/local.repo
	cd stage3-chroot/rpmbuild/RPMS && createrepo .
	cp $(INIT) stage3-chroot/init
	cd stage3-chroot && virt-make-fs . ../$@ -t ext2 -F raw -s +20G

# If a rule really wants stage3-disk.img, you have to unset the
# environment variable.
stage3-disk.img::
	@if [ "$(STAGE3_DISK)" != stage3-disk.img ]; then \
	  echo "unset STAGE3_DISK environment variable to continue"; \
	  exit 1; \
	fi

# Upload the compressed disk image.
upload-stage3: stage3-disk.img.xz
	scp $^ tick:public_html/riscv/
stage3-disk.img.xz: stage3-disk.img
	rm -f $@
	xz --best -k $^

# Helper which boots stage3 disk image in spike.
boot-stage3-in-spike: $(STAGE3_DISK) stage3-kernel/linux-$(KERNEL_VERSION)/vmlinux
	spike +disk=$(STAGE3_DISK) \
	    /usr/bin/bbl stage3-kernel/linux-$(KERNEL_VERSION)/vmlinux

# Helper which boots stage3 disk image in qemu.
boot-stage3-in-qemu: $(STAGE3_DISK) stage3-kernel/linux-$(KERNEL_VERSION)/vmlinux
	qemu-system-riscv -m 4G -kernel /usr/bin/bbl \
	    -append ./stage3-kernel/linux-$(KERNEL_VERSION)/vmlinux \
	    -drive file=$(STAGE3_DISK),format=raw -nographic

ifneq ($(origin SRPM), undefined)

# Rule for building SRPMs automatically.
# For instructions, see:
# https://fedoraproject.org/wiki/Architectures/RISC-V/Bootstrapping

STAGE3_BUILD_EMULATOR = qemu

srpm_init=$(shell rpm -q --qf "%{NAME}\n" -p $(SRPM))-init.sh
srpm_disk=$(shell rpm -q --qf "%{NAME}\n" -p $(SRPM))-disk.img

stage3-build:
	@if [ "$(STAGE3_DISK)" != stage3-disk.img ]; then \
	  echo "unset STAGE3_DISK environment variable to continue"; \
	  exit 1; \
	fi
	rm -f $(srpm_disk)
	cp $(SRPM) stage3-chroot/var/tmp/
	sed 's,@SRPM@,$(shell basename $(SRPM)),' \
		< stage3-build-init.sh.in > $(srpm_init)
	$(MAKE) STAGE3_DISK=$(srpm_disk) $(srpm_disk) INIT=$(srpm_init)
	rm $(srpm_init)
# Boot the first time to install the RPMs.
	$(MAKE) STAGE3_DISK=$(srpm_disk) boot-stage3-in-$(STAGE3_BUILD_EMULATOR)
	@if ! guestfish --ro -a $(srpm_disk) -i stat /rpmsdone; then \
	    echo "Build failed -- see error messages above."; \
	    exit 1; \
	fi
# Boot the second time to build the SRPM.
	$(MAKE) STAGE3_DISK=$(srpm_disk) boot-stage3-in-$(STAGE3_BUILD_EMULATOR)
	@if ! guestfish --ro -a $(srpm_disk) --ro -i stat /buildok; then \
	    echo "Build failed -- see error messages above."; \
	    exit 1; \
	fi
	virt-copy-out -a $(srpm_disk) /rpmbuild ./
	cp $(SRPM) stage3-built-rpms/SRPMS/
	@echo Check log output, and RPMs in ./rpmbuild directory
	@echo If they are correct then:
	@echo 1. copy RPMs from ./rpmbuild to stage3-built-rpms/RPMS/riscv64/
	@echo 2. check in the SRPM and RPMs
	@echo $(srpm_disk) is still available for examination.

endif

# Stage 4

stage4: stage4-disk.img

# The clean stage4 disk image, built only from RPMs.
stage4-disk.img: stage4-disk.img-pristine
	cp $< $@

stage4-disk.img-pristine: stamp-stage4-builder stage3-chroot/usr/bin/poweroff
	rm -f $@ $@-t
# Boot the first time to install the RPMs.
	$(MAKE) STAGE3_DISK=stage4-builder.img boot-stage3-in-qemu
	@if ! guestfish --ro -a stage4-builder.img -i stat /rpmsdone; then \
	    echo "Build failed -- see error messages above."; \
	    exit 1; \
	fi
# Boot the second time to build the stage4.
	$(MAKE) STAGE3_DISK=stage4-builder.img boot-stage3-in-qemu
	guestfish --ro -a stage4-builder.img -i download /var/tmp/stage4-disk.img $@-t
# Temporarily add an /init script and a poweroff command.
# We will remove these when we have built systemd.  However we
# will also have to recompile the kernel to remove the hard-coded
# init=/init command line.
	guestfish -a $@-t -i \
	    upload stage4-temporary-init.sh /init : \
	    chmod 0755 /init : \
	    upload stage3-chroot/usr/bin/poweroff /usr/bin/poweroff : \
	    chmod 0755 /usr/bin/poweroff
# Sparsify it.
	virt-sparsify --inplace $@-t
	mv $@-t $@

# The "builder" is a variation of stage3-disk.img with a modified
# /init script and containing all the RPMs built so far.  The /init
# script takes the RPMs and tries to build stage4-disk.img from them.
stamp-stage4-builder: stage4-build-init.sh \
		      stage3-chroot/var/tmp/stage4-disk.img-template.tar.gz
	rm -f $@ stage4-builder.img
	$(MAKE) STAGE3_DISK=stage4-builder.img stage4-builder.img INIT=$<
	touch $@

# Make an empty template for the stage4 disk image.
# This just avoids having to upload mkfs tools to stage3.
#
# We have to use '.tar.gz' format here because it's the only format
# that preserves sparseness properly (we could use 'xz' instead, but
# that's really slow).
stage3-chroot/var/tmp/stage4-disk.img-template.tar.gz: stage4-disk.img-template.tar.gz
	cp $< $@

stage4-disk.img-template.tar.gz: stage4-disk.img-template.tar
	rm -f $@
	gzip -9 -k $^

stage4-disk.img-template.tar: stage4-disk.img-template
	rm -f $@ $@-t
	tar -cSf $@-t $^
	mv $@-t $@

stage4-disk.img-template:
	rm -f $@ $@-t
	truncate -s 10G $@-t
	mkfs -t ext4 $@-t
	mv $@-t $@

# Download STAGE4_KOJI_NOARCH_NAMES packages.
stamp-koji-packages:
	rm -f $@
	mkdir -p stage4-koji-noarch-rpms
	cd stage4-koji-noarch-rpms && \
	for f in $$( koji latest-build $(STAGE4_KOJI_FEDORA_RELEASE) $(STAGE4_KOJI_NOARCH_NAMES) --quiet | awk '{print $$1}' ); do \
	    test -f $$f.src.rpm || koji download-build $$f || exit 1; \
	done;
# Blacklist a few packages which cause excessive dependencies.
	rm -f stage4-koji-noarch-rpms/fedora-release-[a-z]*
	rm -f stage4-koji-noarch-rpms/emacs-gettext-*
	touch $@

# Helper which boots stage4 disk image in qemu.
boot-stage4-in-qemu: stage4-disk.img stage3-kernel/linux-$(KERNEL_VERSION)/vmlinux
	qemu-system-riscv -m 4G -kernel /usr/bin/bbl \
	    -append ./stage3-kernel/linux-$(KERNEL_VERSION)/vmlinux \
	    -drive file=stage4-disk.img,format=raw -nographic

# Upload the compressed stage4 disk image.
upload-stage4: stage4-disk.img.xz stage3-kernel/linux-$(KERNEL_VERSION)/vmlinux
	scp $^ fedorapeople.org:/project/risc-v/disk-images/

stage4-disk.img.xz: stage4-disk.img-pristine
	rm -f $@ $@-t
	xz --best -k $^ --stdout > $@-t
	mv $@-t $@

# Don't run the builds in parallel because they are implicitly ordered.
.NOTPARALLEL:
