#!/bin/bash

# change this to match your usbserial-device
PORT="/dev/cu.usbserial-DN009N24"

BASEDIR="$(dirname `readlink -f $0`)"
UPLOADER="${BASEDIR}/tools/nodemcu-uploader/nodemcu-uploader.py"

${UPLOADER} --port ${PORT} node restart
${UPLOADER} --port ${PORT} file do boot.lc
