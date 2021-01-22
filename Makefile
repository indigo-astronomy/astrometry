
ifeq ($(OS),Windows_NT)
	OS_DETECTED = Windows
else
	OS_DETECTED = $(shell uname -s)
	ARCH_DETECTED = $(shell uname -m)
	ifeq ($(OS_DETECTED),Darwin)
		CC = /usr/bin/clang
		AR = /usr/bin/libtool
		ifeq ($(findstring arm64e,$(shell file $(CC) | head -1)),arm64e)
			MAC_ARCH = -arch x86_64 -arch arm64
		else
			MAC_ARCH = -arch x86_64
		endif
		CFLAGS = $(DEBUG_BUILD) $(MAC_ARCH) -mmacosx-version-min=10.10 -fPIC -O3 -std=gnu11
		LDFLAGS = $(MAC_ARCH) -headerpad_max_install_names -mmacosx-version-min=10.10 -lobjc
		ARFLAGS = -static -o
	endif
	ifeq ($(OS_DETECTED),Linux)
		ifeq ($(ARCH_DETECTED),armv6l)
			ARCH_DETECTED = arm
			DEBIAN_ARCH = armhf
		endif
		ifeq ($(ARCH_DETECTED),armv7l)
			ARCH_DETECTED = arm
			DEBIAN_ARCH = armhf
		endif
		ifeq ($(ARCH_DETECTED),aarch64)
			ARCH_DETECTED = arm64
			DEBIAN_ARCH = arm64
			EXCLUDED_DRIVERS += ccd_sbig
		endif
		ifeq ($(ARCH_DETECTED),i686)
			ARCH_DETECTED = x86
			DEBIAN_ARCH = i386
		endif
		ifeq ($(ARCH_DETECTED),x86_64)
			ifeq ($(wildcard /lib/x86_64-linux-gnu/),)
				ARCH_DETECTED = x86
				DEBIAN_ARCH = i386
			else
				ARCH_DETECTED = x64
				DEBIAN_ARCH = amd64
			endif
		endif
		CC = gcc
		AR = ar
		ifeq ($(ARCH_DETECTED),arm)
			CFLAGS = $(DEBUG_BUILD) -fPIC -O3 -march=armv6 -mfpu=vfp -mfloat-abi=hard -marm -mthumb-interwork -std=gnu11 -pthread -D_FILE_OFFSET_BITS=64
		else
			CFLAGS = $(DEBUG_BUILD) -fPIC -O3 -std=gnu11 -pthread
		endif
		LDFLAGS = -lm -lrt -lusb-1.0 -pthread -L$(BUILD_LIB) -Wl,-rpath=\\\$$\$$ORIGIN/../lib,-rpath=\\\$$\$$ORIGIN/../drivers,-rpath=.
		ARFLAGS = -rv
	endif
endif

AWK = awk

ASTROMETRY = ../astrometry.net
CFITSIO = ../cfitsio

VERSION = 0.85

CFLAGS += -I $(ASTROMETRY)/include -I $(ASTROMETRY)/include/astrometry -I $(ASTROMETRY)/gsl-an -I $(ASTROMETRY)/util \
	-I $(CFITSIO) \
	-I include -isysteminclude

AN_GIT_REVISION = $(shell git rev-parse HEAD)
AN_GIT_DATE = $(shell git log -n 1 --format=%cd | sed 's/ /_/g')
AN_GIT_URL = $(shell git remote get-url origin)

CFLAGS += -DAN_GIT_REVISION='"$(AN_GIT_REVISION)"'
CFLAGS += -DAN_GIT_DATE='"$(AN_GIT_DATE)"'
CFLAGS += -DAN_GIT_URL='"$(AN_GIT_URL)"'

ANBASE_FILES = starutil mathutil bl-sort bl bt healpix-utils \
	healpix permutedsort ioutils fileutils md5 \
	an-endian errors an-opts tic log datalog \
	sparsematrix coadd convolve-image resample \
	intmap histogram histogram2d
	
