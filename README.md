#NightLight#

This software runs on a wifipixel or a nodemcu with a neopixel ring. It provides 3 modes for a set of neopixels used to:

* Simulate twinkling stars
* Simulate a sunrise
* Turn off the pixels

##Requirements##
* [mqtt](http://mqtt.org/) server e.g. [mosquitto](http://mosquitto.org/)
* either a wifipixel or a [nodemcu](http://nodemcu.com/index_en.html) and a [neopixel](https://www.adafruit.com/category/168)

##Usage##
There are 2 parts to getting the system running. Setting the hardware up and setting up the software.
###Hardware###
Skip this section if you have a wifipixel.
Provide 5v power to the neopixel and connect to a pin on the nodemcu.
I suggest using pin 2 (the default settings). If pin 3 is used the onboard LED will not be turned off during operation.

To change the pin change the line

	led_pin=2

###Software###
The software is split into 2 parts. getting the firmware onto the device and loading the code including user settings.

####Firmware####
Before loading the lua code below the firmware must be flashed to the device.
The firmware will only need to be flashed once.

Flash the firmware from the firmware folder.
 
	python esptool.py  --port $nodeport  write_flash 0x000000  firmware/nodemcu-master-10-modules-2016-03-26-21-20-44-float.bin 

This was generated from 
[http://nodemcu-build.com/]http://nodemcu-build.com/ with the options:

* enduser_setup
* file 
* gpio 
* mqtt 
* net 
* node 
* tmr 
* uart
* wifi
* ws2812

####Lua Setup####
Before uploading the code to your device it is nescassery to  edit the settings.lua file with the details for your wifi and mqtt server setup:
these are changed in the **settings.lua** file.

To Set the ESSID change the line:

	ap="$SSID"

To set the password:

	ap_pass="$WIFI_PASSWORD"

Set the mqtt server

	mqtt_server="$MQTT"
	
With a nodemvu V0.9 the onboard LED will flash once a second until a connection to the mqtt has been made successfully.
####Upload the code###
Upload each file  using [nodemcu-tool](https://github.com/AndiDittrich/NodeMCU-Tool)

	nodemcu-tool upload run.lua
	nodemcu-tool upload settings.lua
**Note make sure that compile is turned off before uploading init.lua**

	nodemcu-tool upload init.lua 
	
	



###MQTT###
The device should now boot and connect to the MQTT server. You will know this is successful when the on board LED goes blank. Boot time takes a while as there is the option to skip the automatic boot from a terminal.
To set the mode post an integer to the topic.
mode is set via a post /led with a numeric mode

* 0 Turn all pixels off
* 1 Sunrise mode starts. Starts off black and gradually ramps up to full power yellow
* 2 Twinkle mode.

A [node-red](http://nodered.org/) example flow is shown in the node-red folder.
