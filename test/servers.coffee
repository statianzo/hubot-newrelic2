Error.stackTraceLimit = 1

samples = require("./samples")
cmd = require("../src/newrelic").servers

res = servers = lines = null

module.exports =
  setUp: (done) ->
    servers = samples.servers().servers
    res = cmd servers
    lines = res.split("\n")
    done()

  "empty string when no servers": (test) ->
    res = cmd []
    test.equal("", res)
    test.done()

  "one line per server": (test) ->
    test.equal(2, res.split("\n").length)
    test.done()

  "indicates UP or DN": (test) ->
    test.ok(lines[0].match /UP/)
    test.ok(lines[1].match /DN/)
    test.done()

  "contains name": (test) ->
    test.ok(lines[0].match servers[0].name)
    test.ok(lines[1].match servers[1].name)
    test.done()

  "lists stats": (test) ->
    for stat in ["cpu", "memory", "fullest_disk"]
      test.ok(lines[0].match servers[0][stat], "Missing stat #{stat}")
    test.done()

  "hides label for unknown stats": (test) ->
    for label in ["CPU", "Mem", "Disk"]
      test.ok(!lines[1].match(label), "Contained label #{label}")
    test.done()

  "Allows custom up and down text": (test) ->
    res = cmd servers, up: 'HI', down: 'BYE'
    lines = res.split("\n")
    test.ok(lines[0].match /HI/)
    test.ok(lines[1].match /BYE/)
    test.done()
