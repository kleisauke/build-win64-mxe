PKG             := vips-all
$(PKG)_WEBSITE  := https://libvips.github.io/libvips/
$(PKG)_DESCR    := A fast image processing library with low memory needs.
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 8.7.4
$(PKG)_CHECKSUM := ce7518a8f31b1d29a09b3d7c88e9852a5a2dcb3ee1501524ab477e433383f205
$(PKG)_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/vips-[0-9]*.patch)))
$(PKG)_GH_CONF  := libvips/libvips/releases/download,v
$(PKG)_SUBDIR   := $(subst -all,,$(PKG))-$($(PKG)_VERSION)
$(PKG)_FILE     := $(subst -all,,$(PKG))-$($(PKG)_VERSION).tar.gz
$(PKG)_DEPS     := cc matio libwebp librsvg giflib poppler glib pango fftw \
                   libgsf libjpeg-turbo tiff openslide lcms libexif \
                   imagemagick libpng openexr cfitsio nifticlib orc

define $(PKG)_PRE_CONFIGURE
    # Copy some files to the packaging directory
    mkdir -p $(TOP_DIR)/vips-packaging
    $(foreach f,COPYING ChangeLog README.md AUTHORS, mv '$(SOURCE_DIR)/$f' '$(TOP_DIR)/vips-packaging';)

    (echo '{'; \
     echo '  "cairo": "$(cairo_VERSION)",'; \
     echo '  "cfitsio": "$(cfitsio_VERSION)",'; \
     echo '  "croco": "$(libcroco_VERSION)",'; \
     echo '  "exif": "$(libexif_VERSION)",'; \
     echo '  "expat": "$(expat_VERSION)",'; \
     echo '  "ffi": "$(libffi_VERSION)",'; \
     echo '  "fftw": "$(fftw_VERSION)",'; \
     echo '  "fontconfig": "$(fontconfig_VERSION)",'; \
     echo '  "freetype": "$(freetype_VERSION)",'; \
     echo '  "fribidi": "$(fribidi_VERSION)",'; \
     echo '  "gdkpixbuf": "$(gdk-pixbuf_VERSION)",'; \
     echo '  "gettext": "$(gettext_VERSION)",'; \
     echo '  "gif": "$(giflib_VERSION)",'; \
     echo '  "glib": "$(glib_VERSION)",'; \
     echo '  "gsf": "$(libgsf_VERSION)",'; \
     echo '  "harfbuzz": "$(harfbuzz_VERSION)",'; \
     echo '  "hdf5": "$(hdf5_VERSION)",'; \
     echo '  "iconv": "$(libiconv_VERSION)",'; \
     echo '  "imagemagick": "$(imagemagick_VERSION)",'; \
     echo '  "jpeg": "$(libjpeg-turbo_VERSION)",'; \
     echo '  "lcms": "$(lcms_VERSION)",'; \
     echo '  "matio": "$(matio_VERSION)",'; \
     echo '  "nifti": "$(nifticlib_VERSION)",'; \
     echo '  "openexr": "$(openexr_VERSION)",'; \
     echo '  "openjpeg": "$(openjpeg_VERSION)",'; \
     echo '  "openslide": "$(openslide_VERSION)",'; \
     echo '  "orc": "$(orc_VERSION)",'; \
     echo '  "pango": "$(pango_VERSION)",'; \
     echo '  "pixman": "$(pixman_VERSION)",'; \
     echo '  "png": "$(libpng_VERSION)",'; \
     echo '  "poppler": "$(poppler_VERSION)",'; \
     echo '  "sqlite": "$(sqlite_VERSION)",'; \
     echo '  "svg": "$(librsvg_VERSION)",'; \
     echo '  "tiff": "$(tiff_VERSION)",'; \
     echo '  "vips": "$(vips-web_VERSION)",'; \
     echo '  "webp": "$(libwebp_VERSION)",'; \
     echo '  "xml": "$(libxml2_VERSION)",'; \
     echo '  "zlib": "$(zlib_VERSION)"'; \
     echo '}';) \
     > '$(TOP_DIR)/vips-packaging/versions.json'
endef

define $(PKG)_BUILD
    $($(PKG)_PRE_CONFIGURE)
    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        $(MXE_CONFIGURE_OPTS) \
        --enable-debug=no \
        --disable-introspection

    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install
endef
