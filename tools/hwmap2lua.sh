#!/bin/sh -
# === HWMAP-to-Lua converter ===
# This script allows you to put arbitrary HWMAPs into your missions!
#
# Usage:
# It expects a .hwmap file of name "map.hwmap" to be in
# its directory and creates a Lua file (map.lua) containing code to
# draw the map.
# In Lua, call drawMap() in onGameInit. And don't forget
# to set MapGen to mgDrawn. Then your map should be ready to go! :-)
#
# Many thanks to szczur!

# FILE NAMES 
IN="./map.hwmap";
OUT="./map.lua";

# TEMPORARY FILES
TEMP_UNBASE=$(mktemp);
TEMP_GZIP=$(mktemp);
TEMP_OCTETS=$(mktemp);
base64 -d $IN | tail -c +7 | head -c -4 > $TEMP_UNBASE;
echo -ne "\x1f\x8b\x08\0\0\0\0\0\x02\xff" > $TEMP_GZIP;
# Suppress gunzip warning: "gzip: stdin: unexpected end of file"
cat $TEMP_GZIP $TEMP_UNBASE | gunzip 2> /dev/null > $TEMP_OCTETS;
C=0;
echo -n '-- Map definition automatically converted from HWMAP file by hwmap2lua.sh
local map = {' > $OUT;
od -w240 -t u1 $TEMP_OCTETS | grep -Ev "^[0-9]*[[:space:]]*$" | while read f;
do C=$((C+1));
	if ((C!=1));
	then
		echo "," >> $OUT;
	fi;
	echo -n $f | sed "s/^......./'/;s/  */\\\\/g;s/$/'/" >> $OUT;
done;
echo '}

local function drawMap()
	for m=1, #map do
		ParseCommand("draw "..map[m])
	end
end' >> $OUT;
rm $TEMP_UNBASE $TEMP_GZIP $TEMP_OCTETS;
