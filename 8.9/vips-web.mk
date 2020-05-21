PKG             := vips-web
$(PKG)_WEBSITE  := https://libvips.github.io/libvips/
$(PKG)_DESCR    := A fast image processing library with low memory needs.
$(PKG)_IGNORE   :=
# https://github.com/libvips/libvips/tarball/c2165671e25981a0e06925c36ddeb1e66610a9c1
$(PKG)_VERSION  := c216567
$(PKG)_CHECKSUM := 1460884ad919e77b36ec241f4c0bf58ad256398a78d0f3a2e021bbbd41c627cf
$(PKG)_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/vips-[0-9]*.patch)))
$(PKG)_GH_CONF  := libvips/libvips/branches/libspng-experiment
$(PKG)_DEPS     := cc libwebp librsvg giflib glib pango libgsf \
                   libjpeg-turbo tiff lcms libexif libspng orc

define $(PKG)_PRE_CONFIGURE
    # Copy some files to the packaging directory
    mkdir -p $(TOP_DIR)/vips-packaging
    $(foreach f,COPYING ChangeLog README.md AUTHORS, mv '$(SOURCE_DIR)/$f' '$(TOP_DIR)/vips-packaging';)

    (printf '{\n'; \
     printf '  "cairo": "$(cairo_VERSION)",\n'; \
     printf '  "exif": "$(libexif_VERSION)",\n'; \
     printf '  "expat": "$(expat_VERSION)",\n'; \
     printf '  "ffi": "$(libffi_VERSION)",\n'; \
     printf '  "fontconfig": "$(fontconfig_VERSION)",\n'; \
     printf '  "freetype": "$(freetype_VERSION)",\n'; \
     printf '  "fribidi": "$(fribidi_VERSION)",\n'; \
     printf '  "gdkpixbuf": "$(gdk-pixbuf_VERSION)",\n'; \
     printf '  "gif": "$(giflib_VERSION)",\n'; \
     printf '  "glib": "$(glib_VERSION)",\n'; \
     printf '  "gsf": "$(libgsf_VERSION)",\n'; \
     printf '  "harfbuzz": "$(harfbuzz_VERSION)",\n'; \
     printf '  "jpeg": "$(libjpeg-turbo_VERSION)",\n'; \
     printf '  "lcms": "$(lcms_VERSION)",\n'; \
     printf '  "orc": "$(orc_VERSION)",\n'; \
     printf '  "pango": "$(pango_VERSION)",\n'; \
     printf '  "pixman": "$(pixman_VERSION)",\n'; \
     printf '  "png": "$(libpng_VERSION)",\n'; \
     printf '  "svg": "$(librsvg_VERSION)",\n'; \
     printf '  "spng": "$(libspng_VERSION)",\n'; \
     printf '  "tiff": "$(tiff_VERSION)",\n'; \
     printf '  "vips": "$(vips-web_VERSION)",\n'; \
     printf '  "webp": "$(libwebp_VERSION)",\n'; \
     printf '  "xml": "$(libxml2_VERSION)",\n'; \
     printf '  "zlib": "$(zlib_VERSION)"\n'; \
     printf '}';) \
     > '$(TOP_DIR)/vips-packaging/versions.json'
endef

define $(PKG)_BUILD
    $($(PKG)_PRE_CONFIGURE)

    $(SED) -i 's/$$\*/"$$@"/g' '$(SOURCE_DIR)/autogen.sh'
 
    # Always build as shared library, we need
    # libvips-42.dll for the language bindings.
    cd '$(SOURCE_DIR)' && ./autogen.sh \
        --host='$(TARGET)' \
        --build='$(BUILD)' \
        --prefix='$(PREFIX)/$(TARGET)' \
        --disable-static \
        --enable-shared \
        $(MXE_DISABLE_DOC_OPTS) \
        --enable-debug=no \
        --without-fftw \
        --without-magick \
        --without-heif \
        --without-openslide \
        --without-pdfium \
        --without-poppler \
        --without-cfitsio \
        --without-OpenEXR \
        --without-nifti \
        --without-matio \
        --without-ppm \
        --without-analyze \
        --without-radiance \
        --without-imagequant \
        --disable-introspection \
        $(if $(IS_LLVM), CXXFLAGS="$(CXXFLAGS) -Wno-incompatible-ms-struct") \
        $(if $(BUILD_STATIC), lt_cv_deplibs_check_method="pass_all")

    # libtool should automatically generate a list
    # of exported symbols, even for "static" builds
    $(if $(BUILD_STATIC), \
        $(SED) -i 's/^always_export_symbols=no/always_export_symbols=yes/g' '$(SOURCE_DIR)/libtool')

    # remove -nostdlib from linker commandline options
    # (i.e. archive_cmds and archive_expsym_cmds)
    # https://debbugs.gnu.org/cgi/bugreport.cgi?bug=27866
    $(if $(IS_LLVM), \
        $(SED) -i 's/\-shared \-nostdlib/\-shared/g' '$(SOURCE_DIR)/libtool')

    $(MAKE) -C '$(SOURCE_DIR)' -j '$(JOBS)'
    $(MAKE) -C '$(SOURCE_DIR)' -j 1 install
endef
