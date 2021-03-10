#!/usr/bin/env bash

if [[ "$*" == *--help* ]]; then
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [DEPS] [TARGET]
Package libvips in mxe/usr/TARGET/

OPTIONS:
	--help	Show the help and exit

DEPS:
	The group of dependencies to build libvips with,
	    defaults to 'web'
	Possible values are:
	    - web
	    - all

TARGET:
	The binary target,
	    defaults to 'x86_64-w64-mingw32.shared.win32'
	Possible values are:
		- aarch64-w64-mingw32.shared.posix
		- aarch64-w64-mingw32.static.posix
		- armv7-w64-mingw32.shared.posix
		- armv7-w64-mingw32.static.posix
		- i686-w64-mingw32.shared.posix
		- i686-w64-mingw32.shared.win32
		- i686-w64-mingw32.static.posix
		- i686-w64-mingw32.static.win32
		- x86_64-w64-mingw32.shared.posix
		- x86_64-w64-mingw32.shared.win32
		- x86_64-w64-mingw32.static.posix
		- x86_64-w64-mingw32.static.win32
EOF
  exit 0
fi

. variables.sh

deps="${1:-web}"
target="${2:-x86_64-w64-mingw32.shared.win32}"
arch="${target%%-*}"
type="${target#*.}"
type="${type%%.*}"
build_os=`$mxe_dir/ext/config.guess`

if [ "$arch" = "i686" ]; then
  arch="w32"
elif [ "$arch" = "x86_64" ]; then
  arch="w64"
elif [ "$arch" = "armv7" ]; then
  arch="arm32"
elif [ "$arch" = "aarch64" ]; then
  arch="arm64"
fi

# Make sure that the repackaging dir is empty
rm -rf $repackage_dir
mkdir -p $repackage_dir/bin

# Copy libvips-cpp-42.dll
target_dll="libvips-cpp-42.dll"

zip_suffix="${vips_pre_version:+-$vips_pre_version}"

if [ "$type" = "static" ]; then
  zip_suffix+="-static"
fi

if [ "$HEVC" = "true" ]; then
  zip_suffix+="-hevc"
fi

if [ "$DEBUG" = "true" ]; then
  zip_suffix+="-debug"
fi

if [ "$LLVM" = "false" ]; then
  zip_suffix+="-gcc"
fi

if [ "$MOZJPEG" = "false" ]; then
  zip_suffix+="-libjpeg-turbo"
fi

if [ "$ZLIB_NG" = "false" ]; then
  zip_suffix+="-zlib-vanilla"
fi

echo "Copying libvips and dependencies"

# Need to whitelist the Universal C Runtime (CRT) DLLs
# Can't do api-ms-win-crt-*-l1-1-0.dll, unfortunately
whitelist=(api-ms-win-crt-{conio,convert,environment,filesystem,heap,locale,math,multibyte,private,process,runtime,stdio,string,time,utility}-l1-1-0.dll)

# CreateEnvironmentBlock, GetUserProfileDirectoryA, etc.
whitelist+=(userenv.dll)

# Copy libvips and dependencies with pe-util
$mxe_prefix/$build_os/bin/peldd \
  $mxe_prefix/$target.$deps/bin/$target_dll \
  --clear-path \
  --path $mxe_prefix/$target.$deps/bin \
  ${whitelist[@]/#/--wlist } \
  -a | xargs cp -t $repackage_dir/bin

echo "Copying install area $mxe_prefix/$target.$deps/"

# Follow symlinks when copying /share, /etc, /lib and /include
cp -Lr $mxe_prefix/$target.$deps/{share,etc,lib,include} $repackage_dir

echo "Generating import files"
./gendeflibs.sh $deps $target

echo "Cleaning unnecessary files / directories"

# Unnecessary LLVM files
if [ "$LLVM" = "true" ]; then
  rm -rf $repackage_dir/include/{c++,fuzzer,profile,sanitizer,xray}
fi

rm -rf $repackage_dir/share/{aclocal,bash-completion,cmake,config.site,doc,gdb,glib-2.0,gtk-2.0,gtk-doc,installed-tests,man,meson,thumbnailers,xml,zsh}
rm -rf $repackage_dir/include/cairo
rm -rf $repackage_dir/lib/{*.so*,*cairo*,*gdk*,*_too.a,ldscripts,rustlib,xml2Conf.sh}
rm -rf $repackage_dir/etc/bash_completion.d

find $repackage_dir/lib -name "*.la" -exec rm -f {} \;

# We intentionally disabled the i18n features of (GNU) gettext,
# so the locales are not needed.
rm -rf $repackage_dir/share/locale

# Remove those .gitkeep files
rm $repackage_dir/{share,lib,include}/.gitkeep

echo "Copying vips executables"

# We still need to copy the vips executables
cp $mxe_prefix/$target.$deps/bin/{vips,vipsedit,vipsheader,vipsthumbnail}.exe $repackage_dir/bin/

echo "Strip unneeded symbols"

# Remove all symbols that are not needed
if [ "$DEBUG" = "false" ]; then
  $mxe_prefix/bin/$target.$deps-strip --strip-unneeded $repackage_dir/bin/*.{exe,dll}
fi

echo "Copying packaging files"

cp $mxe_prefix/$target.$deps/vips-packaging/{AUTHORS,ChangeLog,COPYING,README.md,versions.json} $repackage_dir

echo "Creating $zipfile"

zipfile=$vips_package-dev-$arch-$deps-$vips_version.$vips_patch_version$zip_suffix.zip
rm -f $zipfile
zip -r -qq $zipfile $repackage_dir
