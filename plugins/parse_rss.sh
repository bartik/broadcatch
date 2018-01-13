#!/bin/sh
# $1 - temporary path + file name withoud extension
# $2 - pattern to grep for

# set internal variables
PATH="/opt/bin"
EXT=$(echo $0|sed -e 's/^.*parse_//'|sed -e 's/\.sh$//')
TMPRSS="${1}.${EXT}"
TMPEXT="${1}.extract"
TMPLINK="${1}.link"
TMPENCL="${1}.enclosure"
TMPSANE="${1}.sane"
TMPTRC="${1}.xml"
GREPURL="${2}"

. ./common/common.sh

# make rss feed sed/awk/grep friendly
sed -e 's/></>|</g' "$TMPRSS" | tr '|' '\n' | sed -e '1,/<item>/d' > "$TMPSANE"
# extract the link
grep "<link>" "$TMPSANE" | sed -e 's/^\s*<link>//' | sed -e 's/<\/link>\s*$//' > "$TMPLINK"
printXmlTraceText "  <ENTRY TYPE=\"TRACE\" FROM=\"$0\">Extracted links from feed"
xmlify "$TMPLINK" >> "${TMPTRC}"
printXmlTraceText "  </ENTRY>"
# enclosure is even easier to extract
grep '<enclosure' "$TMPSANE" | sed -e 's/^.*url="//' -e 's/".*$//' >> "$TMPENCL"
printXmlTraceText "  <ENTRY TYPE=\"TRACE\" FROM=\"$0\">Extracted url attribute from enclosure tag in feed"
xmlify "$TMPENCL" >> "${TMPTRC}"
printXmlTraceText "  </ENTRY>"
cat "${TMPLINK}" > "${TMPEXT}"
cat "${TMPENCL}" >> "${TMPEXT}"
# finally if a mixed rss get what you want
if [ -n "$GREPURL" ]; then
  grep -i "$GREPURL" "$TMPEXT" | sort | uniq
else
  sort "$TMPEXT" | uniq
fi

# remove rubbish
rm -f "$TMPSANE" "$TMPLINK" "$TMPENCL" "$TMPEXT" "$TMPRSS"
