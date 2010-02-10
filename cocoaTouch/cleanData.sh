#!/bin/bash

svn export --force share/hedgewars/Data ../iphone-hwengine/Data
rm -rf ../iphone-hwengine/Data/Sounds/*
rm -rf ../iphone-hwengine/Data/Music/*
rm -rf ../iphone-hwengine/Data/Locale/hedgewars_*
