$(info == General overrides: $(lastword $(MAKEFILE_LIST)))

# Install the mingw-w64 headers somewhere else
# because we need to distribute the /include and
# /lib directories
mingw-w64-headers_CONFIGURE_OPTS=--prefix='$(PREFIX)/$(TARGET)/mingw'

# Common configure options for building within the
# $(PREFIX)/$(TARGET)/mingw directory.
common_CONFIGURE_OPTS=--prefix='$(PREFIX)/$(TARGET)/mingw' \
--with-sysroot='$(PREFIX)/$(TARGET)/mingw' \
CPPFLAGS='-I$(PREFIX)/$(TARGET)/mingw/include' \
CFLAGS='-I$(PREFIX)/$(TARGET)/mingw/include -s -O3 -ffast-math' \
CXXFLAGS='-I$(PREFIX)/$(TARGET)/mingw/include -s -O3 -ffast-math' \
LDFLAGS='-L$(PREFIX)/$(TARGET)/mingw/lib' \
RCFLAGS='-I$(PREFIX)/$(TARGET)/mingw/include'

# Override GCC patches with our own patches
gcc_PATCHES := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/gcc-[0-9]*.patch)))

# Point native system header dir to /mingw/include
# and compile without optimizations / stripping
gcc_CONFIGURE_OPTS=--with-build-sysroot='$(PREFIX)/$(TARGET)' \
--with-native-system-header-dir='/mingw/include' \
CFLAGS='' \
CXXFLAGS='' \
LDFLAGS=''

# The trick here is to symlink all files from /mingw/{bin,lib,include}/
# to $(PREFIX)/$(TARGET) after building MinGW-w64
# This ensures that all files are found during linking and that we
# can clean up those unnecessary files afterwards
define gcc_BUILD_x86_64-w64-mingw32
    $(subst @gcc-crt-config-opts@,--disable-lib32 $(common_CONFIGURE_OPTS), \
    $(subst winpthreads/configure' $(MXE_CONFIGURE_OPTS),winpthreads/configure' $(MXE_CONFIGURE_OPTS) $(common_CONFIGURE_OPTS), \
    $(gcc_BUILD_mingw-w64)))
    ln -sf '$(PREFIX)/$(TARGET)/mingw/bin/'* '$(PREFIX)/$(TARGET)/bin'
    ln -sf '$(PREFIX)/$(TARGET)/mingw/lib/'* '$(PREFIX)/$(TARGET)/lib'
    ln -sf '$(PREFIX)/$(TARGET)/mingw/include/'* '$(PREFIX)/$(TARGET)/include'
endef

define gcc_BUILD_i686-w64-mingw32
    $(subst @gcc-crt-config-opts@,--disable-lib64 $(common_CONFIGURE_OPTS), \
    $(subst winpthreads/configure' $(MXE_CONFIGURE_OPTS),winpthreads/configure' $(MXE_CONFIGURE_OPTS) $(common_CONFIGURE_OPTS), \
    $(gcc_BUILD_mingw-w64)))
    ln -sf '$(PREFIX)/$(TARGET)/mingw/bin/'* '$(PREFIX)/$(TARGET)/bin'
    ln -sf '$(PREFIX)/$(TARGET)/mingw/lib/'* '$(PREFIX)/$(TARGET)/lib'
    ln -sf '$(PREFIX)/$(TARGET)/mingw/include/'* '$(PREFIX)/$(TARGET)/include'
endef

define llvm-mingw_BUILD_x86_64-w64-mingw32
    $(subst @mingw-crt-config-opts@,--disable-lib32 --enable-lib64 $(common_CONFIGURE_OPTS),$(llvm-mingw_BUILD_mingw-w64))
    ln -sf '$(PREFIX)/$(TARGET)/mingw/bin/'* '$(PREFIX)/$(TARGET)/bin'
    ln -sf '$(PREFIX)/$(TARGET)/mingw/lib/'* '$(PREFIX)/$(TARGET)/lib'
    ln -sf '$(PREFIX)/$(TARGET)/mingw/include/'* '$(PREFIX)/$(TARGET)/include'
endef

define llvm-mingw_BUILD_i686-w64-mingw32
    $(subst @mingw-crt-config-opts@,--enable-lib32 --disable-lib64 $(common_CONFIGURE_OPTS),$(llvm-mingw_BUILD_mingw-w64))
    ln -sf '$(PREFIX)/$(TARGET)/mingw/bin/'* '$(PREFIX)/$(TARGET)/bin'
    ln -sf '$(PREFIX)/$(TARGET)/mingw/lib/'* '$(PREFIX)/$(TARGET)/lib'
    ln -sf '$(PREFIX)/$(TARGET)/mingw/include/'* '$(PREFIX)/$(TARGET)/include'
endef

define llvm-mingw_BUILD_armv7-w64-mingw32
    $(subst @mingw-crt-config-opts@,--disable-lib32 --disable-lib64 --enable-libarm32 $(common_CONFIGURE_OPTS),$(llvm-mingw_BUILD_mingw-w64))
    ln -sf '$(PREFIX)/$(TARGET)/mingw/bin/'* '$(PREFIX)/$(TARGET)/bin'
    ln -sf '$(PREFIX)/$(TARGET)/mingw/lib/'* '$(PREFIX)/$(TARGET)/lib'
    ln -sf '$(PREFIX)/$(TARGET)/mingw/include/'* '$(PREFIX)/$(TARGET)/include'
endef

define llvm-mingw_BUILD_aarch64-w64-mingw32
    $(subst @mingw-crt-config-opts@,--disable-lib32 --disable-lib64 --enable-libarm64 $(common_CONFIGURE_OPTS),$(llvm-mingw_BUILD_mingw-w64))
    ln -sf '$(PREFIX)/$(TARGET)/mingw/bin/'* '$(PREFIX)/$(TARGET)/bin'
    ln -sf '$(PREFIX)/$(TARGET)/mingw/lib/'* '$(PREFIX)/$(TARGET)/lib'
    ln -sf '$(PREFIX)/$(TARGET)/mingw/include/'* '$(PREFIX)/$(TARGET)/include'
endef

## Update dependencies

