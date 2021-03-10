PKG             := proxy-libintl
$(PKG)_WEBSITE  := https://github.com/frida/proxy-libintl
$(PKG)_DESCR    := Proxy for a dynamically loaded optional libintl.
$(PKG)_IGNORE   :=
# https://github.com/frida/proxy-libintl/tarball/50bd2525261d44d80533a523873b9344a6d741c5
$(PKG)_VERSION  := 50bd252
$(PKG)_CHECKSUM := 09a587e2623ee9525da6b1f5cff5f8ef0ef7cdb508f34ac591738e00c012a57f
$(PKG)_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/$(PKG)-[0-9]*.patch)))
$(PKG)_GH_CONF  := frida/proxy-libintl/branches/master
$(PKG)_DEPS     := cc

define $(PKG)_BUILD
    '$(TARGET)-meson' \
        --default-library=static \
        --buildtype=release \
        $(if $(STRIP_LIB), --strip) \
        --libdir='lib' \
        --includedir='include' \
        -Dc_args='-DG_INTL_STATIC_COMPILATION' \
        '$(SOURCE_DIR)' \
        '$(BUILD_DIR)'

    ninja -C '$(BUILD_DIR)' install
endef
