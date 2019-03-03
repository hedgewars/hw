#!/bin/sh -
# Script to check locale files

# HOW TO USE:
# - Run this script in the tools/ directory.
# Result: Problems and missing translations in some locale files will be reported

# SYNTAX:
#
#     ./check_locale_files.sh
#

./check_engine_locale_files.sh ALL 0
./check_lua_locale_files.sh
lua ./check_lua_locale_files.lua
