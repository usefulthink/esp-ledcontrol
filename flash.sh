#!/bin/bash
# change this to match your usbserial-device
PORT="/dev/cu.usbserial-DN009N24"

# change to `nodemcu-custom-float.bin` if you need floating-point support
IMAGE="nodemcu-custom-integer.bin"

BASEDIR="$(dirname `readlink -f $0`)"
IMAGE_FILE="${BASEDIR}/firmware/${IMAGE}"
ESPTOOL="${BASEDIR}/tools/esptool/esptool.py"

${ESPTOOL} -p ${PORT} write_flash 0x00000 "${IMAGE_FILE}"
