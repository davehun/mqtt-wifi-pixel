require('settings')
wifi.setmode(wifi.STATION)
wifi.sta.config(ap, ap_pass)

m = mqtt.Client(mqtt_client_id, mqtt_timeout, mqtt_user_name, mqtt_password)
local mode = 0
local red = 0
local blue = 0
local green = 0
led = string.char(red, green, blue):rep(led_count)
background = 0

count = 0

blueTarget = string.char(background):rep(led_count)

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

        --if topic=='/led' then

        if data ~= nil then
           local a = tonumber(data)
           print("set mode : "..a)
           mode = a
           red  = 0
           green = 0
           blue = 0
           led = string.char(red, green, blue):rep(led_count)
        end
end)

tmr.alarm(1,1000,1, function()

             if wifi.sta.status() == 5 then
                toggleLED()
                print("lets try and connect")
                tmr.stop(1)
                m:connect(mqtt_server, mqtt_port, 0, function(conn)
                             print("connected to mqtt")
                             m:subscribe("/led",0, function(conn)
                                            print("subscribed")
                                            led = string.char(0,0,0):rep(16)
                                            tmr.start(0)
                                            value = gpio.HIGH
                                            gpio.write(pin, value)
                             end )
                             --m:subscribe("/dial",0, function(conn)
                             --               print("subscribed")
                            -- end)
                end)
end end)

tmr.alarm(2,500, 1, function()
             toggleLED()
             if wifi.sta.getip()==nil then
                print(" Wait to get IP address!")
                tmr.stop(0)
                tmr.stop(1)
             else
                print("New IP address is "..wifi.sta.getip())
                print("lets connect")
                tmr.start(1)
                tmr.stop(2)
end end)


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
                      if (blue  < blueValTarget and (background ~= blueValTarget)) then
                         blue = blue + 2;
                      else
                         --print("down")
                         blue = blue - 4;
                      end
                   end
                   if blueValTarget <= blue then
                      blueTarget =  setBlueTarget(i,background);
                   end

                   if(blue <0 ) then
                      blue = background
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