ANUTILS_FILES =  sip-utils fit-wcs sip \
	anwcs wcs-resample gslutils wcs-pv2sip matchobj \
	fitsioutils sip_qfits fitstable fitsbin fitsfile \
	tic dallpeaks dcen3x3 dfind dmedsmooth dobjects \
	dpeaks dselip dsigma dsmooth image2xy simplexy ctmf

ANFILES_FILES = multiindex index indexset \
	codekd starkd rdlist xylist \
	starxy qidxfile quadfile scamp scamp-catalog \
	tabsort wcs-xy2rd wcs-rd2xy matchfile
	
QFITS_FILES = anqfits qfits_card qfits_convert qfits_error qfits_header \
	qfits_image qfits_md5 qfits_table qfits_time qfits_tools qfits_byteswap \
	qfits_memory qfits_rw qfits_float
	
KD_FILES = kdint_ddd kdint_fff kdint_ddu kdint_duu kdint_dds kdint_dss kdtree \
	kdtree_dim kdtree_mem kdtree_fits_io dualtree dualtree_rangesearch \
	dualtree_nearestneighbour

GSL_FILES = cblas/dtrmm cblas/sdsdot cblas/sdot cblas/ddot cblas/cdotu_sub \
	cblas/cdotc_sub cblas/xerbla cblas/ztrsm cblas/ctrsm cblas/dtrsm \
	cblas/strsm cblas/ztrmm cblas/ctrmm cblas/strmm cblas/zher2k cblas/cher2k \
	cblas/zsyr2k cblas/csyr2k cblas/dsyr2k cblas/ssyr2k cblas/zherk cblas/cherk \
	cblas/zsyrk cblas/csyrk cblas/dsyrk cblas/ssyrk cblas/dsyr cblas/ssyr \
	cblas/dsyr2 cblas/ssyr2 cblas/zhemm cblas/chemm cblas/zsymm cblas/csymm \
	cblas/dsymm cblas/ssymm cblas/zgemm cblas/cgemm cblas/dgemm cblas/sgemm \
	cblas/zher2 cblas/cher2 cblas/zher cblas/cher cblas/zgerc cblas/cgerc \
	cblas/zgeru cblas/cgeru cblas/sger cblas/dger cblas/ztrsv cblas/ctrsv \
	cblas/dtrsv cblas/strsv cblas/ztrmv cblas/ctrmv cblas/dtrmv cblas/strmv \
	cblas/ssymv cblas/dsymv cblas/zhemv cblas/chemv cblas/zgemv cblas/cgemv \
	cblas/dgemv cblas/sgemv cblas/zdscal cblas/csscal cblas/zscal cblas/cscal \
	cblas/dscal cblas/sscal cblas/drotm cblas/srotm cblas/drotmg cblas/srotmg \
	cblas/drot cblas/srot cblas/drotg cblas/srotg cblas/zaxpy cblas/caxpy \
	cblas/daxpy cblas/saxpy cblas/zcopy cblas/ccopy cblas/dcopy cblas/scopy \
	cblas/zswap cblas/cswap cblas/dswap cblas/sswap cblas/izamax cblas/icamax \
	cblas/idamax cblas/isamax cblas/dzasum cblas/scasum cblas/dasum cblas/sasum \
	cblas/dznrm2 cblas/scnrm2 cblas/dnrm2 cblas/snrm2 cblas/zdotc_sub \
	cblas/zdotu_sub cblas/dsdot multiroots/fdjac multiroots/fsolver \
	multiroots/fdfsolver multiroots/convergence multiroots/newton \
	multiroots/gnewton multiroots/dnewton multiroots/broyden \
	multiroots/hybrid multiroots/hybridj vector/prop matrix/matrix \
	matrix/rowcol matrix/init matrix/submatrix matrix/copy vector/vector \
	vector/subvector vector/copy vector/init block/block block/init \
	err/error err/stream sys/infnan sys/fdiv blas/blas linalg/cholesky \
	matrix/matrix matrix/rowcol vector/vector vector/subvector vector/copy \
	err/error err/stream sys/infnan sys/fdiv blas/blas linalg/svd \
	linalg/bidiag sys/coerce vector/swap matrix/swap vector/oper sys/ldfrexp \
	linalg/lu permutation/init permutation/permutation permutation/permute \
	matrix/view err/strerror \
	linalg/qr linalg/householder matrix/matrix matrix/rowcol matrix/init \
	matrix/submatrix matrix/copy vector/vector vector/subvector vector/copy \
	vector/init block/block block/init err/error err/stream sys/infnan sys/fdiv \
	blas/blas

