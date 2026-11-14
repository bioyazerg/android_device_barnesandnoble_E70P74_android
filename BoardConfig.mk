DEVICE_PATH := device/barnesandnoble/E70P74_android

# Architecture
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a7
TARGET_BOARD_PLATFORM := sun8iw15p1
PLATFORM_VERSION := 8.1.0
PLATFORM_SECURITY_PATCH := 2018-07

# Kernel & Device Tree (Prebuilt kernel fused with .fdt)
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/kernel

# Kernel Base and Offsets (MATCHED EXACTLY FROM STOCK UNPACK)
BOARD_KERNEL_BASE        := 0x40000000
BOARD_KERNEL_OFFSET      := 0x00008000
BOARD_RAMDISK_OFFSET     := 0x02000000
BOARD_SECOND_OFFSET      := 0x00f00000
BOARD_TAGS_OFFSET        := 0x00000100
BOARD_KERNEL_PAGESIZE    := 2048

# Command Line & Bootimg Args
BOARD_KERNEL_CMDLINE := selinux=1 androidboot.selinux=permissive buildvariant=user
BOARD_MKBOOTIMG_ARGS := --kernel_offset $(BOARD_KERNEL_OFFSET) --ramdisk_offset $(BOARD_RAMDISK_OFFSET) --tags_offset $(BOARD_TAGS_OFFSET) --second_offset $(BOARD_SECOND_OFFSET) --os_version $(PLATFORM_VERSION) --os_patch_level $(PLATFORM_SECURITY_PATCH)

# Partitions
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 33554432
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_RECOVERY_IMAGE_PREPARE += \
    rm -f $(TARGET_RECOVERY_ROOT_OUT)/file_contexts.bin;

# Filesystems
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# USB & ConfigFS
TW_EXCLUDE_DEFAULT_USB_INIT := true
TARGET_USE_CUSTOM_LUN_FILE_PATH := /config/usb_gadget/g1/functions/mass_storage.0/lun.%d/file

# E-Ink Display & Monochrome TWRP UI (Portrait 1404x1872)
TW_AW_EINK := true
TW_AW_EINK_A2 := true
TW_NO_SCREEN_TIMEOUT := true
TW_NO_SCREEN_BLANK := true
TW_THEME := portrait_hdpi
TW_CUSTOM_THEME := $(DEVICE_PATH)/theme
TW_INPUT_BLACKLIST := "h2w"
TW_BRIGHTNESS_PATH := "/sys/class/backlight/lm3630a_led/brightness"
TW_MAX_BRIGHTNESS := 100
TW_DEFAULT_BRIGHTNESS := 50

# Touch Calibration (Goodix gt82x on 90-deg rotated Portrait panel)
RECOVERY_TOUCHSCREEN_SWAP_XY := true
RECOVERY_TOUCHSCREEN_FLIP_Y := true
TW_IGNORE_MAJOR_AXIS_0 := true

ALLOW_MISSING_DEPENDENCIES := true

# Inject stock Nook/Allwinner SELinux policy & file_contexts before packing recovery ramdisk
BOARD_RECOVERY_IMAGE_PREPARE = cp -f $(DEVICE_PATH)/sepolicy/sepolicy $(DEVICE_PATH)/sepolicy/plat_file_contexts $(DEVICE_PATH)/sepolicy/nonplat_file_contexts $(DEVICE_PATH)/sepolicy/file_contexts.bin $(TARGET_RECOVERY_ROOT_OUT)/ && cat $(DEVICE_PATH)/sepolicy/plat_file_contexts $(DEVICE_PATH)/sepolicy/nonplat_file_contexts > $(TARGET_RECOVERY_ROOT_OUT)/file_contexts
