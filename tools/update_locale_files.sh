#!/bin/sh -
# Script to update all Lua and frontend locale files.

# HOW TO USE:
# - Run this script in the tools/ directory.
# Result: All .ts and .lua files in share/hedgewars/Data/Locale will be updated.
# This will take a while!

./update_frontend_locale_files.sh
./update_lua_locale_files.sh
