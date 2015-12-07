#!/bin/bash
#
# This script will install the Xedrak keyboard layout into the XOrg
# base xkb list, causing it to show up in the layout lists in all of 
# the major desktop environments, such as Gnome/KDE.  Running it multiple
# times is harmless.
#
# Tested Linux Distributions:
#    Arch Linux
#
#
# TODO:  Auto detect where XKB_PATH is, rather than assume its location
#
#
# Author: Shawn Badger
# Date:   12/30/2014
#

LAYOUT_NAME=xedrak
LAYOUT_DISPLAY_NAME=Xedrak

XKB_LAYOUT_FILE=$LAYOUT_NAME
XKB_PATH=/usr/share/X11/xkb
RULES_PATH=$XKB_PATH/rules
SYMBOLS_PATH=$XKB_PATH/symbols
XKB_CACHE_PATH=/var/lib/xkb

LST_FILE=$RULES_PATH/evdev.lst
XML_FILE=$RULES_PATH/evdev.xml
XSL_FILE=$LAYOUT_NAME.xsl

TMP_FILE=./__layout_install.tmp

if [[ $(id -u) -ne 0 ]]; then
  echo "This script requires root privileges";
  exit 1;
fi

if [ ! -e "$XML_FILE" ]; then
  echo "It appears as though XKB files are not in $XKB_PATH" 
  echo "If your distribution stores them elsewhere, you can modify this script"
  echo "by changing the XKB_PATH field to point to the correct directory."
  echo "Some distributions use /etc/X11/xkb"
  exit 1;
fi

#echo " * Copying $LST_FILE file to $TMP_FILE"
cp $LST_FILE $TMP_FILE
if [ $? -ne 0 ]; then
  echo "   *** Failed to copy $LST_FILE to $TMP_FILE"
  exit 1
fi

echo " * Removing existing $LAYOUT_DISPLAY_NAME entries in $LST_FILE"
awk "!/${LAYOUT_DISPLAY_NAME}/" $TMP_FILE > $LST_FILE
if [ $? -ne 0 ]; then
  echo "   *** Failed to remove $LAYOUT_DISPLAY_NAME entries from $LST_FILE file"
  exit 1
fi

#echo " * Copying $LST_FILE file to $TMP_FILE"
cp $LST_FILE $TMP_FILE
if [ $? -ne 0 ]; then
  echo "   *** Failed to copy $LST_FILE to $TMP_FILE"
  exit 1
fi

echo " * Adding $LAYOUT_DISPLAY_NAME entry to $LST_FILE"
awk "/Colemak/ && !x {print \"  $LAYOUT_NAME         us: English ($LAYOUT_DISPLAY_NAME)\"; x=1} 1" $TMP_FILE > $LST_FILE 
if [ $? -ne 0 ]; then
  echo "   *** Failed to add $LAYOUT_DISPLAY_NAME entry to $LST_FILE file"
  exit 1
fi

#echo " * Copying $XML_FILE file to $TMP_FILE"
cp $XML_FILE $TMP_FILE
if [ $? -ne 0 ]; then
  echo "   *** Failed to copy $XML_FILE to $TMP_FILE"
  exit 1
fi

echo " * Adding $LAYOUT_DISPLAY_NAME section to $XML_FILE file, if not already present"
xsltproc $XSL_FILE $TMP_FILE 1> $XML_FILE 2> /dev/null
if [ $? -ne 0 ]; then
  echo "   *** Failed to add $LAYOUT_DISPLAY_NAME section to $XML_FILE file"
  exit 1
fi

grep -i "$LAYOUT_NAME" $SYMBOLS_PATH/us > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo " * Adding $LAYOUT_DISPLAY_NAME symbols to $SYMBOLS_PATH/us" 
  echo "" >> $SYMBOLS_PATH/us
  cat $LAYOUT_NAME >> $SYMBOLS_PATH/us
  if [ $? -ne 0 ]; then
    echo "   *** Failed to add $LAYOUT_DISPLAY_NAME symbols to $SYMBOLS_PATH/us"
    exit 1
  fi
fi

echo " * Removing xkb cache files"
rm -f $XKB_CACHE_PATH/*.xkm

rm -f $TMP_FILE


echo " --- $LAYOUT_DISPLAY_NAME layout should now be installed and ready to use --- "

