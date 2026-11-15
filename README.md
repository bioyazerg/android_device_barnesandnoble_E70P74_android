# TWRP for Barnes & Noble Nook Glowlight 4 Plus (`E70P74_android` / `sun8iw15p1`)

Developer guide for building, flashing, and verifying Team Win Recovery Project (TWRP) with working `.tar` and raw partition backups/restores on the Barnes & Noble Nook Glowlight 4 Plus (`E70P74_android`, Allwinner `sun8iw15p1`, board codename `emperor`).

> **Important note:**
> The stock bootloader accepts `fastboot boot recovery.img` and reports `OKAY`, **but it does not actually boot the image**. Temporary ramdisk booting via `fastboot boot` is non-functional on this device—you must flash the recovery image directly to the `recovery` partition (`fastboot flash recovery ...` or `dd`).

* **Python 2.7 (Bundled in Source Tree):** Legacy Android/OmniROM build tools (`roomservice.py`, `check_radio_versions.py`) require Python 2 syntax. No host Python 2 installation is required—even on modern Linux distributions where `python` maps to Python 3 (`python-is-python3`), the TWRP source tree includes a prebuilt binary at `prebuilts/python/linux-x86/2.7.5/bin`.
* **Java 8 (Host Required):** OpenJDK 8 is not bundled in `prebuilts/` for this manifest and must be installed on the host (configured via `JAVA_HOME` in `env.sh`, defaulting to `$HOME/jdk8u402-b06`).
* **Locale:** `LC_ALL=C` is required to prevent collation/sorting issues in legacy host tools. 