# upstream version is 3.2.1
libffi_VERSION  := 3.3
libffi_CHECKSUM := 72fba7922703ddfa7a028d513ac15a85c8d54c8d67f55fa5a4802885dc652056
libffi_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/libffi-[0-9]*.patch)))
libffi_SUBDIR   := libffi-$(libffi_VERSION)
libffi_FILE     := libffi-$(libffi_VERSION).tar.gz
libffi_URL      := https://www.mirrorservice.org/sites/sourceware.org/pub/libffi/$(libffi_FILE)
libffi_URL_2    := https://sourceware.org/pub/libffi/$(libffi_FILE)

# upstream version is 2.32.3
gdk-pixbuf_VERSION  := 2.40.0
gdk-pixbuf_CHECKSUM := 1582595099537ca8ff3b99c6804350b4c058bb8ad67411bbaae024ee7cead4e6
gdk-pixbuf_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/gdk-pixbuf-[0-9]*.patch)))
gdk-pixbuf_SUBDIR   := gdk-pixbuf-$(gdk-pixbuf_VERSION)
gdk-pixbuf_FILE     := gdk-pixbuf-$(gdk-pixbuf_VERSION).tar.xz
gdk-pixbuf_URL      := https://download.gnome.org/sources/gdk-pixbuf/$(call SHORT_PKG_VERSION,gdk-pixbuf)/$(gdk-pixbuf_FILE)

# upstream version is 1.5.2
# cannot use GH_CONF:
# matio_GH_CONF  := tbeu/matio/releases,v
matio_VERSION  := 1.5.17
matio_CHECKSUM := 5e455527d370ab297c4abe5a2ab4d599c93ac7c1a0c85d841cc5c22f8221c400
matio_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/matio-[0-9]*.patch)))
matio_SUBDIR   := matio-$(matio_VERSION)
matio_FILE     := matio-$(matio_VERSION).tar.gz
matio_URL      := https://github.com/tbeu/matio/releases/download/v$(matio_VERSION)/$(matio_FILE)

# upstream version is 7, we want ImageMagick 6
imagemagick_VERSION  := 6.9.10-92
imagemagick_CHECKSUM := 170cff8a401e958692513d19290b12bb63a7af48d19a2f7640fbfe7dede60f3a
imagemagick_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/imagemagick-[0-9]*.patch)))
imagemagick_GH_CONF  := ImageMagick/ImageMagick6/tags

# upstream version is 2.4
x265_VERSION  := 3.2.1
x265_CHECKSUM := fb9badcf92364fd3567f8b5aa0e5e952aeea7a39a2b864387cec31e3b58cbbcc
x265_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/x265-[0-9]*.patch)))
x265_SUBDIR   := x265_$(x265_VERSION)
x265_FILE     := x265_$(x265_VERSION).tar.gz
x265_URL      := https://bitbucket.org/multicoreware/x265/downloads/$(x265_FILE)
x265_URL_2    := ftp://ftp.videolan.org/pub/videolan/x265/$(x265_FILE)

# upstream version is 2.40.5
librsvg_VERSION  := 2.48.0
librsvg_CHECKSUM := 4a348b76cf4c52838e9c337ca767a38fe7f742db40ccccf8ac99f1946872cda6
librsvg_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/librsvg-[0-9]*.patch)))
librsvg_SUBDIR   := librsvg-$(librsvg_VERSION)
librsvg_FILE     := librsvg-$(librsvg_VERSION).tar.xz
librsvg_URL      := https://download.gnome.org/sources/librsvg/$(call SHORT_PKG_VERSION,librsvg)/$(librsvg_FILE)

# upstream version is 1.37.4
pango_VERSION  := 1.44.7
pango_CHECKSUM := 66a5b6cc13db73efed67b8e933584509f8ddb7b10a8a40c3850ca4a985ea1b1f
pango_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/pango-[0-9]*.patch)))
pango_SUBDIR   := pango-$(pango_VERSION)
pango_FILE     := pango-$(pango_VERSION).tar.xz
pango_URL      := https://download.gnome.org/sources/pango/$(call SHORT_PKG_VERSION,pango)/$(pango_FILE)

# upstream version is 1.0.5
# cannot use GH_CONF:
# fribidi_GH_CONF  := fribidi/fribidi/releases,v
fribidi_VERSION  := 1.0.9
fribidi_CHECKSUM := c5e47ea9026fb60da1944da9888b4e0a18854a0e2410bbfe7ad90a054d36e0c7
fribidi_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/fribidi-[0-9]*.patch)))
fribidi_SUBDIR   := fribidi-$(fribidi_VERSION)
fribidi_FILE     := fribidi-$(fribidi_VERSION).tar.xz
fribidi_URL      := https://github.com/fribidi/fribidi/releases/download/v$(fribidi_VERSION)/$(fribidi_FILE)

# upstream version is 1.0.3
libwebp_VERSION  := 1.1.0
libwebp_CHECKSUM := 98a052268cc4d5ece27f76572a7f50293f439c17a98e67c4ea0c7ed6f50ef043
libwebp_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/libwebp-[0-9]*.patch)))
libwebp_SUBDIR   := libwebp-$(libwebp_VERSION)
libwebp_FILE     := libwebp-$(libwebp_VERSION).tar.gz
libwebp_URL      := http://downloads.webmproject.org/releases/webp/$(libwebp_FILE)

# upstream version is 2.50.2
glib_VERSION  := 2.64.1
glib_CHECKSUM := 17967603bcb44b6dbaac47988d80c29a3d28519210b28157c2bd10997595bbc7
glib_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/glib-[0-9]*.patch)))
glib_SUBDIR   := glib-$(glib_VERSION)
glib_FILE     := glib-$(glib_VERSION).tar.xz
glib_URL      := https://download.gnome.org/sources/glib/$(call SHORT_PKG_VERSION,glib)/$(glib_FILE)

