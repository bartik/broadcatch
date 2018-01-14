#!/bin/sh
# load parameters from the conf file
# $1 - original configuration file with full path preferably
# $2 - temporary file for variables
# $3 - names of variables to read from config file
loadConfigFile()
{
  grep '^\$' "$1" | sed -e 's/^.//' > "$2"
  while read CONFIGLINE
  do
    for VAR in $3
    do
        GREPVAR=`echo "${CONFIGLINE}" | grep "$VAR=" | awk -F'=' '{ print $2 }'`
        if [ "$GREPVAR" != "" ]
        then
            eval "$VAR=\"$GREPVAR\""
        fi
    done
  done < "$2"
}

# replace restricted chars with matachars
xmlify()
{
  if [ -f "${1}" ]
  then
    sed -e 's/\&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g' "${1}"
  else
    echo "${1}" | sed -e 's/\&/\&amp;/g' \
      -e 's/</\&lt;/g' \
      -e 's/>/\&gt;/g' \
      -e 's/"/\&quot;/g'
  fi
}     

# print text to file
printXmlText()
{
  echo "$1" >> "$2"
}

# will print single XML trace entry to the trace file
# $1 - the text to print as a content of the XML ENTRY tag
printXmlSingleTraceEntry()
{
  SAFETXT=`xmlify "${1}"`
  printXmlText "  <ENTRY TYPE=\"TRACE\" FROM=\"$MYNAME\">${SAFETXT}</ENTRY>" "${TMPTRC}"
}

# will print single XML log entry to the log file
# $1 - the text to print as a content of the XML ENTRY tag
# $2 - the type of the log entry FAILURE/SUCCESS
printXmlSingleLogEntry()
{
  SAFETXT=`xmlify "${1}"`
  printXmlText "  <ENTRY TYPE=\"$2\" FROM=\"$MYNAME\">${SAFETXT}</ENTRY>" "${TMPXML}"
}

# Will print text to trace file
# $1 - text to print
printXmlTraceText()
{
  printXmlText "$1" "${TMPTRC}"
}

# Will print text to log file
# $1 - text to prin
printXmlLogText()
{
  printXmlText "$1" "${TMPXML}"
}

# this function will add the log/trace to the web log
# $1 - log file where the xml output should be appended
# $2 - temporary file which holds the new log entries to be added
# $3 - temporarry file to store the original log
addToWebLog()
{
  # remove the closing tag 
  sed -e '/^\s*$/d' -e '$,$d' "$1" > "$3"
  CLOSINGTAG=`sed -n '$p' "$1"`
  # equivalent to above CLOSINGTAG=`sed -e '$!d' "$1"`
  # equivalent to above CLOSINGTAG=`tail -1 "$1"`
  # add the newest log/trace results to the web log
  cat "$2" >> "$3"
  echo "${CLOSINGTAG}" >> "$3"
  mv "$3" "$1"
}

# will print an empty web log file
# $1 - the root tag
# $2 - log file
# $3 - xsl stylesheet (optional)
emptyWebLog()
{
  XSLSHEET="${3}"
  ROOTAG=`echo "${1}" | tr '[a-z]' '[A-Z]'`
  echo '<?xml version="1.0" encoding="UTF-8"?>' > "${2}"
  if [ -n "${XSLSHEET}" ]
  then
    echo "<?xml-stylesheet type=\"text/xsl\" href=\"${XSLSHEET}.xsl\"?>" > "${2}"
  fi
  echo "<${ROOTAG}>" >> "$2"
  echo "</${ROOTAG}>" >> "$2"
}

# the function will sort and uniq the given file
# $1 - file to process
# $2 - temporary file
sortAndUniqFile()
{
  sort "$1" | uniq > "$2"
  rm -f "$1"
  mv "$2" "$1"
}

# will try to download a file from web
# $1 - torrent file URL to download
# $2 - where to save the torrent file
# $3 - timeout value for http connection
# $4 - number of retries
# $5 - what to use wget/curl curl is default 
# $6 - file for cookies
# retrun value
# the exit status of the curl/wget respectively
getFileFromWeb()
{
  # if webtool specified use that, fallback option is curl
  case "$5" in
    wget)
      # -q quiet
      # -O <filename>
      # -T connect-timeout
      # -t retry
      wget -q "$1" -O "$2" -T "$3" -t "$4" --save-cookies "$6" --load-cookies "$6"
      ;;
    *)
      # -q ignore .curlrc
      # -s silence (quiet)
      # -g no globbing (don't treat {} and [] specially)
      # -o <filename> write output to <filename>
      # -b load cookies from this file
      # -c cookie jar save cookies after session here
      curl -q -s -g -o "$2" -c "$6" -b "$6" --retry "$4" --connect-timeout "$3" "$1"
      ;;
  esac
  return $?
}
