PKG             := rust
$(PKG)_WEBSITE  := https://www.rust-lang.org/
$(PKG)_DESCR    := A systems programming language focused on safety, speed and concurrency.
$(PKG)_IGNORE   :=
# https://static.rust-lang.org/dist/2020-12-17/rustc-nightly-src.tar.gz.sha256
$(PKG)_VERSION  := nightly
$(PKG)_CHECKSUM := c2fe6cdaf4cd79e7b71c25224b42c521fa8841241f942bc6888589fa838e6433
$(PKG)_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/$(PKG)-[0-9]*.patch)))
$(PKG)_SUBDIR   := $(PKG)c-$($(PKG)_VERSION)-src
$(PKG)_FILE     := $(PKG)c-$($(PKG)_VERSION)-src.tar.gz
$(PKG)_URL      := https://static.rust-lang.org/dist/2020-12-17/$($(PKG)_FILE)
$(PKG)_DEPS     := $(BUILD)~$(PKG)
$(PKG)_TARGETS  := $(BUILD) $(MXE_TARGETS)

$(PKG)_DEPS_$(BUILD) := $(BUILD)~llvm

# Build Rust from source to support the ARM targets and
# to ensure that it links against UCRT (the prebuilt Rust
# binaries are built with --with-default-msvcrt=msvcrt)
define $(PKG)_BUILD_$(BUILD)
    # x86_64-pc-linux-gnu -> x86_64-unknown-linux-gnu
    $(eval BUILD_RUST := $(firstword $(subst -, ,$(BUILD)))-unknown-linux-gnu)

    # Disable LTO, panic strategy and optimization settings while
    # we bootstrap Rust
    $(eval unexport CARGO_PROFILE_RELEASE_LTO)
    $(eval unexport CARGO_PROFILE_RELEASE_OPT_LEVEL)
    $(eval unexport CARGO_PROFILE_RELEASE_PANIC)

    # Don't depend on a nightly version of rustfmt
    $(SED) -i '/^rustfmt:/d' $(SOURCE_DIR)/src/stage0.txt

    cd '$(BUILD_DIR)' && $(SOURCE_DIR)/configure \
        --prefix='$(PREFIX)/$(BUILD)' \
        --release-channel=nightly \
        --enable-extended \
        --tools=cargo,src \
        --disable-docs \
        --disable-codegen-tests \
        --python='$(PYTHON)' \
        --llvm-root='$(PREFIX)/$(BUILD)' \
        --set target.$(BUILD_RUST).cc='$(BUILD_CC)' \
        --set target.$(BUILD_RUST).cxx='$(BUILD_CXX)' \
        --set target.$(BUILD_RUST).ar='$(PREFIX)/$(BUILD)/bin/llvm-ar' \
        --set target.$(BUILD_RUST).ranlib='$(PREFIX)/$(BUILD)/bin/llvm-ranlib'

    # Enable networking while we build Rust from source. Assumes
    # that the Rust build is reproducible.
    echo 'static int __attribute__((unused)) _dummy;' > '$(BUILD_DIR)/dummy.c'
    $(BUILD_CC) -shared -fPIC $(NONET_CFLAGS) -o $(NONET_LIB) $(BUILD_DIR)/dummy.c

    # Build Rust
    cd '$(BUILD_DIR)' && \
        $(PYTHON) $(SOURCE_DIR)/x.py build -j '$(JOBS)' -v

    # Install Rust
    cd '$(BUILD_DIR)' && \
        $(PYTHON) $(SOURCE_DIR)/x.py install --keep-stage 1 -j '$(JOBS)' -v

    # Disable networking (again) for reproducible builds further on
    $(BUILD_CC) -shared -fPIC $(NONET_CFLAGS) -o $(NONET_LIB) $(TOP_DIR)/tools/nonetwork.c
endef

