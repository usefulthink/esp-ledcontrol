local urest = require('urest');
local restServer = {};

function restServer.init(config)
    local srv = net.createServer(net.TCP);

    urest.get('/config', function(req)
        return config
    end)

    urest.post('/color', function(req, params, body)
        local data = cjson.decode(body);

        if not data.color or #data.color < 3 then
            return urest.error(400, 'NO_COLORS', 'missing color-data');
        end

        ws2812.writergb(config.LED_PIN,
            string.char(data.color[1], data.color[2], data.color[3]):rep(config.NUM_LEDS)
        )

        return { error = nil }
    end)

    srv:listen(config.HTTP_PORT, function(client)
        client:on('receive', function(_, request)
            local response = urest.handle(request)

            client:send(response);
            client:close();
        end)
    end)
end

return restServer;