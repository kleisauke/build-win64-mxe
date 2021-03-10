PKG             := vips-all
$(PKG)_WEBSITE  := https://libvips.github.io/libvips/
$(PKG)_DESCR    := A fast image processing library with low memory needs.
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 8.10.6
$(PKG)_CHECKSUM := 50c34790f6244fbc1d2bc7b07c3531304e0edbd166c4175ac0bdd28786bcc9cd
$(PKG)_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/vips-[0-9]*.patch)))
$(PKG)_GH_CONF  := libvips/libvips/releases,v,-beta2
$(PKG)_SUBDIR   := vips-$($(PKG)_VERSION)
$(PKG)_FILE     := vips-$($(PKG)_VERSION).tar.gz
$(PKG)_DEPS     := cc libwebp librsvg giflib glib pango libgsf \
                   libjpeg-turbo tiff lcms libexif libheif libpng \
                   libspng libimagequant orc imagemagick matio openexr \
                   cfitsio nifticlib poppler fftw openslide

define $(PKG)_PRE_CONFIGURE
    # Copy some files to the packaging directory
    mkdir -p $(PREFIX)/$(TARGET)/vips-packaging
    $(foreach f,COPYING ChangeLog README.md AUTHORS, cp '$(SOURCE_DIR)/$f' '$(PREFIX)/$(TARGET)/vips-packaging';)

    (printf '{\n'; \
     printf '  "aom": "$(aom_VERSION)",\n'; \
     printf '  "cairo": "$(cairo_VERSION)",\n'; \
     printf '  "cfitsio": "$(cfitsio_VERSION)",\n'; \
     $(if $(IS_HEVC),printf '  "de265": "$(libde265_VERSION)"$(comma)\n';) \
     printf '  "exif": "$(libexif_VERSION)",\n'; \
     printf '  "expat": "$(expat_VERSION)",\n'; \
     printf '  "ffi": "$(libffi_VERSION)",\n'; \
     printf '  "fftw": "$(fftw_VERSION)",\n'; \
     printf '  "fontconfig": "$(fontconfig_VERSION)",\n'; \
     printf '  "freetype": "$(freetype_VERSION)",\n'; \
     printf '  "fribidi": "$(fribidi_VERSION)",\n'; \
     printf '  "gdkpixbuf": "$(gdk-pixbuf_VERSION)",\n'; \
     printf '  "gif": "$(giflib_VERSION)",\n'; \
     printf '  "glib": "$(glib_VERSION)",\n'; \
     printf '  "gsf": "$(libgsf_VERSION)",\n'; \
     printf '  "harfbuzz": "$(harfbuzz_VERSION)",\n'; \
     printf '  "hdf5": "$(hdf5_VERSION)",\n'; \
     printf '  "heif": "$(libheif_VERSION)",\n'; \
     printf '  "imagemagick": "$(imagemagick_VERSION)",\n'; \
     printf '  "imagequant": "$(libimagequant_VERSION)",\n'; \
     $(if $(IS_MOZJPEG),,printf '  "jpeg": "$(libjpeg-turbo_VERSION)"$(comma)\n';) \
     printf '  "lcms": "$(lcms_VERSION)",\n'; \
     printf '  "matio": "$(matio_VERSION)",\n'; \
     $(if $(IS_MOZJPEG),printf '  "mozjpeg": "$(mozjpeg_VERSION)"$(comma)\n';) \
     printf '  "nifti": "$(nifticlib_VERSION)",\n'; \
     printf '  "openexr": "$(openexr_VERSION)",\n'; \
     printf '  "openjpeg": "$(openjpeg_VERSION)",\n'; \
     printf '  "openslide": "$(openslide_VERSION)",\n'; \
     printf '  "orc": "$(orc_VERSION)",\n'; \
     printf '  "pango": "$(pango_VERSION)",\n'; \
     printf '  "pixman": "$(pixman_VERSION)",\n'; \
     printf '  "png": "$(libpng_VERSION)",\n'; \
     printf '  "poppler": "$(poppler_VERSION)",\n'; \
     printf '  "sqlite": "$(sqlite_VERSION)",\n'; \
     printf '  "svg": "$(librsvg_VERSION)",\n'; \
     printf '  "spng": "$(libspng_VERSION)",\n'; \
     printf '  "tiff": "$(tiff_VERSION)",\n'; \
     printf '  "vips": "$(vips-all_VERSION)",\n'; \
     printf '  "webp": "$(libwebp_VERSION)",\n'; \
     $(if $(IS_HEVC),printf '  "x265": "$(x265_VERSION)"$(comma)\n';) \
     printf '  "xml": "$(libxml2_VERSION)",\n'; \
     $(if $(IS_ZLIB_NG), \
          printf '  "zlib-ng": "$(zlib-ng_VERSION)"\n';, \
          printf '  "zlib": "$(zlib_VERSION)"\n';) \
     printf '}';) \
     > '$(PREFIX)/$(TARGET)/vips-packaging/versions.json'
endef

define $(PKG)_BUILD
    $($(PKG)_PRE_CONFIGURE)

    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        $(MXE_CONFIGURE_OPTS) \
        --enable-debug=no \
        --without-pdfium \
        --disable-introspection \
        --disable-deprecated

    # libtool should automatically generate a list
    # of exported symbols on llvm-mingw
    $(if $(IS_LLVM), \
        $(SED) -i '/^always_export_symbols=/s/=no/=yes/' '$(BUILD_DIR)/libtool')

    # remove -nostdlib from linker commandline options
    # https://debbugs.gnu.org/cgi/bugreport.cgi?bug=27866
    $(if $(IS_LLVM), \
        $(SED) -i '/\-shared /s/ \-nostdlib//' '$(BUILD_DIR)/libtool')

    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)' -j 1 $(INSTALL_STRIP_LIB)
endef
