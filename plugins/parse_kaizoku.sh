#!/bin/sh

# set internal variables
EXT=$(echo $0|sed -e 's/^.*parse_//'|sed -e 's/\.sh$//')
TMPHTML="${1}.${EXT}"
TMPTRC="${1}.xml"
GREPURL="${2}"

# get parameters
sed -e 's/td>/td>!/g' $TMPHTML |\
  tr "!" "\n" |\
  grep "/tracker/torrents" |\
  sed -e 's/^.*href="//' -e 's/.torrent">.*$/.torrent/' |\
  grep -v "\[BATCH\]"|\
  sed -e 's/ /%20/g'

# remove rubbish
rm -f $TMPHTML
