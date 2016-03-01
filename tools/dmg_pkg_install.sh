#!/bin/bash

# Downloads and install a .dmg from a URL
#
# Usage
# $ dmg_pkg_install [url]
#
# Adopted from https://gist.github.com/afgomez/4172338


if [[ $# -lt 1 ]]; then
  echo "Usage: dmg_pkg_install [url]"
  exit 1
fi

url=$*

# Generate a random file name
tmp_file=/tmp/`openssl rand -base64 10 | tr -dc '[:alnum:]'`.dmg

# Download file
echo "Downloading $url..."
curl -# -L -o $tmp_file $url

echo "Mounting image..."
volume=`hdiutil mount $tmp_file | tail -n1 | perl -nle '/(\/Volumes\/[^ ]+)/; print $1'`

# Locate .pkg
app_pkg=`find $volume/. -name *.pkg -maxdepth 1 -print0`
echo "Install pkg..."
installer -pkg $app_pkg -target /

# Unmount volume, delete temporal file
echo "Cleaning up..."
hdiutil unmount $volume -quiet
rm $tmp_file

echo "Done!"
exit 0