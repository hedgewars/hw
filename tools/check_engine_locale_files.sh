#!/bin/sh -
# Script to check all engine locale files (XX.txt)

# HOW TO USE:
# - Run this script in the tools/ directory.
# Result: All problems and missing translations in .txt files will be reported

# SYNTAX:
#
#     ./check_engine_locale_files.sh [file_to_check [show_untranslated]]
#
# Optional parameters:
#
# * file_to_check: Add this if you want to check a single file. Use the special value ALL to check all files.
# * show_untranslated: Set to 0 if you want to hide the list of untranslated files, set to 1 otherwise

SHOW_UNTRANSLATED_STRINGS=1;
CHECKED_FILES=*.txt

# Parse command line
if [[ $# -gt 0 ]]
then
	if [ $1 = ALL ]
	then
		CHECKED_FILES=*.txt
	else
		CHECKED_FILES=$1;
	fi
fi
if [[ $# -gt 1 ]]
then
	if [[ $2 -eq 1 ]]
	then
		SHOW_UNTRANSLATED_STRINGS=1;
	elif [[ $2 -eq 0 ]]
	then
		SHOW_UNTRANSLATED_STRINGS=0;
	fi
fi

cd ../share/hedgewars/Data/Locale;

# Temporary files
TEMP_SYMBOLS_EN=$(mktemp);
TEMP_SYMBOLS=$(mktemp);
TEMP_COMPARE=$(mktemp);
TEMP_COMPARE_2=$(mktemp);
TEMP_CHECK=$(mktemp);
TEMP_TEMP=$(mktemp);
declare -a TEMP_PARAMS;
for n in 0 1 2 3 4 5 6 7 8 9
do
	TEMP_PARAMS[$n]=$(mktemp);
done

# Collect list of string IDs
echo -n "" > $TEMP_SYMBOLS_EN;
grep -o "^[0-9][0-9]:[0-9][0-9]=" en.txt | cut -c1-5 | sort | uniq > $TEMP_SYMBOLS_EN;
TOTAL_STRINGS=`wc -l < $TEMP_SYMBOLS_EN`;

# Collect strings with placeholders (only in 01:XX)
for n in 0 1 2 3 4 5 6 7 8 9
do
	grep -o "^01:[0-9][0-9]=.*%$n.*" en.txt | cut -c1-5 | sort | uniq > $TEMP_PARAMS[$n];
done

# Iterate through selected language files
for CHECKED_LANG_FILE in $CHECKED_FILES;
	# Skip files that don't contain engine strings
	do
	if [[ $CHECKED_LANG_FILE == campaigns_* ]] || [[ $CHECKED_LANG_FILE == missions_* ]] || [ $CHECKED_LANG_FILE == CMakeLists.txt ]
	then
		continue;
	fi
	if [ ! -e $CHECKED_LANG_FILE ]
	then
		echo "ERROR: $CHECKED_LANG_FILE not found!";
		continue;
	fi
	if [ ! -r $CHECKED_LANG_FILE ]
	then
		echo "ERROR: No permission to read $CHECKED_LANG_FILE!";
		continue;
	fi

	# Start the tests
	echo "== $CHECKED_LANG_FILE ==";
	MISSING_STRINGS=0;
	HAS_PROBLEMS=0;

	if [ $CHECKED_LANG_FILE != en.txt ]
	then
		grep -o "^[0-9][0-9]:[0-9][0-9]=" $CHECKED_LANG_FILE | cut -c1-5 | sort | uniq > $TEMP_SYMBOLS;

		# Find strings with missing placeholders
		> $TEMP_COMPARE;
		> $TEMP_COMPARE_2;
		for n in 0 1 2 3 4 5 6 7 8 9
		do
			grep -o "^01:[0-9][0-9]=.*%$n.*" $CHECKED_LANG_FILE | cut -c1-5 | sort | uniq > $TEMP_CHECK;
			comm $TEMP_PARAMS[$n] $TEMP_CHECK -2 -3 >> $TEMP_COMPARE;
			comm $TEMP_PARAMS[$n] $TEMP_CHECK -1 -3 >> $TEMP_COMPARE_2;
		done
		cat $TEMP_COMPARE | cut -c1-5 | sort | uniq > $TEMP_TEMP;
		cat $TEMP_TEMP > $TEMP_COMPARE;
		comm $TEMP_COMPARE $TEMP_SYMBOLS -1 -2 > $TEMP_TEMP;
		if [ -s $TEMP_TEMP ]
		then
			echo "ERROR! Missing placeholders in these strings:";
			cat $TEMP_TEMP;
			HAS_PROBLEMS=1;
		fi
		cat $TEMP_COMPARE_2 | cut -c1-5 | sort | uniq > $TEMP_TEMP;
		cat $TEMP_TEMP > $TEMP_COMPARE_2;
		comm $TEMP_COMPARE_2 $TEMP_SYMBOLS -1 -2 > $TEMP_TEMP;
		if [ -s $TEMP_TEMP ]
		then
			echo "ERROR! Invalid placeholders found in these strings:";
			cat $TEMP_TEMP;
			HAS_PROBLEMS=1;
		fi
	
		# Find superficial strings
		comm $TEMP_SYMBOLS_EN $TEMP_SYMBOLS -1 -3 > $TEMP_COMPARE;
		if [ -s $TEMP_COMPARE ]
		then
			echo "WARNING! Superficial strings that do not exist in en.txt:";
			cat $TEMP_COMPARE;
			HAS_PROBLEMS=1;
		fi
	
		# Find missing translations
		comm $TEMP_SYMBOLS_EN $TEMP_SYMBOLS -2 -3 > $TEMP_COMPARE;
		if [ -s $TEMP_COMPARE ]
		then
			if [ $SHOW_UNTRANSLATED_STRINGS -eq 1 ]
			then
				echo "Missing translations:";
				cat $TEMP_COMPARE;
			fi
			MISSING_STRINGS=`wc -l < $TEMP_COMPARE`;
		fi

		# Print summary
		if [ $MISSING_STRINGS -ne 0 ]
		then
			echo "Missing translations TOTAL: $MISSING_STRINGS/$TOTAL_STRINGS";
		else
			echo "All strings translated!";
		fi
		if [ $HAS_PROBLEMS -eq 1 ]
		then
			echo "Problems have been found.";
		fi
	else
		if [ $HAS_PROBLEMS -eq 0 ]
		then
			echo "No problems.";
		fi
	fi;
		
done;

# Clean up files
rm $TEMP_SYMBOLS $TEMP_SYMBOLS_EN $TEMP_COMPARE $TEMP_COMPARE_2 $TEMP_CHECK $TEMP_TEMP;