# upstream version is 1.14.30
libgsf_VERSION  := 1.14.46
libgsf_CHECKSUM := ea36959b1421fc8e72caa222f30ec3234d0ed95990e2bf28943a85f33eadad2d
libgsf_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/libgsf-[0-9]*.patch)))
libgsf_SUBDIR   := libgsf-$(libgsf_VERSION)
libgsf_FILE     := libgsf-$(libgsf_VERSION).tar.xz
libgsf_URL      := https://download.gnome.org/sources/libgsf/$(call SHORT_PKG_VERSION,libgsf)/$(libgsf_FILE)

# upstream version is 1.16.0
cairo_VERSION  := 1.17.2
cairo_CHECKSUM := 6b70d4655e2a47a22b101c666f4b29ba746eda4aa8a0f7255b32b2e9408801df
cairo_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/cairo-[0-9]*.patch)))
cairo_SUBDIR   := cairo-$(cairo_VERSION)
cairo_FILE     := cairo-$(cairo_VERSION).tar.xz
cairo_URL      := http://cairographics.org/snapshots/$(cairo_FILE)

# upstream version is 2.2.0
# cannot use GH_CONF:
# openexr_GH_CONF  := AcademySoftwareFoundation/openexr/tags
openexr_VERSION  := 2.4.1
openexr_CHECKSUM := 3ebbe9a8e67edb4a25890b98c598e9fe23b10f96d1416d6a3ff0732e99d001c1
openexr_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/openexr-[0-9]*.patch)))
openexr_SUBDIR   := openexr-$(openexr_VERSION)
openexr_FILE     := openexr-$(openexr_VERSION).tar.gz
openexr_URL      := https://github.com/AcademySoftwareFoundation/openexr/archive/v$(openexr_VERSION).tar.gz

# upstream version is 2.2.0
# cannot use GH_CONF:
# ilmbase_GH_CONF  := openexr/openexr/tags
ilmbase_VERSION  := $(openexr_VERSION)
ilmbase_CHECKSUM := $(openexr_CHECKSUM)
ilmbase_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/ilmbase-[0-9]*.patch)))
ilmbase_SUBDIR   := $(openexr_SUBDIR)
ilmbase_FILE     := $(openexr_FILE)
ilmbase_URL      := $(openexr_URL)

# upstream version is 3410
cfitsio_VERSION  := 3.47
cfitsio_CHECKSUM := 418516f10ee1e0f1b520926eeca6b77ce639bed88804c7c545e74f26b3edf4ef
cfitsio_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/cfitsio-[0-9]*.patch)))
cfitsio_SUBDIR   := cfitsio-$(cfitsio_VERSION)
cfitsio_FILE     := cfitsio-$(cfitsio_VERSION).tar.gz
cfitsio_URL      := https://heasarc.gsfc.nasa.gov/FTP/software/fitsio/c/$(cfitsio_FILE)
cfitsio_URL_2    := https://mirrorservice.org/sites/distfiles.macports.org/cfitsio/$(cfitsio_FILE)

# upstream version is 0.33.6
pixman_VERSION  := 0.38.4
pixman_CHECKSUM := da66d6fd6e40aee70f7bd02e4f8f76fc3f006ec879d346bae6a723025cfbdde7
pixman_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/pixman-[0-9]*.patch)))
pixman_SUBDIR   := pixman-$(pixman_VERSION)
pixman_FILE     := pixman-$(pixman_VERSION).tar.gz
pixman_URL      := https://cairographics.org/releases/$(pixman_FILE)

# upstream version is 2.13.1
fontconfig_VERSION  := 2.13.92
fontconfig_CHECKSUM := 506e61283878c1726550bc94f2af26168f1e9f2106eac77eaaf0b2cdfad66e4e
fontconfig_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/fontconfig-[0-9]*.patch)))
fontconfig_SUBDIR   := fontconfig-$(fontconfig_VERSION)
fontconfig_FILE     := fontconfig-$(fontconfig_VERSION).tar.xz
fontconfig_URL      := https://www.freedesktop.org/software/fontconfig/release/$(fontconfig_FILE)

# upstream version is 1.8.12
hdf5_VERSION  := 1.10.6
hdf5_CHECKSUM := 09d6301901685201bb272a73e21c98f2bf7e044765107200b01089104a47c3bd
hdf5_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/hdf5-[0-9]*.patch)))
hdf5_SUBDIR   := hdf5-$(hdf5_VERSION)
hdf5_FILE     := hdf5-$(hdf5_VERSION).tar.bz2
hdf5_URL      := https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-$(call SHORT_PKG_VERSION,hdf5)/hdf5-$(hdf5_VERSION)/src/$(hdf5_FILE)

## Patches that we override with our own

libjpeg-turbo_PATCHES := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/libjpeg-turbo-[0-9]*.patch)))
poppler_PATCHES := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/poppler-[0-9]*.patch)))
libxml2_PATCHES := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/libxml2-[0-9]*.patch)))
fftw_PATCHES := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/fftw-[0-9]*.patch)))

# zlib will make libzlib.dll, but we want libz.dll so we must
# patch CMakeLists.txt
zlib_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/zlib-[0-9]*.patch)))

## Override sub-dependencies
# HarfBuzz:
#  Removed: icu4c
# libgsf:
#  Removed: bzip2
# freetype:
#  Removed: bzip2
# freetype-bootstrap:
#  Removed: bzip2
# GLib:
#  Removed: dbus, libiconv, pcre
# GDK-PixBuf:
#  Removed: jasper, libiconv
#  Replaced: jpeg with libjpeg-turbo
# lcms:
#  Removed: jpeg, tiff
# TIFF:
#  Replaced: jpeg with libjpeg-turbo
# ImageMagick:
#  Added: libxml2, openjpeg
#  Removed: bzip2, ffmpeg, fftw, freetype, jasper, liblqr-1, libltdl, libpng, openexr, pthreads, tiff, zlib
#  Replaced: jpeg with libjpeg-turbo
# OpenEXR:
#  Added: $(BUILD)~cmake
#  Removed: pthreads
# IlmBase:
#  Added: $(BUILD)~cmake
# Pango:
#  Added: fribidi
# Poppler:
#  Removed: curl, qtbase, libwebp
#  Added: mingw-std-threads, libjpeg-turbo, lcms
# librsvg:
#  Removed: libcroco, libgsf
#  Added: libxml2, rust
# libwebp:
#  Added: gettext
# Cairo:
#  Removed: lzo zlib
# hdf5:
#  Added: $(BUILD)~cmake
#  Removed: pthreads
# x265:
#  Replaced: yasm with $(BUILD)~nasm

