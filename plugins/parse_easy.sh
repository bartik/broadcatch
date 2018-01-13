#!/bin/sh
# $1 - temporary path + file name withoud extension
# $2 - pattern to grep for
# $3 - start tag (spaces are encoded with %20)
# $4 - end tag (spaces are encoded with %20)

# set internal variables
PATH="/opt/bin"
EXT=$(echo $0|sed -e 's/^.*parse_//' -e 's/\.sh$//')
TMPFILE="${1}.${EXT}"
TMPEXT="${1}.extract"
TMPTRC="${1}.xml"
GREPURL="${2}"
TAGSTART=$(echo $3|sed -e 's/%20/ /g')
TAGEND=$(echo $4|sed -e 's/%20/ /g')

. ./common/common.sh

# extract the data
cat "${TMPFILE}" | tr -d '\n' | sed -e 's/>\s*</></g' -e 's/@/\&#64;/g' -e "s/${TAGSTART}/@/g" | tr '@' '\n' | sed -e '1,1d' -e "s/${TAGEND}.*$//" -e 's/\&#64;/@/g' > "$TMPEXT"
printXmlTraceText "  <ENTRY TYPE=\"TRACE\" FROM=\"$0\">Extracted links from feed"
xmlify "$TMPEXT" >> "${TMPTRC}"
printXmlTraceText "  </ENTRY>"
# finally get what you want
if [ -n "$GREPURL" ]; then
  grep -i "$GREPURL" "$TMPEXT" | sort | uniq | sed -e 's|http://www.mininova.org/tor/|http://www.mininova.org/get/|' -e 's|^//|http://|'
else
  sort "$TMPEXT" | uniq | sed -e 's|http://www.mininova.org/tor/|http://www.mininova.org/get/|' -e 's|^//|http://|'
fi

# remove rubbish
rm -f "$TMPEXT" "$TMPFILE"
