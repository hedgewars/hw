#!/bin/sh -
# Script to update all Lua locale files.
# It's Clunky and slow!
# Note this script may sooner or later be phased out when we move to Gettext.

# HOW TO USE:
# - Run this script in the tools/ directory.
# - All .lua files in share/hedgewars/Data/Locale will be updated.
# - Change LOCALEFILES below to limit the number of locale files to update

# Space-separated list of locale files to update, or *.lua for all.
# (Note: always include stub.lua)
LOCALEFILES="*.lua"

# List of all Lua files to scan:
# * Missions
# * Campaign missions
# * Lua libraries
# * Styles (aka multiplayer scripts)
# * Mission maps
# IMPORTANT: Don't forget to update this list when new places for Lua
#            directories have been added!
LUAFILES="../Missions/Challenge/*.lua\
 ../Missions/Scenario/*.lua\
 ../Missions/Training/*.lua\
 ../Missions/Campaign/*/*.lua\
 ../Scripts/*.lua\
 ../Scripts/Multiplayer/*.lua\
 ../Maps/*/map.lua"

cd ../share/hedgewars/Data/Locale;

# Collect strings
echo "Step 1: Collect strings";
echo -n "" > __temp_loc;
for F in loc loc_noop;
	do
	grep -F "$F(\"" $LUAFILES | sed 's/")/")\n/g' | sed "s/.*$F(\"/loc(\"/;s/\").*/\")/" | grep loc | sort | uniq >> __temp_loc;
done

# Update locale files
# This step is clunky and inefficient. Improve performance (if you are bored)!
echo "Step 2: Update locale files (this may take a while)";
for i in $LOCALEFILES;
do
	echo $i;
	cat __temp_loc | while read f
		do
		STR=$(echo "$f" | sed 's/loc("//;s/")\s*$//;s/"/\\"/g');
		MAPS=$(grep -F -l -- "loc(\"${STR}\")" $LUAFILES | sed 's/.*\/\([^\/]*\)\/map.lua/\1/;s/.*Campaign\/\([^\/]*\)\//\1:/;s/.*\///;s/.lua//;s/ /_/g' | xargs | sed 's/ /, /g');
		C=$(echo $MAPS | sed 's/,/\n/' | wc -l)
		grep -Fq -- "[\"${STR}\"]" $i;
		if (($?));
		then
			if ((C>0));
			then
				echo "--      [\"${STR}\"] = \"\", -- $MAPS" >> $i;
			else
				echo "--      [\"${STR}\"] = \"\"," >> $i;
			fi;
		fi;
	done;
done

# Sort
echo "Step 3: Sort strings";
for i in $LOCALEFILES;
do
	echo $i;
	rm -f __temp_head __temp_tail __temp_lua;
	cat $i | grep -Ev "}|{" | grep -Ev "^[[:space:]]*$" | sort | uniq > __temp_lua;
	echo "locale = {" > __temp_head;
	echo "}" > __temp_tail;
	cat __temp_head __temp_lua __temp_tail > $i;
done

# Drop unused
echo "Step 4: Delete unused strings";
cat stub.lua | grep '"] =' | while read f;
do
	PHRASE=$(echo "$f" | sed 's/[^[]*\["//;s/"] =.*//;s/"/\\"/g');
	CNT=$(grep -Frc "loc(\"$PHRASE\")" __temp_loc);
	if (($CNT==0));
	then
		echo "|$PHRASE|";
		PHRASE=$(echo "$PHRASE" | sed 's/\\/\\\\/g;s/\[/\\[/g;s/\]/\\]/g;s/\//\\\//g');
		sed -i "/.*\[\"$PHRASE\"\].*/d" $LOCALEFILES;
	fi;
done

# Delete temporary files
rm __temp_head __temp_tail __temp_lua __temp_loc;

echo "Done."