harfbuzz_DEPS           := $(filter-out icu4c,$(harfbuzz_DEPS))
libgsf_DEPS             := $(filter-out bzip2 ,$(libgsf_DEPS))
freetype_DEPS           := $(filter-out bzip2 ,$(freetype_DEPS))
freetype-bootstrap_DEPS := $(filter-out bzip2 ,$(freetype-bootstrap_DEPS))
glib_DEPS               := cc gettext libffi zlib
gdk-pixbuf_DEPS         := cc glib libjpeg-turbo libpng tiff
lcms_DEPS               := $(filter-out jpeg tiff ,$(lcms_DEPS))
tiff_DEPS               := cc libjpeg-turbo libwebp xz zlib
imagemagick_DEPS        := cc libxml2 openjpeg lcms libjpeg-turbo
openexr_DEPS            := cc ilmbase zlib $(BUILD)~cmake
ilmbase_DEPS            := cc $(BUILD)~cmake
pango_DEPS              := $(pango_DEPS) fribidi
poppler_DEPS            := cc mingw-std-threads cairo libjpeg-turbo freetype glib openjpeg lcms libpng tiff zlib
librsvg_DEPS            := $(filter-out libcroco libgsf ,$(librsvg_DEPS)) libxml2 rust
libwebp_DEPS            := $(libwebp_DEPS) gettext
cairo_DEPS              := cc fontconfig freetype-bootstrap glib libpng pixman
hdf5_DEPS               := $(filter-out pthreads ,$(hdf5_DEPS)) $(BUILD)~cmake
x265_DEPS               := $(subst yasm,$(BUILD)~nasm,$(x265_DEPS))

## Override build scripts

# libasprintf isn't needed, so build with --disable-libasprintf
define gettext_BUILD
    cd '$(SOURCE_DIR)' && autoreconf -fi
    cd '$(BUILD_DIR)' && '$(SOURCE_DIR)/gettext-runtime/configure' \
        $(MXE_CONFIGURE_OPTS) \
        --enable-threads=win32 \
        --without-libexpat-prefix \
        --without-libxml2-prefix \
        --disable-libasprintf \
        CONFIG_SHELL=$(SHELL)
    $(MAKE) -C '$(BUILD_DIR)/intl' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)/intl' -j 1 install
endef

# disable version script on llvm-mingw
define libffi_BUILD
    # build and install the library
    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        $(MXE_CONFIGURE_OPTS) \
        --disable-multi-os-directory \
        $(if $(BUILD_STATIC), --disable-raw-api) \
        $(if $(IS_LLVM), --disable-symvers)

    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install

    '$(TARGET)-gcc' \
        -W -Wall -Werror -std=c99 -pedantic \
        '$(TEST_FILE)' -o '$(PREFIX)/$(TARGET)/bin/test-libffi.exe' \
        `'$(TARGET)-pkg-config' libffi --cflags --libs`
endef

# icu will pull in standard linux headers, which we don't want,
# build with CMake.
define harfbuzz_BUILD
    # mman-win32 is only a partial implementation
    cd '$(BUILD_DIR)' && $(TARGET)-cmake \
        -DHB_HAVE_GLIB=ON \
        -DHB_HAVE_FREETYPE=ON \
        -DHB_HAVE_ICU=OFF \
        -DHAVE_SYS_MMAN_H=OFF \
        -DHB_BUILD_UTILS=OFF \
        -DHB_BUILD_TESTS=OFF \
        '$(SOURCE_DIR)'
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install

    # create pkg-config file, see:
    # https://github.com/harfbuzz/harfbuzz/issues/896
    $(INSTALL) -d '$(PREFIX)/$(TARGET)/lib/pkgconfig'
    (echo 'prefix=$(PREFIX)/$(TARGET)'; \
     echo 'exec_prefix=$${prefix}'; \
     echo 'libdir=$${exec_prefix}/lib'; \
     echo 'includedir=$${prefix}/include'; \
     echo ''; \
     echo 'Name: $(PKG)'; \
     echo 'Version: $($(PKG)_VERSION)'; \
     echo 'Description: HarfBuzz text shaping library'; \
     echo 'Libs: -L$${libdir} -lharfbuzz'; \
     echo 'Cflags: -I$${includedir}/harfbuzz';) \
     > '$(PREFIX)/$(TARGET)/lib/pkgconfig/$(PKG).pc'
endef

define freetype_BUILD
    # alias libharfbuzz and libfreetype to satisfy circular dependence
    # libfreetype should already have been created by freetype-bootstrap.mk
    $(if $(BUILD_STATIC), \
        ln -sf libharfbuzz.a '$(PREFIX)/$(TARGET)/lib/libharfbuzz_too.a' \
        && ln -sf libfreetype.a '$(PREFIX)/$(TARGET)/lib/libfreetype_too.a',)
    $($(PKG)_BUILD_COMMON)
    # remove circular dependencies from pc file
    $(if $(BUILD_STATIC), \
        $(SED) -i '/^Libs.private:/s/\-lharfbuzz_too -lfreetype_too//g' '$(PREFIX)/$(TARGET)/lib/pkgconfig/freetype2.pc')
endef

# exclude bz2 and gdk-pixbuf
define libgsf_BUILD
    $(SED) -i 's,\ssed\s, $(SED) ,g'           '$(SOURCE_DIR)'/gsf/Makefile.in

    # need to regenerate the configure script
    cd '$(SOURCE_DIR)' && autoreconf -fi

    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        $(MXE_CONFIGURE_OPTS) \
        --disable-nls \
        --without-gdk-pixbuf \
        --disable-gtk-doc \
        --without-python \
        --without-bz2 \
        --with-zlib \
        --with-gio \
        PKG_CONFIG='$(PREFIX)/bin/$(TARGET)-pkg-config'
    $(MAKE) -C '$(BUILD_DIR)'     -j '$(JOBS)' install-pkgconfigDATA $(MXE_DISABLE_PROGRAMS)
    $(MAKE) -C '$(BUILD_DIR)/gsf' -j 1 install $(MXE_DISABLE_PROGRAMS)
