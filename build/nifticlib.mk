PKG             := nifticlib
$(PKG)_WEBSITE  := https://nifti.nimh.nih.gov/
$(PKG)_DESCR    := A set of i/o libraries for reading and writing files in the nifti-1 data format
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 2.0.0
$(PKG)_CHECKSUM := a3e988e6a32ec57833056f6b09f940c69e79829028da121ff2c5c6f7f94a7f88
$(PKG)_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/$(PKG)-[0-9]*.patch)))
$(PKG)_SUBDIR   := $(PKG)-$($(PKG)_VERSION)
$(PKG)_FILE     := $(PKG)-$($(PKG)_VERSION).tar.gz
$(PKG)_URL      := https://$(SOURCEFORGE_MIRROR)/project/niftilib/$(PKG)/$(PKG)_$(subst .,_,$($(PKG)_VERSION))/$($(PKG)_FILE)
$(PKG)_DEPS     := cc zlib

define $(PKG)_UPDATE
    $(WGET) -q -O- 'https://sourceforge.net/projects/niftilib/files/' | \
    $(SED) -n 's,.*nifticlib-\([0-9][^>]*\)\.tar.*,\1,p' | \
    head -1
endef

# disable link-time garbage collection for shared builds
define $(PKG)_BUILD_SHARED
    $(eval export CFLAGS   := -O3)
    $(eval export CXXFLAGS := -O3)
    $(eval export LDFLAGS  := -Wl,-s)

    $($(PKG)_BUILD)
endef

define $(PKG)_BUILD
    cd '$(BUILD_DIR)' && '$(TARGET)-cmake' \
        '$(SOURCE_DIR)'
    $(MAKE) -C '$(BUILD_DIR)' -j $(JOBS)
    $(MAKE) -C '$(BUILD_DIR)' -j 1 $(subst -,/,$(INSTALL_STRIP_LIB))

    # create pkg-config files
    $(INSTALL) -d '$(PREFIX)/$(TARGET)/lib/pkgconfig'
    (echo 'Name: $(PKG)'; \
     echo 'Version: $($(PKG)_VERSION)'; \
     echo 'Libs: -lniftiio -lnifticdf -lznz';) \
     > '$(PREFIX)/$(TARGET)/lib/pkgconfig/$(PKG).pc'
endef
