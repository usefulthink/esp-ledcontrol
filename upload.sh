#!/bin/bash

# change this to match your usbserial-device
PORT="/dev/cu.usbserial-DN009N24"

BASEDIR="$(dirname `readlink -f $0`)"
UPLOADER="${BASEDIR}/tools/nodemcu-uploader/nodemcu-uploader.py"

DEVMODE=no
COMPILE=yes

while [ $# -gt 0 ] ; do
  case $1 in
    --dev|d) DEVMODE=yes ; shift ;;
    --no-compile|-C) COMPILE=no ; shift ;;
    --) shift ; files="$files $@" ; break ;;
    -*) echo "invalid argument: $1" ; shift ;;
    *) files="$files $1" ; shift ;;
  esac
done

files=${files:-src/*lua}

uploadList=""
for f in ${files} ; do
  dest=`basename "${f}"`

  # in devmode, don't transfer init.lua directly, but rename to _init.lua
  if [ ${DEVMODE} == yes ] && [ "${f/init.lua/}" != "${f}" ] ; then
    uploadList="${uploadList} ${f}:_${dest}"
  else
    uploadList="${uploadList} ${f}:${dest}"
  fi
done

# remove file init.lua so we won't run into boot-loops that would require us to
# re-flash the whole device
if [ ${DEVMODE} == yes ] ; then
  cmd="file.remove(\"init.lua\")"
  ${UPLOADER} --port ${PORT} exec <(echo "$cmd")
fi

if [ $COMPILE == yes ] ; then
    ${UPLOADER} --port ${PORT} upload --compile --restart ${uploadList}
else
    ${UPLOADER} --port ${PORT} upload --restart ${uploadList}
fi
