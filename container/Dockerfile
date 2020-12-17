FROM buildpack-deps:buster

RUN apt-get update \
  && apt-get install -y \
    # http://mxe.cc/#requirements-debian
    autopoint bison flex gettext gperf intltool \
    libtool-bin libxml-parser-perl lzip p7zip-full \
    ruby g++-multilib libc6-dev-i386 \
    # needed when building libvips from git
    gobject-introspection gtk-doc-tools \
    # needed for Meson
    ninja-build python3-pip \
  # install Meson
  && pip3 install meson

# TODO: This patch needs to be incorporated upstream
RUN cd $(dirname `python3 -c "import mesonbuild as _; print(_.__path__[0])"`) \
  && curl -L https://gist.github.com/kleisauke/a2370bf67d1d8813cf8257c039488a79/raw/a4aecefa3e069a3b3ae9b94a5489a0027ef7a0d3/meson-llvm-mingw.patch | git apply -v

# gas-preprocessor.pl is required for the ARM/ARM64 builds of libjpeg-turbo
# TODO(kleisauke): This is no longer necessary once libjpeg-turbo 2.1 is released.
RUN curl -L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl -o /usr/bin/gas-preprocessor.pl \
  && chmod +x /usr/bin/gas-preprocessor.pl

# The build dir is mounted at /data, so this runs the build script in that
ENTRYPOINT ["/bin/bash", "/data/build.sh"]

# The build dir is mounted here
WORKDIR /data
