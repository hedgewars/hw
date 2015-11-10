#!/bin/sh


if [ -d QTfrontend ]; then
	cd QTfrontend
else
	if [ -d ../QTfrontend ]; then
		cd ../QTfrontend
	else
		echo 'abort: Directory "QTfrontend" not found!' >&2
		exit 1
	fi
fi

if [ -z "$1" ]; then
	OUTPUT_DIRECTORY="../doc/QTfrontend"
else
	OUTPUT_DIRECTORY="$1"
fi

echo "Creating documentation for Qt-Frontend in $OUTPUT_DIRECTORY ..."

if [ $(which hg) ]; then

branch=$(hg identify -b)
rev=$(hg identify -rdefault -i)

#branchurl="<a href=http://code.google.com/p/hedgewars/source/list?name=${branch}>${branch}</a>"
#revurl="<a href=http://code.google.com/p/hedgewars/source/detail?r=${rev}>${rev}</a>"

branchurl="$branch"
revurl="$rev"

export PROJECT_NUMBER="${branchurl} branch, ${revurl}"
export OUTPUT_DIRECTORY

fi

doxygen
exit $?
