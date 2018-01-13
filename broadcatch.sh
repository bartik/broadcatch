#!/bin/sh

#
# As function name use a string of concatenated words. The first word starts with a
# lower case character every other word in the name starts with a capital
#
# exit codes
# 0 - everything ok
# 1 - interuppted
# 2 - already running
# 3 - configuration file doesn't exist or not readable
#
# the ${TMPTMP} variable is never used to hold permanent information !
#

# removes the temporary file
# no parameters
removeTmpFiles()
{
  # this must be cleaned up explicitly
  rm -f "${TMPMAIL}"
  rm -f "${TMPVAR}"
  rm -f "${PID}"
  # this deletions can be expressed implicitly
  rm -f ${TMPDIR}/${MYNAME}_${MYPID}*
}

# when the script is interrupted log it and do clean up
# no params
cleanUp()
{
  printXmlSingleLogEntry "Interrupted!" "${FAILED}"
  printXmlLogText "</RUN>"
  removeTmpFiles
  echo "Interrupted!" >&2
  exit 1
}

# set temporary variables given as lis
# $1 - list of variables to create
setTmpVariables()
{
  for VAR in $1
  do
    EXT=`echo "$VAR" | tr '[A-Z]' '[a-z]'`
    eval "TMP${VAR}=\"${TMPDIR}/${MYNAME}_${MYPID}.${EXT}\""
  done
}

# main starts here
PATH="/opt/bin"

# get absolute path to scrip
WORKDIR=`echo "$0" | sed -e 's/\/[^\/]*$//'`
WORKDIR=`cd "${WORKDIR}" 2>/dev/null && pwd || echo "${WORKDIR}"`
cd "${WORKDIR}"

. "${WORKDIR}/common/common.sh"

# derive name
MYNAME=`echo "$0" | awk -F'/' '{ print $NF }' | sed -e 's/\.[a-z]*$//'`

# get PID number
MYPID=$$

# set hardcoded filenames/values
CFG="${WORKDIR}/${MYNAME}.conf"
PID="/var/run/${MYNAME}.pid"
FAILED="FAILED"
SUCCESS="SUCCESS"
NOW=`date`

# check if configuration is presen
if [ ! -r "$CFG" ]
then
  echo "The configuration file $CFG not found or not readable!" >&2
  exit 3
fi

# check if already running (pid file used as lock file too)
if [ -f "${PID}" ]
then
  echo "Already running!" >&2
  exit 2
fi
echo "${MYPID}" > "${PID}"

# if interupted do cleanup
trap cleanUp 1 2 3 15

# set "not so much hardcoded" filenames
if [ -z "$TMP" ]
then
  TMPDIR="/tmp"
else
  TMPDIR="${TMP}"
fi
TMPVAR="${TMPDIR}/${MYNAME}_${MYPID}.var"

# set default files/values which can be changed by conf file
OLD="${WORKDIR}/${MYNAME}.old"
LOG="/volume1/public/debian/chroottarget/var/www/${MYNAME}.xml"
TMPMAIL="/volume1/public/debian/chroottarget/tmp/${MYNAME}.txt"
COOKIES="${WORKDIR}/${MYNAME}.cos"
TORRENTDIR="/volume1/public/debian/chroottarget/root/.mldonkey/torrents/incoming"
TORRENTTIMEOUT=120
TORRENTRETRY=6

# load parameters from the conf file
# OLD - text file which stores the list of already downloaded torrents
# LOG - file where the finished XML file will be stored with proper header and <BROADCATCH> tag
# TORRENTDIR - directory where to move the torrent files
# TMPDIR - directory to store temporary files (exception is the *.var file)
# TRACE - if set to on traces will be written otherwise no traces will be written to LOG file
# TORRENTTIMEOUT - how muc time to wait till the downloading of torrent file will timeou
# TORRENTRETRY - how many retries to do before giving up on the torrent file
# WEBTOOL - set to wget if you want to use the wget otherwise curl will be used
# DIFFORMAT - context/normal/unified C/N/U
loadConfigFile "${CFG}" "${TMPVAR}" "COOKIES OLD LOG TORRENTDIR TMPDIR TRACE TORRENTTIMEOUT TORRENTRETRY WEBTOOL DIFFORMAT"

# set names of temporary files
# variables created are: $TMPCFG, ${TMPTMP}, ${TMPNEW} etc. (see list below)
setTmpVariables "CFG TMP NEW DOW XML DIF"

