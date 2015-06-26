local application = {};

function application.start()
    print("starting opc-server");
    collectgarbage();

    local opcServer = require("opc-server");
    opcServer.init(config);
end

return application