endef

# build gdk-pixbuf with libjpeg-turbo
# and the Meson build system
define gdk-pixbuf_BUILD
    '$(TARGET)-meson' \
        --buildtype=release \
        --strip \
        --libdir='lib' \
        --bindir='bin' \
        --libexecdir='bin' \
        --includedir='include' \
        -Dbuiltin_loaders='jpeg,png,tiff' \
        -Dgir=false \
        -Dx11=false \
        '$(SOURCE_DIR)' \
        '$(BUILD_DIR)'

    ninja -C '$(BUILD_DIR)' install
endef

# build pixman with the Meson build system
define pixman_BUILD
    '$(TARGET)-meson' \
        --buildtype=release \
        --strip \
        --libdir='lib' \
        --bindir='bin' \
        --libexecdir='bin' \
        --includedir='include' \
        -Dgtk=disabled \
        '$(SOURCE_DIR)' \
        '$(BUILD_DIR)'

    ninja -C '$(BUILD_DIR)' install
endef

# build fribidi with the Meson build system
define fribidi_BUILD
    '$(TARGET)-meson' \
        --buildtype=release \
        --strip \
        --libdir='lib' \
        --bindir='bin' \
        --libexecdir='bin' \
        --includedir='include' \
        -Ddocs=false \
        '$(SOURCE_DIR)' \
        '$(BUILD_DIR)'

    ninja -C '$(BUILD_DIR)' install
endef

# exclude jpeg, tiff dependencies
# build with -DCMS_RELY_ON_WINDOWS_STATIC_MUTEX_INIT to avoid a
# horrible hack (we don't target pre-Windows XP, so it should be safe)
define lcms_BUILD
    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        $(MXE_CONFIGURE_OPTS) \
        --with-zlib \
        CFLAGS="$(CFLAGS) -DCMS_RELY_ON_WINDOWS_STATIC_MUTEX_INIT"
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' $(MXE_DISABLE_PROGRAMS)
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install $(MXE_DISABLE_PROGRAMS)
endef

# disable largefile support, we rely on vips for that and ImageMagick's
# detection does not work when cross-compiling
# build with jpeg-turbo and without lzma
# disable POSIX threads with --without-threads, use Win32 threads instead
# exclude deprecated methods in MagickCore API
define imagemagick_BUILD
    # avoid linking against -lgdi32, see: https://github.com/kleisauke/net-vips/issues/61
    $(SED) -i 's,-lgdi32,,g' $(SOURCE_DIR)/configure

    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        $(MXE_CONFIGURE_OPTS) \
        --without-fftw \
        --without-fontconfig \
        --without-gvc \
        --without-heic \
        --without-ltdl \
        --without-lqr \
        --without-lzma \
        --without-magick-plus-plus \
        --without-modules \
        --without-openexr \
        --without-pango \
        --without-png \
        --without-rsvg \
        --without-tiff \
        --without-webp \
        --without-x \
        --without-zlib \
        --without-threads \
        --disable-largefile \
        --disable-opencl \
        --disable-openmp \
        CFLAGS="$(CFLAGS) -DMAGICKCORE_EXCLUDE_DEPRECATED"
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' $(MXE_DISABLE_CRUFT)
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install $(MXE_DISABLE_CRUFT)
endef

# WITH_TURBOJPEG=OFF turns off a library we don't use (we just use the
# libjpeg API)
define libjpeg-turbo_BUILD
    cd '$(BUILD_DIR)' && $(TARGET)-cmake \
        -DWITH_TURBOJPEG=OFF \
        -DENABLE_SHARED=$(CMAKE_SHARED_BOOL) \
        -DENABLE_STATIC=$(CMAKE_STATIC_BOOL) \
        -DCMAKE_ASM_NASM_COMPILER=$(TARGET)-yasm \
        '$(SOURCE_DIR)'
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install
endef

# disable GObject introspection
# build with the Meson build system
# force FontConfig since the Win32 font backend within Cairo is disabled
define pango_BUILD
    '$(TARGET)-meson' \
        --buildtype=release \
        --strip \
        --libdir='lib' \
        --libexecdir='bin' \
        --includedir='include' \
        -Dintrospection=false \
        -Duse_fontconfig=true \
        '$(SOURCE_DIR)' \
        '$(BUILD_DIR)'

    ninja -C '$(BUILD_DIR)' install
endef

# compile with the Rust toolchain
define librsvg_BUILD
    # We need to explicitly link against msvcrt-os after commit ae95d7c
    # on the mingw-w64 repo. Otherwise the __ms_vsnprintf symbol is
    # undefined during linking. The standard library of Rust appears
    # to link against this symbol by default.
    # Note: this can probably be removed when the standard library of
    # Rust is build with the latest mingw-w64 version (> v7.0.0).
    # TODO: Could we use this instead?:
    # LDFLAGS='$(LDFLAGS) -Wl,-u,___mingw_vsnprintf -Wl,--defsym,___ms_vsnprintf=___mingw_vsnprintf'
    $(if $(IS_LLVM), \
        $(SED) -i 's/^\(Libs:.*\)/\1 -lmsvcrt-os/' '$(SOURCE_DIR)/librsvg.pc.in')

    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        $(MXE_CONFIGURE_OPTS) \
        --disable-pixbuf-loader \
        --disable-gtk-doc \
        --disable-introspection \
        --disable-tools \
        RUST_TARGET='$(PROCESSOR)-pc-windows-gnu' \
        CARGO='$(TARGET)-cargo' \
        RUSTC='$(TARGET)-rustc' \
        $(if $(IS_LLVM), LIBS='-lmsvcrt-os -lucrt')

    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)' -j 1 $(INSTALL_STRIP_LIB)
endef