# where to write traces (this should be equal either to ${TMPXML} or /dev/null)
# we don't write traces to a separate file, that's why the TRC doesn't go into
# the previous setTmpVariables parameter list.
case "${TRACE}" in
  [oO][nN])
    TMPTRC="${TMPXML}"
    ;;
  *)
    TMPTRC="/dev/null"
    ;;
esac

# start trace
printXmlLogText "<RUN AT=\"${NOW}\" PID=\"${MYPID}\" NAME=\"${MYNAME}\">"

# print parameters to trace
printXmlSingleTraceEntry "CFG=${CFG}"
printXmlSingleTraceEntry "OLD=${OLD}"
printXmlSingleTraceEntry "LOG=${LOG}"
printXmlSingleTraceEntry "COOKIES=${COOKIES}"
printXmlSingleTraceEntry "TMPDIR=${TMPDIR}"
printXmlSingleTraceEntry "TMPCFG=${TMPCFG}"
printXmlSingleTraceEntry "TMPTMP=${TMPTMP}"
printXmlSingleTraceEntry "TMPNEW=${TMPNEW}"
printXmlSingleTraceEntry "TMPDOW=${TMPDOW}"
printXmlSingleTraceEntry "TMPXML=${TMPXML}"
printXmlSingleTraceEntry "TMPMAIL=${TMPMAIL}"
printXmlSingleTraceEntry "TMPTRC=${TMPTRC}"
printXmlSingleTraceEntry "TORRENTDIR=${TORRENTDIR}"
printXmlSingleTraceEntry "Start $0 at ${NOW}"

# working in the directory
printXmlSingleTraceEntry "Working directory `pwd`"

# get the list of rss feeds
grep -v "^#" "$CFG" |
  grep -v "^$" |
  grep -v '^\$' > "$TMPCFG"

printXmlTraceText "  <ENTRY TYPE=\"TRACE\" FROM=\"$MYNAME\">Preprocessed configuration ${CFG}"
xmlify "$TMPCFG" >> "${TMPTRC}"
printXmlTraceText "  </ENTRY>"

# get rss feeds
printXmlSingleTraceEntry "Remove temporary file ${TMPNEW}"
rm -f "${TMPNEW}"
touch "${TMPNEW}"
printXmlSingleTraceEntry "Reading configuration ${TMPCFG}"
while read COMMANDLINE
do
  printXmlSingleTraceEntry "Commandline: ${COMMANDLINE}"
  # parse command line
  PARSETYPE=`echo ${COMMANDLINE}| awk -F'|' '{print $1}'`
  PARSEURL=`echo ${COMMANDLINE}| awk -F'|' '{print $2}'`
  PARSEPATTERN=`echo ${COMMANDLINE}| awk -F'|' '{print $3}'`
  P3=`echo ${COMMANDLINE}| awk -F'|' '{print $4}'`
  P4=`echo ${COMMANDLINE}| awk -F'|' '{print $5}'`
  if getFileFromWeb "${PARSEURL}" "${TMPDIR}/${MYNAME}_${MYPID}.${PARSETYPE}" ${TORRENTTIMEOUT} ${TORRENTRETRY} ${WEBTOOL} ${COOKIES}
  then
    # call plugin
    "${WORKDIR}/plugins/parse_${PARSETYPE}.sh" "${TMPDIR}/${MYNAME}_${MYPID}" "${PARSEPATTERN}" "$P3" "$P4" >> "${TMPNEW}"
    printXmlTraceText "  <ENTRY TYPE=\"TRACE\" FROM=\"$MYNAME\">Result from parse_${PARSETYPE}.sh"
    xmlify "${TMPNEW}" >> "${TMPTRC}"
    printXmlTraceText "  </ENTRY>"
  else
    printXmlSingleLogEntry "Failed downloading ${PARSEURL}" "${FAILED}"
  fi
done < "$TMPCFG"

# find out what to download
sortAndUniqFile "${TMPNEW}" "${TMPTMP}"
diff "${OLD}" "${TMPNEW}" > "${TMPDIF}"
case "${DIFFORMAT}" in
  [uU])
    # sort and uniq the torrents found, uses the unified output forma
    sortAndUniqFile "${TMPDIF}" "${TMPTMP}"
    grep '^+' "${TMPDIF}" | grep -v '^+++' | sed -e 's/^\+//' > "${TMPDOW}"
    ;;
  *)
    # use this when the diff supports standard output
    grep '^>' "${TMPDIF}" | sed -e 's/^> //' > "${TMPDOW}"
    ;;
