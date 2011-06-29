#!/bin/sh

${ANDROID_SDK}/platform-tools/adb push ./out/libhwengine.so /sdcard/libhwengine.so
${ANDROID_SDK}/platform-tools/adb shell "su -c \"cat /sdcard/libhwengine.so > /data/data/org.hedgewars/lib/libhwengine.so \""