# compile with CMake and with libjpeg-turbo
define poppler_BUILD
    $(if $(findstring win32,$(TARGET)),\
        (cd '$(SOURCE_DIR)' && $(PATCH) -p1 -u) < $(realpath $(dir $(lastword $(poppler_PATCHES))))/poppler-mingw-std-threads.patch)

    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' \
        -DENABLE_TESTS=OFF \
        -DENABLE_ZLIB=ON \
        -DENABLE_LIBTIFF=ON \
        -DENABLE_LIBPNG=ON \
        -DENABLE_GLIB=ON \
        -DENABLE_CMS='lcms2' \
        -DENABLE_LIBOPENJPEG='openjpeg2' \
        -DENABLE_DCTDECODER='libjpeg' \
        -DFONT_CONFIGURATION=win32 \
        -DENABLE_UNSTABLE_API_ABI_HEADERS=OFF \
        -DENABLE_SPLASH=OFF \
        -DENABLE_CPP=OFF \
        -DBUILD_GTK_TESTS=OFF \
        -DENABLE_UTILS=OFF \
        -DENABLE_QT5=OFF \
        -DENABLE_LIBCURL=OFF \
        -DBUILD_QT5_TESTS=OFF \
        -DBUILD_CPP_TESTS=OFF \
        -DENABLE_GTK_DOC=OFF \
        $(if $(findstring win32,$(TARGET)), \
            -DCMAKE_CXX_FLAGS='$(CXXFLAGS) -I$(PREFIX)/$(TARGET)/include/mingw-std-threads' \
        $(else), \
            -DCMAKE_CXX_FLAGS='$(CXXFLAGS) -Wno-incompatible-ms-struct') \
        '$(SOURCE_DIR)'

    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install
endef

# the zlib configure is a bit basic, so use cmake for shared
# builds
define zlib_BUILD_SHARED
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' '$(SOURCE_DIR)'
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install

    # create pkg-config file
    $(INSTALL) -d '$(PREFIX)/$(TARGET)/lib/pkgconfig'
    (echo 'prefix=$(PREFIX)/$(TARGET)'; \
     echo 'exec_prefix=$${prefix}'; \
     echo 'libdir=$${exec_prefix}/lib'; \
     echo 'includedir=$${prefix}/include'; \
     echo ''; \
     echo 'Name: $(PKG)'; \
     echo 'Version: $($(PKG)_VERSION)'; \
     echo 'Description: $(PKG) compression library'; \
     echo 'Libs: -L$${libdir} -lz'; \
     echo 'Cflags: -I$${includedir}';) \
     > '$(PREFIX)/$(TARGET)/lib/pkgconfig/$(PKG).pc'
endef

# disable the C++ API for now, we don't use it anyway
# build with libjpeg-turbo and without lzma
define tiff_BUILD
    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        $(MXE_CONFIGURE_OPTS) \
        --without-x \
        --disable-cxx \
        --disable-lzma
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' $(MXE_DISABLE_CRUFT)
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install $(MXE_DISABLE_CRUFT)
endef

# disable unneeded loaders
define libwebp_BUILD
    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        $(MXE_CONFIGURE_OPTS) \
        --disable-gl \
        --disable-sdl \
        --disable-png \
        --disable-jpeg \
        --disable-tiff \
        --disable-gif \
        --enable-libwebpmux \
        --enable-libwebpdemux
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' $(MXE_DISABLE_PROGRAMS)
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install $(MXE_DISABLE_PROGRAMS)
endef

# replace libpng12 with libpng16
# node-canvas needs a Cairo with SVG support, so compile only with --disable-svg when building a statically linked binary
# disable the PDF backend, we use Poppler for that
# disable the Win32 surface and font backend to avoid having to link against -lgdi32 and -lmsimg32, see: https://github.com/kleisauke/net-vips/issues/61
# disable the PostScript backend
# ensure the FontConfig backend is enabled
define cairo_BUILD
    $(SED) -i 's,libpng12,libpng16,g'                        '$(SOURCE_DIR)/configure'
    $(SED) -i 's,^\(Libs:.*\),\1 @CAIRO_NONPKGCONFIG_LIBS@,' '$(SOURCE_DIR)/src/cairo.pc.in'
    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        $(MXE_CONFIGURE_OPTS) \
        --disable-gl \
        --disable-lto \
        --disable-gtk-doc \
        --disable-test-surfaces \
        --disable-gcov \
        --disable-xlib \
        --disable-xlib-xrender \
        --disable-xcb \
        --disable-quartz \
        --disable-quartz-font \
        --disable-quartz-image \
        --disable-os2 \
        --disable-beos \
        --disable-directfb \
        --disable-atomic \
        --disable-ps \
        --disable-script \
        --disable-pdf \
        $(if $(BUILD_STATIC), --disable-svg) \
        --disable-win32 \
        --disable-win32-font \
        --disable-interpreter \
        --enable-png \
        --enable-fc \
        --enable-ft \
        --without-x \
        CFLAGS="$(CFLAGS) $(if $(BUILD_STATIC),-DCAIRO_WIN32_STATIC_BUILD)" \
        $(if $(findstring win32,$(TARGET)), ax_cv_c_float_words_bigendian=no)

    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install $(MXE_DISABLE_PROGRAMS)
endef

define matio_BUILD
    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        $(MXE_CONFIGURE_OPTS) \
        ac_cv_va_copy=C99
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' $(MXE_DISABLE_CRUFT)
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install $(MXE_DISABLE_CRUFT)
endef

define matio_BUILD_SHARED
    $($(PKG)_BUILD)
endef

# build without lzma, disable the linker version script on llvm-mingw
define libxml2_BUILD
    $(SED) -i 's,`uname`,MinGW,g' '$(1)/xml2-config.in'

    # need to regenerate the configure script
    cd '$(SOURCE_DIR)' && autoreconf -fi

    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        $(MXE_CONFIGURE_OPTS) \
        --with-zlib='$(PREFIX)/$(TARGET)/lib' \
        --without-lzma \
        --without-debug \
        --without-python \
        --without-threads \
        $(if $(IS_LLVM), --disable-ld-version-script)
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' $(MXE_DISABLE_CRUFT)
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install $(MXE_DISABLE_CRUFT)
    ln -sf '$(PREFIX)/$(TARGET)/bin/xml2-config' '$(PREFIX)/bin/$(TARGET)-xml2-config'
endef