GSL_FILES := $(sort $(GSL_FILES))

ENGINE_FILES = engine solverutils onefield solver quad-utils \
	solvedfile tweak2 \
	verify tweak new-wcs fits-guess-scale cut-table \
	resort-xylist image2xy-files augment-xylist

CAT_FILES = openngc brightstars constellations \
	tycho2-fits tycho2 usnob-fits usnob nomad nomad-fits \
	ucac3-fits ucac3 ucac4-fits ucac4 2mass-fits 2mass hd \
	constellation-boundaries

CFITSIO_FILES = buffers cfileio checksum drvrfile drvrmem \
	drvrnet drvrsmem editcol edithdu eval_l \
	eval_y eval_f fitscore getcol getcolb getcold getcole \
	getcoli getcolj getcolk getcoll getcols getcolsb \
	getcoluk getcolui getcoluj getkey group grparser \
	histo iraffits \
	modkey putcol putcolb putcold putcole putcoli \
	putcolj putcolk putcoluk putcoll putcols putcolsb \
	putcolu putcolui putcoluj putkey region scalnull \
	swapproc wcssub wcsutil imcompress quantize ricecomp \
	pliocomp fits_hcompress fits_hdecompress simplerng \
	zlib/adler32 zlib/crc32 zlib/deflate zlib/infback \
	zlib/inffast zlib/inflate zlib/inftrees zlib/trees \
	zlib/uncompr zlib/zcompress zlib/zuncompress zlib/zutil

AN_LIB = lib/liban.a
QFITS_LIB = lib/libqfits.a
KD_LIB = lib/libkd.a
GSL_LIB = lib/libgsl.a
ENGINE_LIB = lib/libengine.a
CAT_LIB = lib/libcat.a
CFITSIO_LIB = lib/libcfitsio.a
IMAGE2XY_LIB = lib/libimage2xy.a
NEWWCS_LIB = lib/libnew-wcs.a
SOLVEFIELD_LIB = lib/libsolve-field.a
ASTROMETRYENGINE_LIB = lib/libastrometry-engine.a
WCSINFO_LIB = lib/libwcsinfo.a

LIBS = $(ENGINE_LIB) $(KD_LIB) $(CAT_LIB) $(AN_LIB) $(QFITS_LIB) $(GSL_LIB) $(CFITSIO_LIB)

IMAGE2XY = bin/image2xy
NEWWCS = bin/new-wcs
SOLVEFIELD = bin/solve-field
ASTROMETRYENGINE = bin/astrometry-engine
WCSINFO = bin/wcsinfo

all: init $(ANBASE_LIB) $(ANUTILS_LIB) $(ANFILES_LIB) $(QFITS_LIB) $(KD_LIB) $(GSL_LIB) $(CFITSIO_LIB) $(ENGINE_LIB) \
	$(ASTROMETRY)/catalogs/openngc-names.c $(ASTROMETRY)/catalogs/openngc-entries.c $(CAT_LIB) \
	$(IMAGE2XY_LIB) $(NEWWCS_LIB) $(SOLVEFIELD_LIB) $(ASTROMETRYENGINE_LIB) $(WCSINFO_LIB) \
	$(IMAGE2XY) $(NEWWCS) $(SOLVEFIELD) $(ASTROMETRYENGINE) $(WCSINFO)

