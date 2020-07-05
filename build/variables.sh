# included by all scripts

vips_package=vips
vips_version=8.6
vips_micro_version=5

# build-win64-mxe/build dir we are building
work_dir=$(pwd)

# MXE specific
mxe_dir=$work_dir/mxe
mxe_prefix=$mxe_dir/usr

repackage_dir=$vips_package-dev-$vips_version