## Acknowledgments
Special thanks to **[Ryogo-X/nook_gentoo_twrp](https://github.com/Ryogo-X/nook_gentoo_twrp)** for the foundational reverse-engineering, kernel/module bring-up, and initial TWRP device tree work on this platform that made this build possible.

### Quick rebuild steps
From the root of the synced TWRP source tree:
1. `git clone https://github.com/bioyazerg/android_device_barnesandnoble_E70P74_android.git device/barnesandnoble/E70P74_android`
2. `git -C bootable/recovery apply ../../device/barnesandnoble/E70P74_android/bootable_recovery.patch`
3. `source device/barnesandnoble/E70P74_android/env.sh`
4. `mka recoveryimage`

---

## 1. Device Tree Overview

Place or clone this device tree at `device/barnesandnoble/E70P74_android` inside an OmniROM / TWRP 8.1-based build tree:

- **Build & Product makefiles:**
  - `Android.mk`, `AndroidProducts.mk`, `omni_E70P74_android.mk`, `device.mk`, `vendorsetup.sh`
  - `BoardConfig.mk` — Partition sizes, kernel/DTB parameters, `make_ext4fs` / `mkfs.f2fs` flags, and recovery ramdisk preparation hooks.
  - `recovery.fstab` — Partition mountpoints, block device mappings (`/dev/block/by-name/*`), and backup/flash flags.
- **Prebuilt kernel & Device Tree:**
  - `zImage` / `kernel` / `prebuilt/kernel` and `dt.img`
- **Kernel modules (`modules/`):**
  - `disp.ko`, `gt82x.ko`, `mali.ko`, `sunxi-keyboard.ko`, `wacom_i2c.ko` (see Section 2)
- **Recovery init & ramdisk overlay (`recovery/root/`):**
  - `init.rc`, `init.recovery.sun8iw15p1.rc`, `init.recovery.usb.rc`
  - `ueventd.rc`, `ueventd.sun8iw15p1.rc`
  - `proof_of_life.sh`
- **SELinux policy & file contexts (`sepolicy/`):**
  - `sepolicy`, `plat_file_contexts`, `nonplat_file_contexts`, `file_contexts.bin`
- **Custom portrait UI theme (`theme/`):**
  - `portrait.xml`, `splash.xml`, `ui.xml`, and `images/`

---

## 2. Kernel modules (`modules/`)

Allwinner `sun8iw15p1` hardware support in recovery relies on five prebuilt kernel modules located in `device/barnesandnoble/E70P74_android/modules/` (and copied into the recovery ramdisk root `/` during build, where `init.recovery.sun8iw15p1.rc` loads them via `insmod`):

| Module | Hardware component | Role in recovery |
| :--- | :--- | :--- |
| `disp.ko` | Allwinner Display Engine | Initializes framebuffer / panel output for the TWRP GUI |
| `gt82x.ko` | Goodix Capacitive Touchscreen | Enables finger touch input in TWRP |
| `wacom_i2c.ko` | Wacom I2C Digitizer | Enables stylus/pen input |
| `sunxi-keyboard.ko` | Hardware Key / ADC Keypad | Enables physical page-turn and power buttons |
| `mali.ko` | ARM Mali GPU | Provides GPU driver support required by the platform |

---

## 3. Key configuration design (`BoardConfig.mk` & `recovery.fstab`)

To ensure file-based `.tar` backups restore into a bootable Android system under SELinux enforcing mode and match stock bootloader expectations, the device tree uses the following configuration:

### A. Partition table (`recovery.fstab`)
`backup=1` is enabled **only** on the file-based `ext4` entries (`/system`, `/vendor`) so TWRP does not create duplicate/conflicting raw `.emmc.win` and `.ext4.win` archives during backup or restore. Raw block entries (`/system_image`, `/vendor_image`) retain `flashimg=1` so raw `.img` files can still be flashed from the TWRP UI.

```fstab
/boot           emmc    /dev/block/by-name/boot       flags=backup=1;flashimg=1
/recovery       emmc    /dev/block/by-name/recovery   flags=backup=1;flashimg=1
/misc           emmc    /dev/block/by-name/misc       flags=backup=1;flashimg=1
/system         ext4    /dev/block/by-name/system     flags=backup=1
/system_image   emmc    /dev/block/by-name/system     flags=flashimg=1
/vendor         ext4    /dev/block/by-name/vendor     flags=backup=1
/vendor_image   emmc    /dev/block/by-name/vendor     flags=flashimg=1
/cache          ext4    /dev/block/by-name/cache
/data           f2fs    /dev/block/by-name/UDISK      flags=backup=1;encryptable=/dev/block/by-name/metadata
/usb_otg        auto    /dev/block/sda1 /dev/block/sda flags=storage;wipeingui;removable
```

### B. `make_ext4fs` & superblock feature parity (`BoardConfig.mk`)
`TARGET_USERIMAGES_USE_EXT4 := true` compiles `/sbin/make_ext4fs` into the recovery ramdisk so TWRP formats `/system` and `/vendor` with `make_ext4fs` rather than plain `mke2fs`. This preserves the stock `ext4` superblock feature bitmasks (`00000100 0000001c 00000042 00000013` at byte offset `1024 + 88`) and applies SELinux labels to partition root inodes during format.

### C. Text `file_contexts` resolution (`BoardConfig.mk`)
`BOARD_RECOVERY_IMAGE_PREPARE` removes `file_contexts.bin` from `$(TARGET_RECOVERY_ROOT_OUT)` before packing the recovery ramdisk. This forces `libselinux` to resolve contexts from text `/file_contexts` (`/system(/.*)? -> u:object_r:system_file:s0`) so `/system` is labeled `u:object_r:system_file:s0` rather than `u:object_r:rootfs:s0`.

```makefile
TARGET_USERIMAGES_USE_EXT4 := true

BOARD_RECOVERYIMAGE_PARTITION_SIZE := 33554432
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_RECOVERY_IMAGE_PREPARE += \
    rm -f $(TARGET_RECOVERY_ROOT_OUT)/file_contexts.bin;
```

---

## 4. Building from source

From the root of your TWRP build tree:

```bash
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
lunch omni_E70P74_android-eng
mka recoveryimage
```

The resulting recovery image is written to:
`out/target/product/E70P74_android/recovery.img`

### Verify compiled ramdisk contents before flashing
Confirm that `make_ext4fs`, `mkfs.f2fs`, `fsck.f2fs`, and the kernel modules are present in the recovery ramdisk, `make_ext4fs` is linked into TWRP, and `file_contexts.bin` was stripped from the recovery root:

```bash
test -x out/target/product/E70P74_android/recovery/root/sbin/make_ext4fs && echo "OK: make_ext4fs present"
test -x out/target/product/E70P74_android/recovery/root/sbin/mkfs.f2fs && echo "OK: mkfs.f2fs present"
test -x out/target/product/E70P74_android/recovery/root/sbin/fsck.f2fs && echo "OK: fsck.f2fs present"
for ko in disp.ko gt82x.ko mali.ko sunxi-keyboard.ko wacom_i2c.ko; do
  test -f "out/target/product/E70P74_android/recovery/root/$ko" && echo "OK: $ko present"
done
test ! -e out/target/product/E70P74_android/recovery/root/file_contexts.bin && echo "OK: file_contexts.bin removed"
strings out/target/product/E70P74_android/recovery/root/sbin/recovery \
        out/target/product/E70P74_android/recovery/root/sbin/libtwrp*.so 2>/dev/null | grep -F "make_ext4fs"
```

---

## 5. Flashing `recovery.img`

*(Reminder: Always use `flash`, not `fastboot boot`.)*

### Option A: From fastboot (bootloader mode)
Enter bootloader mode (`adb reboot bootloader` or hardware key combo) and flash directly to the `recovery` partition:
```bash
fastboot flash recovery out/target/product/E70P74_android/recovery.img
fastboot reboot
```
*(Or `fastboot flash recovery twrp.img` if you renamed the output image.)*

### Option B: From rooted Android using `adb`
```bash
adb push out/target/product/E70P74_android/recovery.img /sdcard/recovery.img
adb shell "su -c 'dd if=/sdcard/recovery.img of=/dev/block/by-name/recovery bs=4096 && sync'"
adb reboot recovery
```

### Option C: From existing TWRP
```bash
adb push out/target/product/E70P74_android/recovery.img /tmp/recovery.img
adb shell "dd if=/tmp/recovery.img of=/dev/block/by-name/recovery bs=4096 && sync"
adb reboot recovery
```

---

## 6. Backup & Restore verification guide

### Verified Working Partitions
- **`boot` (`emmc`):** Raw partition backup (`boot.emmc.win`) and restore verified bit-identical against `/dev/block/by-name/boot`.
- **`system` & `vendor` (`ext4` `.tar`):** File-based backups (`system.ext4.win`, `vendor.ext4.win`) capture all files, symlinks, `RHT.security.selinux` contexts, and POSIX `SCHILY.xattr.security.capability` headers, and restore cleanly into a bootable Android OS.
- **`data` (`f2fs` `.tar` on `/dev/block/by-name/UDISK`):** Device uses unencrypted F2FS (`ro.crypto.state=unencrypted`, superblock magic `f2f52010`, version `1.8`, feature mask `0x00000001`). File-based backups (`data.f2fs.win000`, `data.f2fs.win001`, etc.) preserve `RHT.security.selinux` xattrs and restore cleanly into a working Android OS with apps, accounts, and internal storage intact.

### `/data` Storage Behavior (`Has_Data_Media` vs. `Format Data`)
- **Standard Backup / Restore / Wipe Data:** TWRP detects `Has_Data_Media` (`Storage_Path: /data/media/0`). During a normal `/data` wipe or restore, TWRP deletes everything under `/data` *except* `/data/media`, leaving internal `/sdcard` files and `/data/media/0/TWRP/BACKUPS/` intact (no USB OTG drive required). Note that in TWRP, `/sdcard` points to `/data/media`, whereas booted Android maps `/sdcard` to `/data/media/0`.
- **Format Data (typing `yes`):** Executes `mkfs.f2fs` on `/dev/block/by-name/UDISK` and wipes the entire partition including `/data/media/0`. Always copy backups off-device via `adb pull` before running **Format Data**.

### Post-Restore Sanity Check Inside TWRP (Before Rebooting to Android)
After running a restore in TWRP, verify formatting, SELinux mountpoint contexts, and `ext4` superblock flags before leaving recovery:

```bash
adb shell '
grep -E "Formatting (System|Vendor) using" /tmp/recovery.log | tail -n 4
mount -o ro /system 2>/dev/null; mount -o ro /vendor 2>/dev/null; mount /data 2>/dev/null
ls -Zd /system /vendor /system/bin/sh /vendor/bin/hw
ls -Zd /data /data/app /data/system /data/media /data/media/0
umount /system /vendor 2>/dev/null
hexdump -s 1112 -n 16 -e "4/4 \"%08x \" \"\n\"" /dev/block/by-name/vendor
hexdump -s 1112 -n 16 -e "4/4 \"%08x \" \"\n\"" /dev/block/by-name/system
'
```

Expected output:
- **Formatter log:** `Formatting System using make_ext4fs...` and `Formatting Vendor using make_ext4fs...`
- **`/system` & `/vendor` root labels:** `/system` -> `u:object_r:system_file:s0`, `/vendor` -> `u:object_r:vendor_file:s0`
- **`/data` labels:** `/data` & `/data/system` -> `u:object_r:system_data_file:s0`, `/data/app` -> `u:object_r:apk_data_file:s0`, `/data/media` & `/data/media/0` -> `u:object_r:media_rw_data_file:s0`
- **Superblock flags:** `00000100 0000001c 00000042 00000013` on both `/dev/block/by-name/vendor` and `/dev/block/by-name/system`

