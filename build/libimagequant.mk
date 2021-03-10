PKG             := libimagequant
$(PKG)_WEBSITE  := https://github.com/lovell/libimagequant
$(PKG)_DESCR    := libimagequant v2.4.1 fork (BSD 2-Clause)
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 2.4.1
$(PKG)_CHECKSUM := d78a28455598a1b73a4d480c9f1db3048f526971496f4d37a484b71b00624fef
$(PKG)_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/$(PKG)-[0-9]*.patch)))
$(PKG)_GH_CONF  := lovell/libimagequant/tags,v
$(PKG)_DEPS     := cc

define $(PKG)_BUILD
    '$(TARGET)-meson' \
        --buildtype=release \
        $(if $(STRIP_LIB), --strip) \
        --libdir='lib' \
        --includedir='include' \
        $(if $(BUILD_SHARED), -Dc_args="$(CFLAGS) -DLIQ_EXPORT='extern __declspec(dllexport)'") \
        '$(SOURCE_DIR)' \
        '$(BUILD_DIR)'

    ninja -C '$(BUILD_DIR)' install
endef
