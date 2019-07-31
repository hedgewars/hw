#!/bin/sh -
echo "*** Luacheck of Lua locale files:"
luacheck ../share/hedgewars/Data/Locale/*.lua --globals locale -q
echo "Missing translations in Lua locale files:"
grep -c -- "^--" ../share/hedgewars/Data/Locale/*.lua
