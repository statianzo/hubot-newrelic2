Error.stackTraceLimit = 1

servers = require("../src/newrelic").servers
module.exports =
  "empty string when no servers": (test) ->
    res = servers []
    test.equal(res, "")
    test.done()
