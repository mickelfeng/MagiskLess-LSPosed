#!/sbin/sh

# Create riru directory
LSPOSEDDIR=@RIRU_PATH@/riru_lsposed

package_extract_dir files $INSTALLDIR

mkdir -p $LSPOSEDDIR

add_file() {
  FROM=$1
  TO=$2

  cp $FROM $TO
  set_metadata $TO uid root guid root mode 644 selabel "u:object_r:system_file:s0"
}

FLAVOR="riru"

if [ "$API" -lt 27 ]; then
    abort "! Unsupported Android version $API (below Oreo MR1)"
fi

# Check architecture
if [ "$ARCH" != "arm" ] && [ "$ARCH" != "arm64" ] && [ "$ARCH" != "x86" ] && [ "$ARCH" != "x64" ]; then
  abort "! Unsupported platform: $ARCH"
else
  ui_print "- Device platform: $ARCH"
fi

# Extract libs
ui_print "- Extracting module files"

mkdir -p $LSPOSEDDIR/framework
mkdir -p $LSPOSEDDIR/riru/lib
mkdir -p /data/adb/lspd

add_file $INSTALLDIR/daemon $LSPOSEDDIR/daemon
add_file $INSTALLDIR/daemon.apk $LSPOSEDDIR/daemon.apk
add_file $INSTALLDIR/framework/lspd.dex $LSPOSEDDIR/framework/lspd.dex
add_file $INSTALLDIR/manager.apk /data/adb/lspd/manager.apk
add_file $INSTALLDIR/lib/$ABI32/liblspd.so $LSPOSEDDIR/riru/lib/liblspd.so

if [ $IS64BIT ]; then
    mkdir -p $LSPOSEDDIR/riru/lib64
    add_file $INSTALLDIR/lib/$ABI/liblspd.so $LSPOSEDDIR/riru/lib64/liblspd.so
fi

if [ "$API" -ge 29 ]; then
    ui_print "- Extracting dex2oat binaries"
    mkdir "$LSPOSEDDIR/bin"

    add_file $INSTALLDIR/bin/$ABI32/dex2oat $LSPOSEDDIR/bin/dex2oat32
    if [ $IS64BIT ]; then
        add_file $INSTALLDIR/bin/$ABI/dex2oat $LSPOSEDDIR/bin/dex2oat64
    fi

    ui_print "- Patching binaries"
    DEV_PATH=$(tr -dc 'a-f0-9' < /dev/urandom | head -c 16)
    while [ -d "/dev/$DEV_PATH" ]; do
        DEV_PATH=$(tr -dc 'a-f0-9' < /dev/urandom | head -c 16)
    done
    sed -i "s/placeholder_\/dev\/................/placeholder_\/dev\/$DEV_PATH/g" "$LSPOSEDDIR/daemon.apk"
    sed -i "s/placeholder_\/dev\/................/placeholder_\/dev\/$DEV_PATH/" "$LSPOSEDDIR/bin/dex2oat32"
    sed -i "s/placeholder_\/dev\/................/placeholder_\/dev\/$DEV_PATH/" "$LSPOSEDDIR/bin/dex2oat64"
fi

chcon u:object_r:system_file:s0 $LSPOSEDDIR
ch_con_recursive u:object_r:system_file:s0 u:object_r:system_file:s0 $LSPOSEDDIR/

set_perm_recursive 0 0 0755 0644 $LSPOSEDDIR
set_perm_recursive 0 0 0755 0755 $LSPOSEDDIR/bin
ch_con_recursive u:object_r:dex2oat_exec:s0 u:object_r:dex2oat_exec:s0 $LSPOSEDDIR/bin
chmod 0744 "$LSPOSEDDIR/daemon"

mv $INSTALLDIR/resetprop /system/bin/resetprop
chmod 755 /system/bin/resetprop
add_file $INSTALLDIR/riru-lsposed.rc /system/etc/init/riru-lsposed.rc

inject_selinux_policy -s init -t su -c process2 -p nosuid_transition
inject_selinux_policy -s zygote -t appdomain_tmpfs -c file -p read,write,open,getattr
inject_selinux_policy -s system_server -t system_server -c process -p execmem
inject_selinux_policy -s system_server -t tmpfs -c file -p getattr,read,open
inject_selinux_policy -s system_server -t shell -c file -p getattr,read,open
inject_selinux_policy -s idmap -t tmpfs -c dir -p write,add_name,remove_name
inject_selinux_policy -s idmap -t tmpfs -c file -p create,read,write,open,getattr
inject_selinux_policy -s shell -t shell -c dir -p write
inject_selinux_policy -s shell -t tmpfs -c file -p read,open,getattr
inject_selinux_policy -s shell -t sysfs_msm_subsys -c file -p read,open,getattr
inject_selinux_policy -s installd -t system_file -c file -p execute_no_trans
inject_selinux_policy -s platform_app -t tmpfs -c file -p read,open,getattr
inject_selinux_policy -s system_app -t tmpfs -c file -p read,open,getattr
inject_selinux_policy -s radio -t tmpfs -c file -p read,open,getattr
inject_selinux_policy -s nfc -t tmpfs -c file -p read,open,getattr
inject_selinux_policy -s priv_app -t tmpfs -c file -p read,open,getattr
inject_selinux_policy -s gmscore_app -t tmpfs -c file -p read,open,getattr
inject_selinux_policy -s snap_app -t tmpfs -c file -p read,open,getattr

ui_print "- Welcome to LSPosed!"
