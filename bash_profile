#!/usr/bin/env bash

# This file is not intended for direct execution
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then exit; fi

if [[ -f "$HOME/.bashrc" ]]; then
    . "$HOME/.bashrc"
fi

# added by setup_fb4a.sh
export ANDROID_SDK=/opt/android_sdk
export ANDROID_NDK_REPOSITORY=/opt/android_ndk
export ANDROID_HOME=${ANDROID_SDK}
export PATH=${PATH}:${ANDROID_SDK}/emulator:${ANDROID_SDK}/tools:${ANDROID_SDK}/tools/bin:${ANDROID_SDK}/platform-tools
