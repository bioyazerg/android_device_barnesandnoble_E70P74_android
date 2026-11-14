#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common Omni stuff.
$(call inherit-product, vendor/omni/config/common.mk)

# Inherit from E70P74_android device
$(call inherit-product, device/barnesandnoble/E70P74_android/device.mk)

PRODUCT_DEVICE := E70P74_android
PRODUCT_NAME := omni_E70P74_android
PRODUCT_BRAND := NOOK
PRODUCT_MODEL := BNRV1300
PRODUCT_MANUFACTURER := barnesandnoble

PRODUCT_GMS_CLIENTID_BASE := android-barnesandnoble

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="E70P74_android-user 8.1.0 b3b5739 8.1.7.120_user release-keys"

BUILD_FINGERPRINT := NOOK/E70P74_android/E70P74_android:8.1.0/b3b5739/8.1.7.120_user:user/release-keys