esac

printXmlTraceText "  <ENTRY TYPE=\"TRACE\" FROM=\"$MYNAME\">Files to download"
xmlify "${TMPDOW}" >> "${TMPTRC}"
printXmlTraceText "  </ENTRY>"

# prepare mail to send
echo "From: sender@example.com" > "$TMPMAIL"
echo "To: sender@example.com" >> "$TMPMAIL"
echo "Subject: broadcatch report" >> "$TMPMAIL"
echo "" >> "$TMPMAIL"
echo "These torrents will be downloaded:" >> "$TMPMAIL"

# send files to mldonkey
NEWITEMS=0
rm -f "${TMPTMP}"
touch "${TMPTMP}"
if [ `wc -l "${TMPDOW}" | awk '{print $1}'` -gt 0 ]
then
  COUNT=0
  while read TORRENT
  do
    COOKIESITE=`echo "${PARSEURL}" | awk -F'/' '{ print $1"//"$3"/"}`
    if [ `grep -c "${COOKIESITE}" "${TMPTMP}"` -eq 0 ]
    then
      # go to main site and get cookies
      printXmlSingleTraceEntry "Reading cookies from ${COOKIESITE}"
      getFileFromWeb "$COOKIESITE}" "/dev/null" ${TORRENTTIMEOUT} ${TORRENTRETRY} ${WEBTOOL} ${COOKIES}
      echo "${COOKIESITE}" >> "${TMPTMP}"
    fi
    STATUS="${FAILED}"
    if getFileFromWeb "${TORRENT}" "${TMPDIR}/${MYNAME}_${MYPID}_${COUNT}.torrent" ${TORRENTTIMEOUT} ${TORRENTRETRY} ${WEBTOOL} ${COOKIES}
    then
      mv "${TMPDIR}/${MYNAME}_${MYPID}_${COUNT}.torrent" "${TORRENTDIR}"
      STATUS="${SUCCESS}"
      NEWITEMS=1
      # add the torrent to the old ones
      echo "${TORRENT}" >> "${OLD}"
      echo "${TORRENT}" >> "${TMPMAIL}"
      # print additional information into the mail
      /volume1/public/debian/chroottarget/home/bdecode/a.out -o "${TORRENTDIR}/${MYNAME}_${MYPID}_${COUNT}.torrent" |\
      tr -d '\n' |\
      sed -e 's/>[ \t]*</></g' \
          -e 's/<PAIR><BYTESTRING length="6">pieces<\/BYTESTRING><BYTESTRING length="[0-9]*">[^>]*>//g' \
          -e 's|</PAIR>|@|g' \
          -e 's|</[A-Z]*>|:|g' \
          -e 's|<[^>]*>||g' \
          -e 's|:@|@|g' \
          -e 's/@*:$/@/g' \
          -e 's/&#32;/ /g' |\
      tr '@' '\n' >> "${TMPMAIL}"
    fi
    printXmlSingleLogEntry "${TORRENT}" "${STATUS}"
    COUNT=`expr $COUNT + 1`
  done < "${TMPDOW}"
else
  printXmlSingleLogEntry "No torrents to download !" "${SUCCESS}"
fi
printXmlSingleTraceEntry "End $0 at ${NOW}"
printXmlLogText "</RUN>"

# if new files then sort and uniq the old file list
if [ "${NEWITEMS}" -gt 0 ]
then
  # there are torrents to download try to start mlnet
  /opt/etc/init.d/S80mlnet start
  # try to send email notification
  echo "" >> "$TMPMAIL"
  #/opt/sbin/chroot /volume1/public/debian/chroottarget /bin/bash -c "/usr/local/sbin/ssmtp -t < /tmp/${MYNAME}.txt"
  /opt/sbin/chroot /volume1/public/debian/chroottarget /bin/bash -c "/usr/local/bin/msmtp -t < /tmp/${MYNAME}.txt"
  sortAndUniqFile "${OLD}" "${TMPTMP}"
fi

# print the XML file into the web directory
# if file doesn't exist or if it is empty
if [ ! -f "${LOG}" -a ! -s "${LOG}" ]
then
  # write a new empty log with XML header and root tag
  emptyWebLog "${MYNAME}" "${LOG}" "${MYNAME}"
fi

# add the log/trace to the web log file
if [ "${TMPXML}" != "/dev/null" ]
then
  addToWebLog "${LOG}" "${TMPXML}" "${TMPTMP}"
fi

# remove temporary files
removeTmpFiles
exit 0