init:
	install -d lib
	install -d bin

$(AN_LIB): $(addsuffix .o, $(addprefix $(ASTROMETRY)/util/, $(ANBASE_FILES) $(ANUTILS_FILES) $(ANFILES_FILES)))
	$(AR) $(ARFLAGS) $@ $^

$(QFITS_LIB): $(addsuffix .o, $(addprefix $(ASTROMETRY)/qfits-an/, $(QFITS_FILES)))
	$(AR) $(ARFLAGS) $@ $^

$(KD_LIB): $(addsuffix .o, $(addprefix $(ASTROMETRY)/libkd/, $(KD_FILES)))
	$(AR) $(ARFLAGS) $@ $^

$(GSL_LIB): $(addsuffix .o, $(addprefix $(ASTROMETRY)/gsl-an/, $(GSL_FILES)))
	$(AR) $(ARFLAGS) $@ $^

$(ENGINE_LIB): $(addsuffix .o, $(addprefix $(ASTROMETRY)/solver/, $(ENGINE_FILES)))
	$(AR) $(ARFLAGS) $@ $^

$(ASTROMETRY)/catalogs/openngc-entries.csv: $(ASTROMETRY)/catalogs/openngc-entries-csv.awk $(ASTROMETRY)/catalogs/NGC.csv
	$(AWK) -F\; -f $(ASTROMETRY)/catalogs/openngc-entries-csv.awk < $(ASTROMETRY)/catalogs/NGC.csv > $@

$(ASTROMETRY)/catalogs/openngc-names.csv: $(ASTROMETRY)/catalogs/openngc-names-csv.awk $(ASTROMETRY)/catalogs/NGC.csv
	$(AWK) -F\; -f $(ASTROMETRY)/catalogs/openngc-names-csv.awk < $(ASTROMETRY)/catalogs/NGC.csv > $@

$(ASTROMETRY)/catalogs/openngc-names.c: $(ASTROMETRY)/catalogs/openngc-names-c.awk $(ASTROMETRY)/catalogs/openngc-names.csv
	$(AWK) -F\; -f $(ASTROMETRY)/catalogs/openngc-names-c.awk < $(ASTROMETRY)/catalogs/openngc-names.csv > $@

$(ASTROMETRY)/catalogs/openngc-entries.c: $(ASTROMETRY)/catalogs/openngc-entries-c.awk $(ASTROMETRY)/catalogs/openngc-entries.csv
	$(AWK) -F\; -f $(ASTROMETRY)/catalogs/openngc-entries-c.awk < $(ASTROMETRY)/catalogs/openngc-entries.csv > $@

$(CAT_LIB): $(addsuffix .o, $(addprefix $(ASTROMETRY)/catalogs/, $(CAT_FILES)))
	$(AR) $(ARFLAGS) $@ $^

$(CFITSIO_LIB): $(addsuffix .o, $(addprefix $(CFITSIO)/, $(CFITSIO_FILES)))
	$(AR) $(ARFLAGS) $@ $^

#src/image2xy-main.c: $(ASTROMETRY)/solver/image2xy-main.c
#	sed "s/^int main/int main_image2xy/" $(ASTROMETRY)/solver/image2xy-main.c >src/image2xy-main.c

$(IMAGE2XY_LIB): $(ASTROMETRY)/solver/image2xy-main.o
	$(AR) $(ARFLAGS) $@ $^

$(NEWWCS_LIB): $(ASTROMETRY)/solver/new-wcs-main.o
	$(AR) $(ARFLAGS) $@ $^

$(SOLVEFIELD_LIB): $(ASTROMETRY)/solver/solve-field.o
	$(AR) $(ARFLAGS) $@ $^

