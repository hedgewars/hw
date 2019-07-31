#!/bin/sh -
# Script to update all frontend locale files.

# HOW TO USE:
# - Run this script in the tools/ directory.
# Result: All .ts files in share/hedgewars/Data/Locale will be updated.

lupdate ../QTfrontend -ts ../share/hedgewars/Data/Locale/hedgewars_*.ts
