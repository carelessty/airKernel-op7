# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

# Set up working directory variables
test "$home" || home=$PWD;
split_img=$home/split_img;

## AnyKernel setup
# begin properties
properties() { '
kernel.string=IceKernel @ xda-developers
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=OnePlus7
device.name2=guacamoleb
device.name3=OnePlus7Pro
device.name4=guacamole
device.name5=OnePlus7ProTMO
device.name6=guacamolet
device.name7=OnePlus7T
device.name8=hotdogb
device.name9=OnePlus7TPro
device.name10=hotdog
device.name11=OnePlus7TProNR
device.name12=hotdogg
supported.versions=10
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot
is_slot_device=1
ramdisk_compression=auto

## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;

## Select the correct image to flash
hotdog="$(grep -wom 1 hotdog*.* /system/build.prop | sed 's/.....$//')";
guacamole="$(grep -wom 1 guacamole*.* /system/build.prop | sed 's/.....$//')";
userflavor="$(file_getprop /system/build.prop "ro.build.user"):$(file_getprop /system/build.prop "ro.build.flavor")";
userflavor2="$(file_getprop2 /system/build.prop "ro.build.user"):$(file_getprop2 /system/build.prop "ro.build.flavor")";
if [ "$userflavor" == "jenkins:$hotdog-user" ] || [ "$userflavor2" == "jenkins:$guacamole-user" ]; then
  os="stock";
else
  os="custom";
fi;

if [ ! -f $home/source/Image.gz ] || [ ! -f $home/source/dtb ]; then
    ui_print " " "This zip is corrupted! Aborting..."; exit 1;
fi

if [ $os == "stock" ]; then
    mv $home/source/Image.gz $home/Image.gz;
else
    mv $home/source/Image.gz $home/Image.gz-dtb;
    cat $home/source/dtb >> $home/Image.gz-dtb;
fi

## AnyKernel install
dump_boot;

if [ $os == "stock" ]; then
    mv $home/source/dtb $home/split_img/;
fi

SYSTEM_PATH=/system

if [ -f /system/system/build.prop ]; then
  SYSTEM_PATH=/system/system
  mount /system
fi

if (grep -qE 'ro.miui|ro.flyme' $SYSTEM_PATH/build.prop); then
    ui_print " " "Custom ROM detected! Applying FOD fix..."
    patch_cmdline "icekramel_helper.is_fod" "icekramel_helper.is_fod=1"
else
    patch_cmdline "icekramel_helper.is_fod" "icekramel_helper.is_fod=0"
fi

case "$ZIPFILE" in
  *BATTERY*)
    ui_print " " "BATTERY string detected! Patching cmdline..."
    patch_cmdline "icekramel_helper.is_custombatt" "icekramel_helper.is_custombatt=1"
    ;;
  *)
    patch_cmdline "icekramel_helper.is_custombatt" "icekramel_helper.is_custombatt=0"
    ;;
esac

# Clean up existing ramdisk overlays
rm -rf $ramdisk/overlay;
rm -rf $ramdisk/overlay.d;

# Inject ramdisk overlay for IceKernel
if [ -d $ramdisk/.backup ]; then
    mv $home/overlay.d $ramdisk/overlay.d;
    chmod -R 750 $ramdisk/overlay.d/*;
    chown -R root:root $ramdisk/overlay.d/*;
    chmod -R 755 $ramdisk/overlay.d/sbin/*;
    chown -R root:root $ramdisk/overlay.d/sbin/*;
fi

write_boot;
## end install
