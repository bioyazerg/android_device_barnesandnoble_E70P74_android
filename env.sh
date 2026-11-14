#!/usr/bin/env bash

# 1. Target build locale fix for legacy host tools
export LC_ALL=C

# 2. Enforce Java 8 PATH precedence first
export JAVA_HOME="$HOME/jdk8u402-b06"
export PATH="$JAVA_HOME/bin:$PATH"

# 3. Initialize Android build system
source build/envsetup.sh
lunch omni_E70P74_android-eng

# 4. Aliases for recovery compilation
alias build-twrp='mka recoveryimage'
alias build-twrp-single='make recoveryimage -j1'

echo "TWRP build environment loaded successfully!"
echo "Current Java version:"
java -version 2>&1 | head -n 1
