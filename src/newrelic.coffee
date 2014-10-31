# Description:
#   Display current server stats from New Relic
#
# Dependencies:
#
# Configuration:
#   HUBOT_NEWRELIC_API_KEY
#
# Commands:
#   hubot newrelic servers - Returns summary server stats from New Relic
#   hubot newrelic apps - Returns summary application stats from New Relic
#
# Author:
#   statianzo



plugin = (robot) ->
  apiKey = process.env.HUBOT_NEWRELIC_API_KEY
  apiBaseUrl = "https://api.newrelic.com/v2/"

  request = (path, cb) ->
    robot.http(apiBaseUrl + path)
      .header('X-Api-Key', apiKey)
      .get() (err, res, body) ->
        if err
          msg.send "New Relic says: #{err}"
          cb(err)
          return

        cb null, JSON.parse(body)

  robot.respond /newrelic servers/i, (msg) ->
    servers apiKey, msg

  robot.respond /newrelic apps/i, (msg) ->
    apps apiKey, msg

plugin.servers = (servers, opts) ->
  opts ||= {}
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

    if summary.cpu
      line.push "CPU:#{summary.cpu}%"

    if summary.memory
      line.push "Mem:#{summary.memory}%"

    if summary.fullest_disk
      line.push "Disk:#{summary.fullest_disk}%"

    line.join "  "

  lines.join("\n")

plugin.apps = (msg, apps) ->
  lines = result.applications.map (a) ->
    line = []

    if a.health_status == "green"
      line.push "(continue)"
    else if a.health_status == "grey"
      line.push "(unknown)"
    else
      line.push "(failed)"

    line.push a.name

    line.join "  "

  msg.send lines.join("\n")

module.exports = plugin
