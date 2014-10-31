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

module.exports = (robot) ->
  servers = (apiKey, msg) ->
    robot.http("https://api.newrelic.com/v2/servers.json")
      .header('X-Api-Key', apiKey)
      .get() (err, res, body) ->
        if err
          msg.send "New Relic says: #{err}"
          return

        result = JSON.parse(body)
        lines = result.servers.map (s) ->
          line = []
          summary = s.summary || {}

          if s.reporting
            line.push "(continue)"
          else
            line.push "(failed)"
          line.push s.name

          if summary.cpu
            line.push "CPU:#{summary.cpu}%"

          if summary.memory
            line.push "Mem:#{summary.memory}%"

          if summary.fullest_disk
            line.push "Disk:#{summary.fullest_disk}%"

          line.join "  "

        msg.send lines.join("\n")

  apps = (apiKey, msg) ->
    robot.http("https://api.newrelic.com/v2/applications.json")
      .header('X-Api-Key', apiKey)
      .get() (err, res, body) ->
        if err
          msg.send "New Relic says: #{err}"
          return

        result = JSON.parse(body)
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



  robot.respond /newrelic servers/i, (msg) ->
    apiKey = process.env.HUBOT_NEWRELIC_API_KEY
    servers apiKey, msg

  robot.respond /newrelic apps/i, (msg) ->
    apiKey = process.env.HUBOT_NEWRELIC_API_KEY
    apps apiKey, msg
