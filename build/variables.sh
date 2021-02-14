# included by all scripts

vips_package=vips
vips_version=8.11
vips_patch_version=0
vips_pre_version=gmodulized

# build-win64-mxe/build dir we are building
work_dir=$(pwd)

# MXE specific
mxe_dir=$work_dir/mxe
mxe_prefix=$mxe_dir/usr

repackage_dir=$vips_package-dev-$vips_version
