#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/barnesandnoble/E70P74_android

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init.recovery.sun8iw15p1.rc:recovery/root/init.recovery.sun8iw15p1.rc \
    $(LOCAL_PATH)/init.recovery.usb.rc:recovery/root/init.recovery.usb.rc \
    $(LOCAL_PATH)/disp.ko:recovery/root/disp.ko \
    $(LOCAL_PATH)/gt82x.ko:recovery/root/gt82x.ko \
    $(LOCAL_PATH)/wacom_i2c.ko:recovery/root/wacom_i2c.ko \
    $(LOCAL_PATH)/sunxi-keyboard.ko:recovery/root/sunxi-keyboard.ko
