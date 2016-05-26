require('settings')
require('parse')
wifi.setmode(wifi.STATION)
wifi.sta.config(ap, ap_pass)

m = mqtt.Client(mqtt_client_id, mqtt_timeout, mqtt_user_name, mqtt_password)
local mode = 0
local red = 0
local blue = 0
local green = 0
count = 0
redDial = 0
blueDial = 0
greenDial = 0
blueBackground = 5
background =  string.char(0,0,0)
led = background:rep(led_count)


count = 0

blueTarget = string.char(blueBackground):rep(led_count)

local pin = 4            --> GPIO2
local value = gpio.LOW

gpio.mode(pin, gpio.OUTPUT)
gpio.write(pin, value)



m:on("connect", function(con)
        print ("made connection")
        value = gpio.HIGH
        gpio.write(pin, value)
        tmr.stop(1)
end)
m:on("offline", function(con)
           print ("offline")
           tmr.start(1)
end)

function toggleLED ()
   --blink the on board led
    if value == gpio.LOW then
        value = gpio.HIGH
    else
        value = gpio.LOW
    end

    gpio.write(pin, value)
end

m:on("message", function(conn, topic, data)
        print(topic .. ":" .. data)

        local command = getTable(data)

        if(command[1] == "dial") then
           tmr.stop(0)
           tmr.stop(3)
           redDial =  tonumber(command[2])
           blueDial = tonumber(command[4])
           greenDial = tonumber(command[3])

           led = background:rep(led_count)
           ws2812.writergb(led_pin, led)
           tmr.start(3)
           countTarget = a
           count = 0
        elseif command[1] == "mode" then
           tmr.stop(0)
           tmr.stop(3)
            mode = tonumber(command[2])
            led = background:rep(led_count)
            ws2812.writergb(led_pin, led)
            tmr.start(0)

        elseif command[1] == "background" then
            mode = tonumber(command[1])
            background =  string.char(tonumber(command[2]),tonumber(command[3]),tonumber(command[4]))
        end

end)

tmr.alarm(1,1000,1, function()

             if wifi.sta.status() == 5 then
                toggleLED()
                print("lets try and connect")
                tmr.stop(1)
                m:connect(mqtt_server, mqtt_port, 0, function(conn)
                             print("connected to mqtt")

                             m:subscribe("led",0, function(conn)
                                            print("subscribed")
                                            led = string.char(0,0,0):rep(16)
                                            value = gpio.HIGH
                                            gpio.write(pin, value)
                             end)
                end)
end end)

tmr.alarm(2,500, 1, function()
             toggleLED()
             if wifi.sta.getip()==nil then
                print(" Wait to get IP address!")
                tmr.stop(0)
                tmr.stop(1)
                tmr.stop(3)
             else
                print("New IP address is "..wifi.sta.getip())
                print("lets connect")
                tmr.start(1)
                tmr.stop(2)
end end)

function getColourVal(count,dialVal)

   if (count * 256 < dialVal) then
      return 255
   elseif ((count - 1) * 256 < dialVal ) then
      return dialVal % 256
   else
      return 0
   end
end

tmr.alarm(3, 50, 1, function()
             tmr.stop(3)
             local lred=0
             local lblue=0
             local lgreen=0
             local newled = ""
             for i = 1 , (count) do

                lred=getColourVal(i,redDial)
                lblue=getColourVal(i,blueDial)
                lgreen=getColourVal(i,greenDial)

                if lred == 0 and lblue == 0 and lgreen == 0 then
                   newled = newled..background
                else
                   --print ("set pixel ".. i .. " to " ..
                   --          lred .. "," ..
                   --          lgreen .. "," ..
                   --          lblue )
                   newled = newled .. string.char(lred, lgreen, lblue)
                end
             end
             newled = newled .. background:rep(led_count-count)
             count = count + 1
             led = newled
             ws2812.writergb(led_pin, led)

             if (count<= led_count) then
                tmr.start(3)
             end

end )


tmr.alarm(0, 20, 1, function()

             tmr.stop(0)
             if(mode == 0) then
                red  = 0
                green = 0
                blue = 0
             end
             if(mode == 1) then
                --yellow mode
                red = redVal(led,1) + 1
                if red >= 200 then
                   red = 200
                end
                green = red / 2
                led = string.char(red,green,0):rep(16)
             end
             if(mode == 2) then
                --sparkles
                newled=""
                for i=1,(led:len()/3) do
                   blue = blueVal(led,i)
                   blueValTarget = blueTarget:byte(i)
                   --print("led " .. tostring(i) .. " val: " .. tostring(blue) .. " target " .. tostring(blueValTarget))
                   if blue ~= blueValTarget then
                      if (blue  < blueValTarget and (blueBackground ~= blueValTarget)) then
                         blue = blue + 2;
                      else
                         --print("down")
                         blue = blue - 4;
                      end
                   end
                   if blueValTarget <= blue then
                      blueTarget =  setBlueTarget(i,blueBackground);
                   end

                   if(blue <0 ) then
                      blue = blueBackground
                   end

                   newled = newled .. string.char(0, 0, blue)

                   if(blue < min_intensity) then
                      if(math.random(200) < 5) then
                         new =math.random(min_intensity,max_intensity)

                         blueTarget =  setBlueTarget(i,new)
                      end
                   end
                end
                led = newled
                --led = string.char(red, green, blue):rep(count)
             end
             if(mode == 3) then
                red = red + 1
                led = string.char(red, green, blue):rep(16)
             end
             ws2812.writergb(led_pin, led)
             count = count % led_count
             count = count + 1
             tmr.start(0)

end )

function redVal(led, position)
   return colourVal(led , position, 1)
end

function greenVal(led, position)
   return colourVal(led , position, 2)

end

function blueVal(led, position)
   return colourVal(led , position, 3)
end

function colourVal(led,position,offset)
   return led:byte(3*(position-1) + offset)
end
function setBlueTarget(position,target)
   if (position == 1) then
      start = ""
   else
      start = blueTarget:sub(1,position-1)
   end
   if(position == led:len()) then
      last = ""
   else
      last = blueTarget:sub(position+1)
   end
   answer = start .. string.char(target)

   answer = answer .. last
   --print("target: "..position)
   --print("answer: " .. answer:len())
   --print("start: " .. start:len())
   --print("last: " .. last:len())
   return answer
end
function setLed (led , position ,  newValue)
   if position+1*3 >led:len() then
      return led
   end
   start = led:sub(1,(position -1) * 3)

   last = led:sub((position + 1) * 3 -2)

   answer = start..newValue
   answer = answer..last

   return answer
end
