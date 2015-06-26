# esp8266 openpixelcontrol-server for ws2812 LEDs

An [openpixelcontrol][]-server written in LUA to be used with the ws2812-library that ships with the [nodeMCU][] firmware.

[openpixelcontrol]: http://openpixelcontrol.org/
[nodeMCU]: http://www.nodemcu.com/index_en.html

## usage

Flash the nodeMCU-firmware and upload the files from the `src/`-directory to the ESP8266 (see below). You need to create an additional file named `src/config.lua` with the WiFi-credentials and other configuration (see `src/config-example.lua` for a template). After booting, the ESP will connect to the network (IP-address and status is reported via UART)


## flashing the firmware

> You need to install the `python-serial` module for esptool to work 
> correctly. See 
> [the projects README-file](https://github.com/themadinventor/esptool) 
> for more information.

This module comes with a prebuilt firmware that contains all required modules. To flash it, edit the `./flash.sh` file to contain the correct path to the programmer and run it.
