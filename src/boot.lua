config = require("config")

local function wifi_start(accessPoints)
    for essid, info in pairs(accessPoints) do
        if config.SSID and config.SSID[essid] then
            wifi.sta.config(essid, config.SSID[essid]);
            wifi.sta.connect();
            config.SSID = nil;

            tmr.alarm(1, 500, 1, function()
                if wifi.sta.getip() then
                    tmr.stop(2);
                    tmr.stop(1);
                    print("Connected to network: " .. essid .. ", IP address: " .. wifi.sta.getip());

                    collectgarbage();
                    require("application").start();
                end
            end);

            break
        end
        collectgarbage();
    end
end

local function renderPreset()
    local brightness = 0
    tmr.alarm(2, 30, 1, function()
        if brightness < 220 then
            brightness = brightness + 1
        else
            tmr.stop(2);
        end

        local color = string.char(brightness+10, brightness+30, brightness)
        ws2812.write(config.LED_PIN, color:rep(config.NUM_LEDS));
    end)
end

print("setting initial scene...");
renderPreset();

print("connecting...");
collectgarbage();
wifi.setmode(wifi.STATION);
wifi.sta.getap(wifi_start);