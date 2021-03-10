PKG             := libexif
$(PKG)_WEBSITE  := https://libexif.github.io/
$(PKG)_DESCR    := A library for parsing, editing, and saving EXIF data.
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 0.6.22
$(PKG)_CHECKSUM := 5048f1c8fc509cc636c2f97f4b40c293338b6041a5652082d5ee2cf54b530c56
$(PKG)_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/$(PKG)-[0-9]*.patch)))
$(PKG)_SUBDIR   := $(PKG)-$($(PKG)_VERSION)
$(PKG)_FILE     := $(PKG)-$($(PKG)_VERSION).tar.xz
$(PKG)_GH_CONF  := libexif/libexif/releases,libexif-,-release,,_,.tar.xz
$(PKG)_DEPS     := cc

define $(PKG)_BUILD
    # configure script is ancient so regenerate
    cd '$(SOURCE_DIR)' && autoreconf -fi

    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        $(MXE_CONFIGURE_OPTS) \
        --disable-nls \
        --without-libiconv-prefix \
        --without-libintl-prefix
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)' $(MXE_DISABLE_PROGRAMS)
    $(MAKE) -C '$(BUILD_DIR)' -j 1 $(INSTALL_STRIP_LIB) $(MXE_DISABLE_PROGRAMS)
endef
