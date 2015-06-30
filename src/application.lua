local application = {};

function application.start()
    collectgarbage();

    if SERVER_MODE == 'OPC' then
        local opcServer = require("opc-server");
        opcServer.init(config);
    else
        local restServer = require("rest-server");
        restServer.init(config);
    end
end

return application
