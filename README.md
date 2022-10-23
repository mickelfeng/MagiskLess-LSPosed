# MagiskLess-LSPosed

Fork of the [LSPosed](https://github.com/LSPosed/LSPosed) Magisk module.

This fork is a version of LSposed that does not require Magisk to be installed on the device.

It does require Riru to work (see [MagiskLess-Riru](https://github.com/Alhyoss/MagiskLess-Riru) or [Riru](https://github.com/RikkaApps/Riru)).

## Requirements

* Android 8.1 to 13
* [Riru](https://github.com/RikkaApps/Riru) or [MagiskLess-Riru](https://github.com/Alhyoss/MagiskLess-Riru)

And if you want to use the provided template to install MagiskLess-Riru on the device:
* Permissive 'su' SELinux context (should be present on userdebug builds such as on LineageOS)
* No dm-verity

## Guide

### Install

   1. Enter recovery mode on your device, and select "Apply update from ADB"
   2. Make sure that the 'riruModulePath' variable in the root build.gradle.kt is correct
   3. Run the command following:
  ```
  gradle flashRelease
  ```
  
### Build

Gradle tasks:

* `zipDebug/Release`

  Build an update package (using the [android-flashable-zip](https://github.com/Alhyoss/android-flashable-zip) template).

* `flashDebug/Release`

  Build an update package (using the [android-flashable-zip](https://github.com/Alhyoss/android-flashable-zip) template) and sideload it to the device.

## Troubleshooting

You may encounter SELinux issues on your device when installing MagiskLess-Riru or a Riru module.

If you are using the provided template, you can inject the required SELinux policies by using the `inject_selinux_policy` util method in the `update.sh` file:
```
inject_selinux_policy -s zygote -t adb_data_file -c dir -p search
```

You can find the required SELinux policies in Logcat:
```
adb logcat | grep avc
```

## License

LSPosed is licensed under the **GNU General Public License v3 (GPL-3)** (http://www.gnu.org/copyleft/gpl.html).
