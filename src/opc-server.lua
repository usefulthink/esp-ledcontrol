local opcServer = {};

local OPC_COMMAND = {
    SETPIXELCOLOR = 0,
    SYSEX = 1
};

function opcServer.init(config)
    local srv = net.createServer(net.TCP);

    srv:listen(config.OPC_PORT, function(socket)
        socket:on("receive", function(client, msg)
            -- body[0]: channel (uint8)
            -- body[1]: command (uint8) [SYSEX: 0xff, SETPIXELCOLOR: 0x00]
            -- body[2,3]: length (uint16BE)
            local channel = msg:byte(1);
            local command = msg:byte(2);
            -- length is ignored for now - assuming a full packet in every received frame
            -- local length = (body:byte(3) * 256) + body:byte(4);

            -- skip messages for other channels
            if not (channel == 0 or channel == config.OPC_CHANNEL) then
                return;
            end

            collectgarbage();
            if command == OPC_COMMAND.SETPIXELCOLOR then
                local grb = msg:sub(5):gsub("(.)(.)(.)", "%2%1%3")
                ws2812.write(config.LED_PIN, grb);
            end
        end);
    end);
end

return opcServer;