PKG             := mozjpeg
$(PKG)_WEBSITE  := https://github.com/mozilla/mozjpeg
$(PKG)_DESCR    := A JPEG codec that provides increased compression for JPEG images (at the expense of compression performance).
$(PKG)_IGNORE   :=
$(PKG)_VERSION  := 4.0.0
$(PKG)_CHECKSUM := 961e14e73d06a015e9b23b8af416f010187cc0bec95f6e3b0fcb28cc7e2cbdd4
# Avoid duplicated patches
$(PKG)_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/../../patches/libjpeg-turbo-[0-9]*.patch)))
$(PKG)_GH_CONF  := mozilla/mozjpeg/tags,v
$(PKG)_DEPS     := cc $(BUILD)~nasm

$(PKG)_PATCH_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST)))/patches)

# WITH_TURBOJPEG=OFF turns off a library we don't use (we just use the
# libjpeg API)
define $(PKG)_BUILD
    # TODO(kleisauke): This is no longer necessary once mozjpeg merges libjpeg-turbo 2.0.6.
    $(if $(IS_ARM),\
        (cd '$(SOURCE_DIR)' && $(PATCH) -p1 -u) < $($(PKG)_PATCH_DIR)/$(PKG)-arm.patch)

    cd '$(BUILD_DIR)' && $(TARGET)-cmake \
        -DWITH_TURBOJPEG=OFF \
        -DENABLE_SHARED=$(CMAKE_SHARED_BOOL) \
        -DENABLE_STATIC=$(CMAKE_STATIC_BOOL) \
        -DCMAKE_ASM_NASM_COMPILER='$(PREFIX)/$(BUILD)/bin/nasm' \
        '$(SOURCE_DIR)'
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)' -j 1 install
endef
