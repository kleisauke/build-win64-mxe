# MXE will run as many parallel jobs as there are
# available CPU cores. This variable can limit this.
#JOBS := 4

# Special flags for compiler.
export CFLAGS   := -O3 -fdata-sections -ffunction-sections
export CXXFLAGS := -O3 -fdata-sections -ffunction-sections
export LDFLAGS  := -Wl,--gc-sections -Wl,-s

# Special flags for Rust.
export CARGO_PROFILE_RELEASE_DEBUG         := false
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS := 1
export CARGO_PROFILE_RELEASE_INCREMENTAL   := false
export CARGO_PROFILE_RELEASE_LTO           := true
export CARGO_PROFILE_RELEASE_OPT_LEVEL     := s
export CARGO_PROFILE_RELEASE_PANIC         := abort

# We don't need debugging symbols.
STRIP_LIB := $(true)

# Disable ccache
MXE_USE_CCACHE := $(false)
