#!/usr/bin/env bash
#
# Tool which tries to find outdated translations in the engine strings (*.txt) using hg blame.
# Note this is only a heuristic; the output might not be 100% accurate.
# Strings which this tool lists MIGHT be outdated, so you might want to re-translate them, if needed.
# Run this in the tools/ directory.
#
# SYNTAX:
#
# ./find_outdated_engine_translations.sh <LANGUAGE>
#
# <LANGUAGE>: Language code of the language to check
#
shopt -s checkwinsize 

cd ../share/hedgewars/Data/Locale

IGNORE_CASE_WHITESPACE=1;
if ((${#@}==2))
then
    IGNORE_CASE_WHITESPACE=$2;
fi;

BLAMELANG=$1;

if [ -z $BLAMELANG ]
then
    echo "No language specified.";
    exit;
fi;
BLAMELANGFILE="$BLAMELANG.txt";

TEMP_EN=$(mktemp);
TEMP_LANG=$(mktemp);

hg blame en.txt | grep -P "^\s*\d+:\s+0[013-6]:" > $TEMP_EN;

hg blame $BLAMELANGFILE | grep -P "^\s*\d+:\s+0[013-6]:" > $TEMP_LANG;

cat $TEMP_EN | while read f;
do
    REV=$(echo $f | sed 's/:.*//');
    CODE=$(echo $f | sed 's/^[0-9]\+:\s\+//;s/=.*//');
    OTHER=$(grep -P "^\s*\d+:\s+${CODE}" $TEMP_LANG);
    if (($?==0));
    then
        OTHER_REV=$(echo $OTHER | sed 's/:.*//');
        if (($REV>$OTHER_REV));
        then
            TEXT=$(echo $f | sed 's/^\s*[0-9]\+:\s*[0-9]\+:[0-9]\+=//');
            OLD_TEXT=$(hg grep --all -r "1:$OTHER_REV" "$CODE" en.txt | tail -n1 | sed 's/.*en.txt:[0-9]\+:[+-]:[0-9]\+:[0-9]\+=//;s///');

            COMPARE_TEXT=$TEXT;
            COMPARE_OLD_TEXT=$OLD_TEXT;
            if (($IGNORE_CASE_WHITESPACE==1));
            then
                COMPARE_TEXT=$(echo $TEXT | sed 's/\s*//g' | tr A-Z a-z);
                COMPARE_OLD_TEXT=$(echo $OLD_TEXT | sed 's/\s*//g' | tr A-Z a-z);
            fi;

            if [ "$COMPARE_TEXT" != "$COMPARE_OLD_TEXT" ];
            then
                if [ -z $COLUMNS ];
                then
                    printf '━%.0s' $(seq 74);
                    echo "";
                else
                    printf '━%.0s' $(seq $COLUMNS);
                fi;
                echo "${CODE}=$TEXT ← Current English";
                echo "${CODE}=$OLD_TEXT ← English at time of translation";
                echo "${CODE}=$(echo $OTHER | sed 's/^\s*[0-9]\+:\s*[0-9]\{2\}:[0-9]\{2\}=//') ← current translation";
            fi;
        fi;
    fi;
done

rm $TEMP_EN $TEMP_LANG
