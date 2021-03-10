PKG             := rust
$(PKG)_WEBSITE  := https://www.rust-lang.org/
$(PKG)_DESCR    := A systems programming language focused on safety, speed and concurrency.
$(PKG)_IGNORE   :=
# https://static.rust-lang.org/dist/2021-03-15/rustc-nightly-src.tar.gz.sha256
$(PKG)_VERSION  := nightly
$(PKG)_CHECKSUM := 9f85fea36e255bb66451bd5fef0e30a6c793dfdceefc674de02c630cc4f80a2a
$(PKG)_PATCHES  := $(realpath $(sort $(wildcard $(dir $(lastword $(MAKEFILE_LIST)))/patches/$(PKG)-[0-9]*.patch)))
$(PKG)_SUBDIR   := $(PKG)c-$($(PKG)_VERSION)-src
$(PKG)_FILE     := $(PKG)c-$($(PKG)_VERSION)-src.tar.gz
$(PKG)_URL      := https://static.rust-lang.org/dist/2021-03-15/$($(PKG)_FILE)
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

    # Unexport target specific compiler / linker flags
    $(eval unexport CFLAGS)
    $(eval unexport CXXFLAGS)
    $(eval unexport LDFLAGS)

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
    $(eval export MXE_ENABLE_NETWORK := 1)

    # Build Rust
    cd '$(BUILD_DIR)' && \
        $(PYTHON) $(SOURCE_DIR)/x.py build -j '$(JOBS)' -v

    # Install Rust
    cd '$(BUILD_DIR)' && \
        $(PYTHON) $(SOURCE_DIR)/x.py install --keep-stage 1 -j '$(JOBS)' -v

    # Copy the Cargo.lock for Rust to places `vendor` will see
    # https://github.com/rust-lang/wg-cargo-std-aware/issues/23#issuecomment-720455524
    cp '$(PREFIX)/$(BUILD)/lib/rustlib/src/rust/Cargo.lock' '$(PREFIX)/$(BUILD)/lib/rustlib/src/rust/library/test'
endef

define $(PKG)_BUILD
    # armv7 -> thumbv7a
    $(eval ARCH_NAME := $(if $(findstring armv7,$(PROCESSOR)),thumbv7a,$(PROCESSOR)))
    $(eval TARGET_RUST := $(ARCH_NAME)-pc-windows-gnu)

    # [major].[minor].[patch]-[label] -> [major].[minor].[patch]
    $(eval CLANG_VERSION := $(firstword $(subst -, ,$(clang_VERSION))))

    # Build and prepare startup objects like rsbegin.o and rsend.o
    $(foreach FILE, rsbegin rsend, \
        $(PREFIX)/$(BUILD)/bin/rustc --target='$(TARGET_RUST)' --emit=obj -o '$(BUILD_DIR)/$(FILE).o' \
            '$(PREFIX)/$(BUILD)/lib/rustlib/src/rust/library/rtstartup/$(FILE).rs';)

    # Install the startup objects
    $(INSTALL) -d '$(PREFIX)/$(BUILD)/lib/rustlib/$(TARGET_RUST)/lib'
    mv -vf '$(BUILD_DIR)/'rs{begin,end}.o '$(PREFIX)/$(BUILD)/lib/rustlib/$(TARGET_RUST)/lib'

    # Install Cargo config
    # Note: -Clinker-flavor=ld.lld will force LLD as linker flavor for targets that
    # have not set this by default (i.e. {i686,x86_64}-pc-windows-gnu).
    # Note 2: -Clink-self-contained=yes will link against the {,dll}crt2.o (defined in
    # pre_link_objects_fallback) from our MinGW distribution.
    # Note 3: The -Clink-arg=* options adds our MinGW distribution and the compiler-rt
    # builtins to the standard set of searched paths.
    $(INSTALL) -d '$(PREFIX)/$(TARGET)/.cargo'
    (echo '[unstable]'; \
     echo 'build-std = ["std", "panic_abort"]'; \
     echo 'build-std-features = ["panic_immediate_abort"]'; \
     echo '[build]'; \
     echo 'target = "$(TARGET_RUST)"'; \
     echo '[target.$(TARGET_RUST)]'; \
     echo 'rustflags = ['; \
     echo '    "-C",'; \
     echo '    "linker-flavor=ld.lld",'; \
     echo '    "-C",'; \
     echo '    "link-self-contained=yes",'; \
     echo '    "-C",'; \
     echo '    "link-arg=-L$(PREFIX)/$(TARGET)/lib",'; \
     echo '    "-C",'; \
     echo '    "link-arg=-L$(PREFIX)/$(TARGET)/mingw/lib",'; \
     echo '    "-C",'; \
     echo '    "link-arg=-L$(PREFIX)/$(BUILD)/lib/clang/$(CLANG_VERSION)/lib/windows"'; \
     echo ']'; \
     echo 'linker = "$(PREFIX)/$(BUILD)/bin/ld.lld"'; \
     echo 'ar = "$(PREFIX)/$(BUILD)/bin/llvm-ar"';) \
             > '$(PREFIX)/$(TARGET)/.cargo/config'

    # Install prefixed wrappers
    (echo '#!/usr/bin/env bash'; \
     echo 'CARGO_HOME="$(PREFIX)/$(TARGET)/.cargo" \'; \
     echo 'RUSTC="$(PREFIX)/$(BUILD)/bin/rustc" \'; \
     echo 'exec $(PREFIX)/$(BUILD)/bin/cargo \'; \
     echo '"$$@"';) \
             > '$(PREFIX)/bin/$(TARGET)-cargo'
    chmod 0755 '$(PREFIX)/bin/$(TARGET)-cargo'

    ln -sf '$(PREFIX)/$(BUILD)/bin/rustc' '$(PREFIX)/bin/$(TARGET)-rustc'
endef
