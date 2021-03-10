# This file is part of MXE. See LICENSE.md for licensing information.

PKG             := llvm
$(PKG)_WEBSITE  := https://llvm.org/
$(PKG)_DESCR    := A collection of modular and reusable compiler and toolchain technologies
$(PKG)_IGNORE   :=
# This version needs to be in-sync with the clang, lld, lldb, compiler-rt, libunwind, libcxxabi and libcxx packages
$(PKG)_VERSION  := 11.1.0
$(PKG)_CHECKSUM := ce8508e318a01a63d4e8b3090ab2ded3c598a50258cc49e2625b9120d4c03ea5
$(PKG)_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/llvm-[0-9]*.patch)))
$(PKG)_GH_CONF  := llvm/llvm-project/releases/latest,llvmorg-,,,,.tar.xz
$(PKG)_SUBDIR   := $(PKG)-$(subst -,,$($(PKG)_VERSION)).src
$(PKG)_FILE     := $($(PKG)_SUBDIR).tar.xz
# This is needed to properly override: https://github.com/mxe/mxe/blob/master/src/llvm.mk#L11
$(PKG)_URL      := https://github.com/llvm/llvm-project/releases/download/llvmorg-$($(PKG)_VERSION)/$($(PKG)_FILE)
$(PKG)_DEPS     := $(BUILD)~$(PKG) llvm-mingw compiler-rt-builtins libunwind libcxxabi libcxx
$(PKG)_TARGETS  := $(BUILD) $(MXE_TARGETS)

$(PKG)_DEPS_$(BUILD) := cmake clang lld lldb

define $(PKG)_BUILD_$(BUILD)
    $(call PREPARE_PKG_SOURCE,clang,$(BUILD_DIR))
    $(call PREPARE_PKG_SOURCE,lld,$(BUILD_DIR))
    $(call PREPARE_PKG_SOURCE,lldb,$(BUILD_DIR))

    # Unexport target specific compiler / linker flags
    $(eval unexport CFLAGS)
    $(eval unexport CXXFLAGS)
    $(eval unexport LDFLAGS)

    cd '$(BUILD_DIR)' && cmake '$(SOURCE_DIR)' \
        -DCMAKE_INSTALL_PREFIX='$(PREFIX)/$(BUILD)' \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_ENABLE_ASSERTIONS=OFF \
        -DLLVM_TARGETS_TO_BUILD='ARM;AArch64;X86' \
        -DLLVM_TOOLCHAIN_TOOLS='llvm-ar;llvm-config;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer' \
        -DLLVM_EXTERNAL_CLANG_SOURCE_DIR='$(BUILD_DIR)/$(clang_SUBDIR)' \
        -DLLVM_EXTERNAL_LLD_SOURCE_DIR='$(BUILD_DIR)/$(lld_SUBDIR)' \
        -DLLVM_EXTERNAL_LLDB_SOURCE_DIR='$(BUILD_DIR)/$(lldb_SUBDIR)' \
        -DLLVM_BUILD_DOCS=OFF \
        -DLLVM_BUILD_EXAMPLES=OFF \
        -DLLVM_BUILD_TESTS=OFF \
        -DLLVM_BUILD_UTILS=OFF \
        -DLLVM_ENABLE_BINDINGS=OFF \
        -DLLVM_ENABLE_DOXYGEN=OFF \
        -DLLVM_ENABLE_OCAMLDOC=OFF \
        -DLLVM_ENABLE_SPHINX=OFF \
        -DLLVM_INCLUDE_DOCS=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_GO_TESTS=OFF \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_UTILS=OFF \
        -DLLDB_ENABLE_LIBEDIT=OFF \
        -DLLDB_ENABLE_PYTHON=OFF \
        -DLLDB_ENABLE_CURSES=OFF \
        -DLLDB_ENABLE_LUA=OFF \
        -DLLDB_INCLUDE_TESTS=OFF
    $(MAKE) -C '$(BUILD_DIR)' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR)' -j 1 $(subst -,/,$(INSTALL_STRIP_TOOLCHAIN))
endef