# Build the standard library of Rust using the build-std feature
define $(PKG)_BUILD
    # armv7 -> thumbv7a
    $(eval ARCH_NAME := $(if $(findstring armv7,$(PROCESSOR)),thumbv7a,$(PROCESSOR)))
    $(eval TARGET_RUST := $(ARCH_NAME)-pc-windows-gnu)

    # [major].[minor].[patch]-[label] -> [major].[minor].[patch]
    $(eval CLANG_VERSION := $(firstword $(subst -, ,$(clang_VERSION))))

    # Flags we use to build the standard library
    # Note: libstd must be built with bitcode (-Cembed-bitcode=yes) so that the produced
    # rlibs can be used for LTO builds.
    # Note 2: -Clinker-flavor=ld.lld will force LLD as linker flavor for targets that
    # have not set this by default (i.e. {i686,x86_64}-pc-windows-gnu).
    # Note 3: -Clink-self-contained=yes will link against the {,dll}crt2.o (defined in
    # pre_link_objects_fallback) from our MinGW distribution.
    # Note 4: The -Clink-arg=* options adds our MinGW distribution and the compiler-rt
    # builtins to the standard set of searched paths.
    $(eval STD_FLAGS := -Cembed-bitcode=yes \
                        -Clinker=ld.lld \
                        -Clinker-flavor=ld.lld \
                        -Clink-self-contained=yes \
                        -Clink-arg=-L$(PREFIX)/$(TARGET)/lib \
                        -Clink-arg=-L$(PREFIX)/$(TARGET)/mingw/lib \
                        -Clink-arg=-L$(PREFIX)/$(BUILD)/lib/clang/$(CLANG_VERSION)/lib/windows)

    # Hint the C/C++ compiler and archiver for this target
    $(eval export CC_$(TARGET_RUST)  := $(TARGET)-clang)
    $(eval export CXX_$(TARGET_RUST) := $(TARGET)-clang++)
    $(eval export AR_$(TARGET_RUST)  := $(PREFIX)/$(BUILD)/bin/llvm-ar)

    # Disable "fat" LTO while we build the standard library
    $(eval unexport CARGO_PROFILE_RELEASE_LTO)

    # Enable networking while we build the standard library
    echo 'static int __attribute__((unused)) _dummy;' > '$(BUILD_DIR)/dummy.c'
    $(BUILD_CC) -shared -fPIC $(NONET_CFLAGS) -o $(NONET_LIB) $(BUILD_DIR)/dummy.c

    # Create a new temporary Cargo package
    CARGO_NAME=dummy \
    $(PREFIX)/$(BUILD)/bin/cargo init '$(BUILD_DIR)' --name dummy --vcs none --lib

    # Build and prepare startup objects like rsbegin.o and rsend.o
    $(foreach FILE, rsbegin rsend, \
        $(PREFIX)/$(BUILD)/bin/rustc --target $(TARGET_RUST) --emit=obj -o '$(BUILD_DIR)/$(FILE).o' \
            '$(PREFIX)/$(BUILD)/lib/rustlib/src/rust/library/rtstartup/$(FILE).rs';)

    # Build the standard library
    cd '$(BUILD_DIR)' && \
        RUSTFLAGS='$(STD_FLAGS)' \
        $(PREFIX)/$(BUILD)/bin/cargo build -Zbuild-std=panic_abort,std --release --target $(TARGET_RUST)

    # Disable networking (again) for reproducible builds further on
    $(BUILD_CC) -shared -fPIC $(NONET_CFLAGS) -o $(NONET_LIB) $(TOP_DIR)/tools/nonetwork.c

    # Install the standard library
    $(INSTALL) -d '$(PREFIX)/$(TARGET)/lib/rustlib/$(TARGET_RUST)/lib'
    mv -vf '$(BUILD_DIR)/target/$(TARGET_RUST)/release/deps/'*.{rlib,rmeta} \
        '$(PREFIX)/$(TARGET)/lib/rustlib/$(TARGET_RUST)/lib'

    # Install Cargo config
    $(INSTALL) -d '$(PREFIX)/$(TARGET)/.cargo'
    (echo '[build]'; \
     echo 'target = "$(TARGET_RUST)"'; \
     echo 'rustflags = ['; \
     echo '    "--sysroot",'; \
     echo '    "$(PREFIX)/$(TARGET)"'; \
     echo ']';) \
             > '$(PREFIX)/$(TARGET)/.cargo/config'

    # Install prefixed wrappers
    (echo '#!/usr/bin/env bash'; \
     echo 'CARGO_HOME="$(PREFIX)/$(TARGET)/.cargo" \'; \
     echo 'RUSTC="$(PREFIX)/bin/$(TARGET)-rustc" \'; \
     echo 'exec $(PREFIX)/$(BUILD)/bin/cargo \'; \
     echo '"$$@"';) \
             > '$(PREFIX)/bin/$(TARGET)-cargo'
    chmod 0755 '$(PREFIX)/bin/$(TARGET)-cargo'

    ln -sf '$(PREFIX)/$(BUILD)/bin/rustc' '$(PREFIX)/bin/$(TARGET)-rustc'
endef
