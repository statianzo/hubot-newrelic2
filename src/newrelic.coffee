# Description:
#   Display stats from New Relic
#
# Dependencies:
#
# Configuration:
#   HUBOT_NEWRELIC_API_KEY
#
# Commands:
#   hubot newrelic servers - Returns server stats from New Relic
#   hubot newrelic apps - Returns application stats from New Relic
#
# Author:
#   statianzo



plugin = (robot) ->
  apiKey = process.env.HUBOT_NEWRELIC_API_KEY
  apiBaseUrl = "https://api.newrelic.com/v2/"
  config = {}

  switch robot.adapterName
    when "hipchat"
      config.up = '(continue)'
      config.down = '(failed)'

  request = (path, cb) ->
    robot.http(apiBaseUrl + path)
      .header('X-Api-Key', apiKey)
      .get() (err, res, body) ->
        if err
          cb(err)
        else
          json = JSON.parse(body)
          if json.error
            cb(new Error(body))
          else
            cb(null, json)

  robot.respond /newrelic servers/i, (msg) ->
    request 'servers.json', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.servers json.servers, config

  robot.respond /newrelic apps/i, (msg) ->
    request 'applications.json', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.apps json.applications, config

plugin.servers = (servers, opts = {}) ->
  up = opts.up || "UP"
  down = opts.down || "DN"
  lines = servers.map (s) ->
    line = []
    summary = s.summary || {}

    if s.reporting
      line.push up
    else
      line.push down
    line.push s.name

    if isFinite(summary.cpu)
      line.push "CPU:#{summary.cpu}%"

    if isFinite(summary.memory)
      line.push "Mem:#{summary.memory}%"

    if isFinite(summary.fullest_disk)
      line.push "Disk:#{summary.fullest_disk}%"

    line.join "  "

  lines.join("\n")

plugin.apps = (apps, opts = {}) ->
  up = opts.up || "UP"
  down = opts.down || "DN"

  lines = apps.map (a) ->
    line = []
    summary = a.application_summary || {}

    if a.reporting
      line.push up
    else
      line.push down

    line.push a.name

    if isFinite(summary.response_time)
      line.push "Res:#{summary.response_time}ms"

    if isFinite(summary.throughput)
      line.push "RPM:#{summary.throughput}"

    if isFinite(summary.error_rate)
      line.push "Err:#{summary.error_rate}%"

    line.join "  "

  lines.join("\n")

module.exports = plugin
