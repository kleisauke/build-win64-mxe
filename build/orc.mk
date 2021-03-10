PKG             := orc
$(PKG)_WEBSITE  := https://gstreamer.freedesktop.org/modules/orc.html
$(PKG)_DESCR    := Library and set of tools for compiling and executing SIMD assembly language-like programs that operate on arrays of data.
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 0.4.32
$(PKG)_CHECKSUM := a66e3d8f2b7e65178d786a01ef61f2a0a0b4d0b8370de7ce134ba73da4af18f0
$(PKG)_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/$(PKG)-[0-9]*.patch)))
$(PKG)_SUBDIR   := $(PKG)-$($(PKG)_VERSION)
$(PKG)_FILE     := $(PKG)-$($(PKG)_VERSION).tar.xz
$(PKG)_URL      := https://gstreamer.freedesktop.org/src/$(PKG)/$($(PKG)_FILE)
$(PKG)_DEPS     := cc

define $(PKG)_UPDATE
    $(WGET) -q -O- 'https://gstreamer.freedesktop.org/src/orc/?C=M;O=D' | \
    $(SED) -n 's,.*orc-\([0-9][^>]*\)\.tar.*,\1,p' | \
    head -1
endef

define $(PKG)_BUILD
    '$(TARGET)-meson' \
        --buildtype=release \
        $(if $(STRIP_LIB), --strip) \
        --libdir='lib' \
        --includedir='include' \
        -Dbenchmarks=disabled \
        -Dexamples=disabled \
        -Dgtk_doc=disabled \
        -Dtests=disabled \
        '$(SOURCE_DIR)' \
        '$(BUILD_DIR)'

    ninja -C '$(BUILD_DIR)' install
endef
