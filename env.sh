#!/usr/bin/env bash

# 1. Target build locale fix for legacy host tools
export LC_ALL=C

# 2. Enforce in-tree prebuilt Python 2.7.5 precedence
SCRIPT_TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." 2>/dev/null && pwd)"
if [ -d "$PWD/prebuilts/python/linux-x86/2.7.5/bin" ]; then
    export PATH="$PWD/prebuilts/python/linux-x86/2.7.5/bin:$PATH"
elif [ -d "$SCRIPT_TOP/prebuilts/python/linux-x86/2.7.5/bin" ]; then
    export PATH="$SCRIPT_TOP/prebuilts/python/linux-x86/2.7.5/bin:$PATH"
fi

# 3. Enforce Java 8 PATH precedence
export JAVA_HOME="$HOME/jdk8u402-b06"
export PATH="$JAVA_HOME/bin:$PATH"

# 4. Initialize Android build system
source build/envsetup.sh
lunch omni_E70P74_android-eng

# 5. Aliases for recovery compilation
alias build-twrp='mka recoveryimage'
alias build-twrp-single='make recoveryimage -j1'

echo "TWRP build environment loaded successfully!"
echo "Current Java version:"
java -version 2>&1 | head -n 1
echo "Current Python version:"
python --version 2>&1