# build with the Meson build system
# compile with the internal PCRE library
define glib_BUILD
    # other packages expect glib-tools in $(TARGET)/bin
    rm -f  '$(PREFIX)/$(TARGET)/bin/glib-*'
    ln -sf '$(PREFIX)/$(BUILD)/bin/glib-genmarshal'        '$(PREFIX)/$(TARGET)/bin/'
    ln -sf '$(PREFIX)/$(BUILD)/bin/glib-compile-schemas'   '$(PREFIX)/$(TARGET)/bin/'
    ln -sf '$(PREFIX)/$(BUILD)/bin/glib-compile-resources' '$(PREFIX)/$(TARGET)/bin/'

    $(if $(BUILD_STATIC), \
        (cd '$(SOURCE_DIR)' && $(PATCH) -p1 -u) < $(realpath $(dir $(lastword $(glib_PATCHES))))/glib-static.patch)

    # cross build
    # build as shared library, since we need `libgobject-2.0-0.dll`
    # and `libglib-2.0-0.dll` for the language bindings.
    '$(TARGET)-meson' \
        --default-library=shared \
        --buildtype=release \
        --strip \
        --libdir='lib' \
        --bindir='bin' \
        --libexecdir='bin' \
        --includedir='include' \
        -Dforce_posix_threads=false \
        -Dinternal_pcre=true \
        -Diconv='external' \
        '$(SOURCE_DIR)' \
        '$(BUILD_DIR)'

    ninja -C '$(BUILD_DIR)' install
endef

# build with CMake.
define openexr_BUILD
    echo "patches: $(ilmbase_PATCHES)"
    $(foreach PKG_PATCH,$(ilmbase_PATCHES), \
        echo $(PKG_PATCH); \
        (cd '$(SOURCE_DIR)' && $(PATCH) -p1 -u) < $(PKG_PATCH))
    mkdir -p '$(BUILD_DIR)/native/IlmBase'
    mkdir '$(BUILD_DIR)/cross'
    cd '$(BUILD_DIR)/native/IlmBase' && cmake \
        -DOPENEXR_CXX_STANDARD=14 \
        -DCMAKE_INSTALL_PREFIX='$(BUILD_DIR)/native/IlmBase/install'\
        '$(SOURCE_DIR)/IlmBase'
    $(MAKE) -C '$(BUILD_DIR)/native/IlmBase' -j '$(JOBS)' install

    cd '$(BUILD_DIR)/native' && cmake \
        -DOPENEXR_CXX_STANDARD=14 \
        -DIlmBase_DIR='$(BUILD_DIR)/native/IlmBase/install/lib/cmake/IlmBase'\
        '$(SOURCE_DIR)/OpenEXR'
    $(MAKE) -C '$(BUILD_DIR)/native/IlmImf' -j '$(JOBS)'

    cd '$(BUILD_DIR)/cross' && $(TARGET)-cmake \
        -DOPENEXR_CXX_STANDARD=14 \
        -DOPENEXR_INSTALL_PKG_CONFIG=ON \
        -DNATIVE_OPENEXR_BUILD_DIR='$(BUILD_DIR)/native' \
        -DBUILD_TESTING=OFF \
        -DOPENEXR_BUILD_UTILS=OFF \
        '$(SOURCE_DIR)/OpenEXR'
    $(MAKE) -C '$(BUILD_DIR)/cross' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)/cross' -j 1 install
endef

# build with CMake.
define ilmbase_BUILD
    mkdir '$(BUILD_DIR)/native'
    mkdir '$(BUILD_DIR)/cross'
    cd '$(BUILD_DIR)/native' && cmake \
        -DOPENEXR_CXX_STANDARD=14 \
        '$(SOURCE_DIR)/IlmBase'
    $(MAKE) -C '$(BUILD_DIR)/native/Half' -j '$(JOBS)'

    cd '$(BUILD_DIR)/cross' && $(TARGET)-cmake \
        $(if $(findstring win32,$(TARGET)), -DILMBASE_FORCE_CXX03=ON) \
        -DOPENEXR_CXX_STANDARD=14 \
        -DNATIVE_ILMBASE_BUILD_DIR='$(BUILD_DIR)/native' \
        -DBUILD_TESTING=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DILMBASE_INSTALL_PKG_CONFIG=ON \
        '$(SOURCE_DIR)/IlmBase'
    $(MAKE) -C '$(BUILD_DIR)/cross' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)/cross' -j 1 install
endef

define cfitsio_BUILD_SHARED
    cd '$(BUILD_DIR)' && $(TARGET)-cmake \
        -DBUILD_SHARED_LIBS=ON \
        '$(SOURCE_DIR)'

    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install

    # create pkg-config files
    $(INSTALL) -d '$(PREFIX)/$(TARGET)/lib/pkgconfig'
    (echo 'Name: $(PKG)'; \
     echo 'Version: $($(PKG)_VERSION)'; \
     echo 'Libs: -l$(PKG)';) \
     > '$(PREFIX)/$(TARGET)/lib/pkgconfig/$(PKG).pc'

    '$(TARGET)-gcc' \
        -W -Wall -Werror -ansi \
        '$(TEST_FILE)' -o '$(PREFIX)/$(TARGET)/bin/test-cfitsio.exe' \
        `'$(TARGET)-pkg-config' cfitsio --cflags --libs`
endef

