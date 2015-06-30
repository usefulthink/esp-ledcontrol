--[[
# urest: a micro http/rest server, built for the nodeMCU ESP8266-firmware.

The idea behind this is to keep it as simple and small as possible (in terms of
usage of the extremely limited heap on the esp8266), by leaving out everything
that is not strictly required (like header-parsing etc) while still providing
an API that is reasonable easy to work with.

Also note that this doesn't contain any networking parts and just transforms a
HTTP-Request given as string into the corresponding response (also a string).

    -- urest networking integration (nodeMCU):
    net.createServer(net.TCP):listen(HTTP_PORT, function(client)
        client:on('receive', function(_, request)
            local response = urest.handle(request);

            client:send(response);
            client:close();
        end)
    end)

The only supported data-format is JSON (it uses the cjson-module for parsing
and serializing, so you'll need a nodemcu-image with that module built-in).

Request handlers are registered using the urest.get/post functions, passing
a route to match and a handler-function that will be called when a request
matching that route is handled.


## Usage

The simplest request-handler looks like this:

    urest.get('^/config', function()
        return { a='lua', table='with', some='data' }
    end)

The route is specified as a pattern for Lua's `string.match` function
(not-quite-but-similar-to-PCRE), the data returned by the handler-function
as a table will be JSON-encoded and sent to to client.

Patterns can also contain wildcards and capture groups. The matched portions
of the URL will be passed to the handler-function, along with the full request
and the request-body:

    cjson = require('cjson')
    urest.post('^/data/(%d+)', function(req, params, body)
        local data = cjson.decode(body)
        return {
            id=params[1],
            data=data
        }
    end)

The full usage-example for the request-handlers, including url-patterns and
body-parsing. This is what the three parameters are:
 - `req` contains the full request-body as it was passed to the
         `urest.handle`-function.
 - `params`: the parameters from the capture-groups in the URL-pattern (just
         the packed return-values from `string.match`)
 - `body`: the raw request-body. JSON-parsing is not done automatically here
         as one might very well get along without that


## Error-Handling

Handlers must return a result in any case. If an error occurs, a table with an
`error`-key containing the error details needs to be returned.
Such an error-table can be created using the `urest.error`-function.

    urest.get('/something)', function(req, params) {
        return urest.error(404, 'WRONG_ID', 'wrong id');
    })

Which is the same as

    urest.get('/something', function(req, params) {
        return { error = { status=404, code='WRONG_ID', msg='wrong id' } }
    })

In some cases errors are generated automatically:

 - if the handler-function produces a runtime-error, an error 500 is returned
   along with the error-message.
 - if not route matched the request, a 404-error is returned.

]]--

local cjson = require('cjson')

local STATUS_TEXT = {}
STATUS_TEXT[200] = 'OK'
STATUS_TEXT[400] = 'Bad request'
STATUS_TEXT[404] = 'Not found'
STATUS_TEXT[500] = 'Internal server error'

-- the main module
local urest = {};

-- the handler-registry
local _handlers = {
    GET = {},
    POST = {}
}

-- Registers a handler for HTTP GET-requests.
--
-- @param {string} url  The url to be matched
-- @param {function():table} handler  The handler-function
function urest.get(url, handler)
    _handlers.GET[url] = handler
end

-- Registers a handler for HTTP POST-requests.
--
-- @param {string} url  The url to be matched
-- @param {function():table} handler  The handler-function
function urest.post(url, handler)
    _handlers.POST[url] = handler
end

-- Create an error-object to be returned from a request-handler.
--
-- @param {number} status  HTTP-status for the error-response
-- @param {string} code  an error-code, passed on with the response
-- @param {string} msg  an error-message
-- @return {table} the error-table
function urest.error(status, code, msg)
    return { error = { status = status, code = code, msg = msg } }
end

-- Matches the routes and calls the corresponding handlers.
local function _callHandler(request, method, url, body)
    local handler, params

    if not _handlers[method] then
        return urest.error(404, 'NO_ROUTE', 'no routes for method ' + method)
    end

    for pattern, fn in pairs(_handlers[method]) do
        params ={url:match(pattern)}
        if params[1] then
            handler = fn
            break
        end
    end

    if not handler then
        return urest.error(404, 'NO_ROUTE', 'no route to match ' .. url)
    end

    local ok, result = pcall(handler, request, params, body)
    if not ok then
        return urest.error(500, 'INTERNAL_ERROR', result)
    end

    return result
end

-- Handles a (presumed) HTTP-Request.
--
-- @param {string} request  The full request as received via TCP
-- @return {string} response  The full reponse-body, including headers.
function urest.handle(request)
    local _, method, url, body, handler,
            status, result, responseText;

    -- read method and url form request
    method, url = request:match('^(%a+)%s+(%S+)%s+HTTP/1.[01]')

    if method == 'POST' then
        local bodyStartPos

        _, bodyStartPos = request:find('\r\n\r\n')
        body = request:sub(bodyStartPos + 1)
    end

    result = _callHandler(request, method, url, body)

    if result.error == nil then -- all good
        status = 200
    else -- the handler returned an error
        status = result.error.status
    end

    responseText = cjson.encode(result)

    return 'HTTP/1.1 ' .. status .. ' ' .. STATUS_TEXT[status] .. '\r\n' ..
            'Content-Type: application/json\r\n' ..
            'Content-Length: ' .. #responseText .. '\r\n\r\n' ..
            responseText
end

return urest