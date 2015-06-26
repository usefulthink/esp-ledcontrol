#!/bin/bash

PORT="/dev/cu.usbserial-DN009N24"

tools/nodemcu-uploader.py --port ${PORT} node restart
tools/nodemcu-uploader.py --port ${PORT} file do boot.lc
