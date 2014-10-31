Error.stackTraceLimit = 1

samples = require("./samples")
console.log samples
servers = require("../src/newrelic").servers
list = null

module.exports =

  "empty string when no servers": (test) ->
    res = servers []
    test.equal("", res)
    test.done()

  "one line per server": (test) ->
    res = servers samples.servers().servers
    test.equal(2, res.split("\n").length)
    test.done()