$(ASTROMETRYENGINE_LIB): $(ASTROMETRY)/solver/engine-main.o
	$(AR) $(ARFLAGS) $@ $^

$(WCSINFO_LIB): $(ASTROMETRY)/util/wcsinfo.o
	$(AR) $(ARFLAGS) $@ $^

$(IMAGE2XY): $(ASTROMETRY)/solver/image2xy-main.o $(LIBS)
	$(CC) -o $@ $(LDFLAGS) $^

$(NEWWCS): $(ASTROMETRY)/solver/new-wcs-main.o $(LIBS)
	$(CC) -o $@ $(LDFLAGS) $^

$(SOLVEFIELD): $(ASTROMETRY)/solver/solve-field.o $(LIBS)
	$(CC) -o $@ $(LDFLAGS) $^

$(ASTROMETRYENGINE): $(ASTROMETRY)/solver/engine-main.o $(LIBS)
	$(CC) -o $@ $(LDFLAGS) $^

$(WCSINFO): $(ASTROMETRY)/util/wcsinfo.o $(LIBS)
	$(CC) -o $@ $(LDFLAGS) $^

package: ROOT = indigo-astrometry-$(VERSION)-$(DEBIAN_ARCH)
package: all
	rm -rf $(ROOT) $(ROOT).deb
	install -d $(ROOT)
	install -d $(ROOT)/usr/bin
	install -m 0755 bin/* $(ROOT)/usr/bin
	install -d $(ROOT)/DEBIAN
	printf "Package: indigo-astrometry\n" > $(ROOT)/DEBIAN/control
	printf "Version: $(VERSION)\n" >> $(ROOT)/DEBIAN/control
	printf "Installed-Size: $(shell echo `du -s $$(ROOT) | cut -f1`)\n" >> $(ROOT)/DEBIAN/control
	printf "Priority: optional\n" >> $(ROOT)/DEBIAN/control
	printf "Architecture: $(DEBIAN_ARCH)\n" >> $(ROOT)/DEBIAN/control
	printf "Maintainer: CloudMakers, s. r. o. <indigo@cloudmakers.eu>\n" >> $(ROOT)/DEBIAN/control
	printf "Homepage: http://www.indigo-astronomy.org\n" >> $(ROOT)/DEBIAN/control
	printf "Description: Astrometry.net for INDIGO\n" >> $(ROOT)/DEBIAN/control
	printf " Automatic recognition of astronomical images; or standards-compliant astrometric metadata from data.\n" >> $(ROOT)/DEBIAN/control
	fakeroot dpkg --build $(ROOT)
	rm -rf $(ROOT)

debs-docker:
	cd ../cfitsio; git archive --format=tar --prefix=cfitsio/ HEAD | gzip >../astrometry/cfitsio.tar.gz
	cd ../astrometry.net; git archive --format=tar --prefix=astrometry.net/ HEAD | gzip >../astrometry/astrometry.net.tar.gz
	cd ../astrometry; git archive --format=tar --prefix=indigo-astrometry-$1/ HEAD | gzip >indigo-astrometry.tar.gz
	sh tools/build_debs.sh "i386/debian:stretch-slim" "indigo-astrometry-$(VERSION)-i386.deb" $(VERSION)
	sh tools/build_debs.sh "amd64/debian:stretch-slim" "indigo-astrometry-$(VERSION)-amd64.deb" $(VERSION)
	sh tools/build_debs.sh "arm32v7/debian:buster-slim" "indigo-astrometry-$(VERSION)-armhf.deb" $(VERSION)
	sh tools/build_debs.sh "arm64v8/debian:buster-slim" "indigo-astrometry-$(VERSION)-arm64.deb" $(VERSION)
	rm indigo-astrometry.tar.gz cfitsio.tar.gz astrometry.net.tar.gz

clean:
	rm -rf lib bin
	cd $(ASTROMETRY); git clean -dfx
	cd $(CFITSIO); git clean -dfx
