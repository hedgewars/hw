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

export PROJECT_NUMBER="${branch} branch, ${rev}"
export OUTPUT_DIRECTORY

fi

doxygen
exit $?