# build with CMake.
define hdf5_BUILD
    mkdir '$(BUILD_DIR)/native'
    mkdir '$(BUILD_DIR)/cross'

    # TODO: Do we need to generate H5lib_settings.c and H5Tinit.c on
    # the host system instead?
    cd '$(BUILD_DIR)/native' && cmake \
        -DBUILD_SHARED_LIBS=$(CMAKE_SHARED_BOOL) \
        -DONLY_SHARED_LIBS=$(CMAKE_SHARED_BOOL) \
        -DBUILD_TESTING=OFF \
        -DHDF5_BUILD_TOOLS=OFF \
        -DHDF5_BUILD_EXAMPLES=OFF \
        -DHDF5_BUILD_HL_LIB=OFF \
        -DHDF5_GENERATE_HEADERS=OFF \
        '$(SOURCE_DIR)'
    $(MAKE) -C '$(BUILD_DIR)/native' -j '$(JOBS)' gen_hdf5-$(if $(BUILD_STATIC),static,shared)
    cp '$(BUILD_DIR)/native/H5lib_settings.c' '$(BUILD_DIR)/cross'

    # H5_HAVE_IOEO=1 requires WINVER >= 0x600
    cd '$(BUILD_DIR)/cross' && '$(TARGET)-cmake' \
        -DONLY_SHARED_LIBS=$(CMAKE_SHARED_BOOL) \
        -DH5_ENABLE_SHARED_LIB=$(CMAKE_SHARED_BOOL) \
        -DH5_ENABLE_STATIC_LIB=$(CMAKE_STATIC_BOOL) \
        -DH5_PRINTF_LL_WIDTH='"ll"' \
        -DH5_LDOUBLE_TO_LONG_SPECIAL=OFF \
        -DH5_LONG_TO_LDOUBLE_SPECIAL=OFF \
        -DH5_LDOUBLE_TO_LLONG_ACCURATE=ON \
        -DH5_LLONG_TO_LDOUBLE_CORRECT=ON \
        -DH5_DISABLE_SOME_LDOUBLE_CONV=OFF \
        -DH5_NO_ALIGNMENT_RESTRICTIONS=ON \
        -DH5_HAVE_IOEO=$(if $(IS_LLVM),1,0) \
        -DTEST_LFS_WORKS_RUN=0 \
        -DHDF5_ENABLE_THREADSAFE=ON \
        -DHDF5_USE_PREGEN=ON \
        -DHDF5_USE_PREGEN_DIR='$(BUILD_DIR)/native' \
        -DBUILD_TESTING=OFF \
        -DHDF5_BUILD_TOOLS=OFF \
        -DHDF5_BUILD_EXAMPLES=OFF \
        -DHDF5_BUILD_HL_LIB=OFF \
        -DHDF5_GENERATE_HEADERS=OFF \
        '$(SOURCE_DIR)'
    $(MAKE) -C '$(BUILD_DIR)/cross' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)/cross' -j 1 install

    # setup cmake toolchain
    (echo 'set(HDF5_C_COMPILER_EXECUTABLE $(PREFIX)/bin/$(TARGET)-h5cc)'; \
     echo 'set(HDF5_CXX_COMPILER_EXECUTABLE $(PREFIX)/bin/$(TARGET)-h5c++)'; \
     ) > '$(CMAKE_TOOLCHAIN_DIR)/$(PKG).cmake'
endef

# `-DENABLE_DYNAMIC_HDR10=ON` -> `-DENABLE_HDR10_PLUS=ON`
# x265 requires nasm 2.13 or newer (instead than yasm) after release 2.6.
define x265_BUILD
    cd '$(BUILD_DIR)' && mkdir -p 10bit 12bit

    # 12 bit
    cd '$(BUILD_DIR)/12bit' && $(TARGET)-cmake '$(SOURCE_DIR)/source' \
        -DHIGH_BIT_DEPTH=ON \
        -DEXPORT_C_API=OFF \
        -DENABLE_SHARED=OFF \
        -DENABLE_ASSEMBLY=$(if $(findstring x86_64,$(TARGET)),ON,OFF) \
        -DENABLE_CLI=OFF \
        -DWINXP_SUPPORT=ON \
        -DENABLE_HDR10_PLUS=ON \
        -DMAIN12=ON
    $(MAKE) -C '$(BUILD_DIR)/12bit' -j '$(JOBS)'
    cp '$(BUILD_DIR)/12bit/libx265.a' '$(BUILD_DIR)/libx265_main12.a'

    # 10 bit
    cd '$(BUILD_DIR)/10bit' && $(TARGET)-cmake '$(SOURCE_DIR)/source' \
        -DHIGH_BIT_DEPTH=ON \
        -DEXPORT_C_API=OFF \
        -DENABLE_SHARED=OFF \
        -DENABLE_ASSEMBLY=$(if $(findstring x86_64,$(TARGET)),ON,OFF) \
        -DENABLE_CLI=OFF \
        -DWINXP_SUPPORT=ON \
        -DENABLE_HDR10_PLUS=ON
    $(MAKE) -C '$(BUILD_DIR)/10bit' -j '$(JOBS)'
    cp '$(BUILD_DIR)/10bit/libx265.a' '$(BUILD_DIR)/libx265_main10.a'

    # 8bit
    cd '$(BUILD_DIR)' && $(TARGET)-cmake '$(SOURCE_DIR)/source' \
        -DHIGH_BIT_DEPTH=OFF \
        -DEXPORT_C_API=ON \
        -DENABLE_SHARED=$(CMAKE_SHARED_BOOL) \
        -DENABLE_ASSEMBLY=$(if $(findstring x86_64,$(TARGET)),ON,OFF) \
        -DENABLE_CLI=OFF \
        -DWINXP_SUPPORT=ON \
        -DENABLE_HDR10_PLUS=ON \
        -DEXTRA_LIB='x265_main10.a;x265_main12.a' \
        -DEXTRA_LINK_FLAGS=-L'$(BUILD_DIR)' \
        -DLINKED_10BIT=ON \
        -DLINKED_12BIT=ON

    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' install
    $(if $(BUILD_SHARED),rm -f '$(PREFIX)/$(TARGET)/lib/libx265.a',\
        $(INSTALL) '$(BUILD_DIR)/libx265_main12.a' '$(PREFIX)/$(TARGET)/lib/libx265_main12.a' && \
        $(INSTALL) '$(BUILD_DIR)/libx265_main10.a' '$(PREFIX)/$(TARGET)/lib/libx265_main10.a' && \
        $(SED) -i 's|-lx265|-lx265 -lx265_main10 -lx265_main12|' '$(PREFIX)/$(TARGET)/lib/pkgconfig/x265.pc')

    '$(TARGET)-gcc' \
        -W -Wall -Werror \
        '$(TOP_DIR)/src/$(PKG)-test.c' \
        -o '$(PREFIX)/$(TARGET)/bin/test-$(PKG).exe' \
        `$(TARGET)-pkg-config --cflags --libs $(PKG)`
endef
