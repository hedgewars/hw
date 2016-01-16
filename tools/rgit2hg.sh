#!/bin/sh

#HW_HG=

if [ -z "$1" ]; then
    echo 'You have to supply at least one hedgewars git revision as parameter!' >&2
    exit
fi

if [ -z "$HW_HG" ]; then 
    HW_HG="$PWD"
fi

if [ ! -d "$HW_HG/.hg" ]; then
    echo 'You have to set HW_HG (inside script or env) to a repo clone OR call this script from inside the repository!' >&2
    exit
fi

while [ ! -z "$1" ]; do
    echo
    echo
    echo '---------------------------------------------------------------'
    echo "$1"
    echo '---------------------------------------------------------------'
    url="https://github.com/hedgewars/hw/commit/$1"
    echo "Checking $url ..."
    echo
    page=$(wget -q -O- "$url")
    author=$(echo "$page" | sed -rn '1,/"user-mention"/{s/^.*"user-mention"( *[^>]*)?> *([^ <]*).*$/\2/ p}')
    if [ -z "$author" ]; then
        echo 'Couldn'\''t find author! Skipping '"$1"' ...' >&2
        shift
        continue
    fi
    echo 'Found author: '"$author"
    date=$(echo "$page" | sed -rn 's/^.*<time datetime="([^T]+)T([^Z]+).*/\1 \2 +0000/ p')
    if [ -z "$date" ]; then
        echo 'Couldn'\''t find date! Skipping '"$1"' ...' >&2
        shift
        continue
    fi
    echo 'Found date:   '"$date"
    echo
    echo 'Checking mercurial log for matches ...'
    echo
    result=$(hg log -R "$HW_HG" -u "$author" -d "$date" -v -l1)
    if [ -z "$result" ]; then
        echo 'No match :('
        shift
        continue
    fi
    rev=$(echo "$result" | sed 's/^.*://;q')
    echo 'Found match: r'"$rev"
    echo 'Link:        http://hg.hedgewars.org/hedgewars/rev/'"$rev"
    echo
    echo "$result"
    # proceed to next parameter
    shift
done

echo