# llvm requires being built in a monorepo layout with
# libunwind, libcxxabi and libcxx available
define $(PKG)_PRE_CONFIGURE
    $(call PREPARE_PKG_SOURCE,libunwind,$(BUILD_DIR))
    rm -rf '$(SOURCE_DIR)/libunwind'
    mv '$(BUILD_DIR)/$(libunwind_SUBDIR)' '$(SOURCE_DIR)/libunwind'

    $(call PREPARE_PKG_SOURCE,libcxxabi,$(BUILD_DIR))
    rm -rf '$(SOURCE_DIR)/libcxxabi'
    mv '$(BUILD_DIR)/$(libcxxabi_SUBDIR)' '$(SOURCE_DIR)/libcxxabi'

    $(call PREPARE_PKG_SOURCE,libcxx,$(BUILD_DIR))
    rm -rf '$(SOURCE_DIR)/libcxx'
    mv '$(BUILD_DIR)/$(libcxx_SUBDIR)' '$(SOURCE_DIR)/libcxx'
endef

define $(PKG)_BUILD
    $($(PKG)_PRE_CONFIGURE)

    mkdir '$(BUILD_DIR).libunwind'
    cd '$(BUILD_DIR).libunwind' && $(TARGET)-cmake '$(SOURCE_DIR)/libunwind' \
        -DCMAKE_CROSSCOMPILING=TRUE \
        -DCMAKE_C_COMPILER_WORKS=TRUE \
        -DCMAKE_CXX_COMPILER_WORKS=TRUE \
        -DLLVM_PATH='$(SOURCE_DIR)' \
        -DLLVM_COMPILER_CHECKED=TRUE \
        -DCMAKE_AR='$(PREFIX)/$(BUILD)/bin/llvm-ar' \
        -DCMAKE_RANLIB='$(PREFIX)/$(BUILD)/bin/llvm-ranlib' \
        -DCXX_SUPPORTS_CXX11=TRUE \
        -DCXX_SUPPORTS_CXX_STD=TRUE \
        -DLIBUNWIND_USE_COMPILER_RT=TRUE \
        -DLIBUNWIND_ENABLE_THREADS=TRUE \
        -DLIBUNWIND_ENABLE_SHARED=$(CMAKE_SHARED_BOOL) \
        -DLIBUNWIND_ENABLE_STATIC=$(CMAKE_STATIC_BOOL) \
        -DLIBUNWIND_ENABLE_CROSS_UNWINDING=FALSE \
        -DCMAKE_CXX_FLAGS='$(CXXFLAGS) -Wno-dll-attribute-on-redeclaration' \
        -DCMAKE_C_FLAGS='$(CFLAGS) -Wno-dll-attribute-on-redeclaration'
    $(MAKE) -C '$(BUILD_DIR).libunwind' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR).libunwind' -j 1 $(subst -,/,$(INSTALL_STRIP_TOOLCHAIN))

    $(if $(BUILD_SHARED), \
        cp '$(BUILD_DIR).libunwind/lib/libunwind.dll' '$(PREFIX)/$(TARGET)/bin')

    # Configure, but don't build, libcxx, so that libcxxabi has
    # proper headers to refer to
    mkdir '$(BUILD_DIR).libcxx'
    cd '$(BUILD_DIR).libcxx' && $(TARGET)-cmake '$(SOURCE_DIR)/libcxx' \
        -DCMAKE_CROSSCOMPILING=TRUE \
        -DCMAKE_C_COMPILER_WORKS=TRUE \
        -DCMAKE_CXX_COMPILER_WORKS=TRUE \
        -DLLVM_PATH='$(SOURCE_DIR)' \
        -DLLVM_COMPILER_CHECKED=TRUE \
        -DCMAKE_AR='$(PREFIX)/$(BUILD)/bin/llvm-ar' \
        -DCMAKE_RANLIB='$(PREFIX)/$(BUILD)/bin/llvm-ranlib' \
        -DLIBCXX_USE_COMPILER_RT=ON \
        -DLIBCXX_INSTALL_HEADERS=ON \
        -DLIBCXX_ENABLE_EXCEPTIONS=ON \
        -DLIBCXX_ENABLE_THREADS=ON \
        -DLIBCXX_HAS_WIN32_THREAD_API=ON \
        -DLIBCXX_ENABLE_SHARED=$(CMAKE_SHARED_BOOL) \
        -DLIBCXX_ENABLE_STATIC=$(CMAKE_STATIC_BOOL) \
        -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=OFF \
        -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=TRUE \
        -DLIBCXX_ENABLE_NEW_DELETE_DEFINITIONS=ON \
        -DLIBCXX_CXX_ABI=libcxxabi \
        -DLIBCXX_CXX_ABI_INCLUDE_PATHS='$(SOURCE_DIR)/libcxxabi/include' \
        -DLIBCXX_CXX_ABI_LIBRARY_PATH='$(BUILD_DIR).libcxxabi/lib' \
        -DLIBCXX_LIBDIR_SUFFIX='' \
        -DLIBCXX_INCLUDE_TESTS=FALSE \
        -DCMAKE_CXX_FLAGS='$(CXXFLAGS) $(if $(BUILD_SHARED),-D_LIBCXXABI_BUILDING_LIBRARY,-D_LIBCXXABI_DISABLE_VISIBILITY_ANNOTATIONS)' \
        -DCMAKE_SHARED_LINKER_FLAGS='-lunwind' \
        -DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=FALSE
    $(MAKE) -C '$(BUILD_DIR).libcxx' -j '$(JOBS)' generate-cxx-headers

    mkdir '$(BUILD_DIR).libcxxabi'
    cd '$(BUILD_DIR).libcxxabi' && $(TARGET)-cmake '$(SOURCE_DIR)/libcxxabi' \
        -DCMAKE_CROSSCOMPILING=TRUE \
        -DCMAKE_C_COMPILER_WORKS=TRUE \
        -DCMAKE_CXX_COMPILER_WORKS=TRUE \
        -DLLVM_PATH='$(SOURCE_DIR)' \
        -DLLVM_COMPILER_CHECKED=TRUE \
        -DCMAKE_AR='$(PREFIX)/$(BUILD)/bin/llvm-ar' \
        -DCMAKE_RANLIB='$(PREFIX)/$(BUILD)/bin/llvm-ranlib' \
        -DLIBCXXABI_USE_COMPILER_RT=ON \
        -DLIBCXXABI_ENABLE_EXCEPTIONS=ON \
        -DLIBCXXABI_ENABLE_THREADS=ON \
        -DLIBCXXABI_TARGET_TRIPLE=$(TARGET) \
        -DLIBCXXABI_ENABLE_SHARED=OFF \
        -DLIBCXXABI_LIBCXX_INCLUDES='$(BUILD_DIR).libcxx/include/c++/v1' \
        -DLIBCXXABI_LIBDIR_SUFFIX='' \
        -DLIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS=OFF \
        -DCXX_SUPPORTS_CXX_STD=TRUE \
        $(if $(BUILD_SHARED), -DCMAKE_CXX_FLAGS='$(CXXFLAGS) -U_LIBCPP_BUILDING_LIBRARY -D_LIBCPP_BUILDING_LIBRARY= -U_LIBCXXABI_DISABLE_VISIBILITY_ANNOTATIONS')
    $(MAKE) -C '$(BUILD_DIR).libcxxabi' -j '$(JOBS)'

    $(MAKE) -C '$(BUILD_DIR).libcxx' -j '$(JOBS)'
    $(MAKE) -C '$(BUILD_DIR).libcxx' -j 1 $(subst -,/,$(INSTALL_STRIP_TOOLCHAIN))

    $(if $(BUILD_STATIC), \
        $(TARGET)-ar qcsL \
            '$(PREFIX)/$(TARGET)/lib/libc++.a' \
            '$(PREFIX)/$(TARGET)/lib/libunwind.a' \
    $(else), \
        $(TARGET)-ar qcsL \
            '$(PREFIX)/$(TARGET)/lib/libc++.dll.a' \
            '$(PREFIX)/$(TARGET)/lib/libunwind.dll.a')
endef
