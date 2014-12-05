# Description:
#   Display stats from New Relic
#
# Dependencies:
#
# Configuration:
#   HUBOT_NEWRELIC_API_KEY
#   HUBOT_NEWRELIC_API_HOST="api.newrelic.com"
#
# Commands:
#   hubot newrelic help - Returns a list of commands for this plugin
#   hubot newrelic apps - Returns statistics for all applications from New Relic
#   hubot newrelic apps name <filter_string> - Returns a filtered list of applications
#   hubot newrelic apps instances <app_id> - Returns a list of one application's instances
#   hubot newrelic apps hosts <app_id> - Returns a list of one application's hosts
#   hubot newrelic apps metrics <app_id> - Returns a list of one application's metric names
#   hubot newrelic apps metrics <app_id> name <filter_string> - Returns a filtered list of metric names and all valid types
#   hubot newrelic apps metrics <app_id> chart <metric_name> <metric_type> - Returns a chart for the metric/type based on the last 30 minutes of data
#   hubot newrelic ktrans - Lists stats for all key transactions from New Relic
#   hubot newrelic ktrans id <ktrans_id> - Returns a single key transaction
#   hubot newrelic servers - Returns statistics for all servers from New Relic
#   hubot newrelic servers name <filter_string> - Returns a filtered list of servers
#   hubot newrelic servers metrics <server_id> - Returns a list of one server's metric names
#   hubot newrelic servers metrics <app_id> name <filter_string> - Returns a filtered list of metric names and all valid types
#   hubot newrelic servers metrics <app_id> chart <metric_name> <metric_type> - Returns a chart for the metric/type based on the last 30 minutes of data
#   hubot newrelic users - Returns a list of all account users from New Relic
#   hubot newrelic user email <filter_string> - Returns a filtered list of account users
#
# Authors:
#   statianzo
#
# Contributors:
#   spkane
#

# TODO - deal with pagination. at the moment we are geting a single page, most likely.

fs     = require 'fs'
s3     = require 's3'
canvas = require 'canvas'
nchart = require 'nchart'

awsKey    = process.env.HUBOT_AWS_KEY
awsSecret = process.env.HUBOT_AWS_SECRET
s3Bucket  = process.env.HUBOT_AWS_S3_BUCKET
s3BaseUrl = "https://#{s3Bucket}.s3.amazonaws.com/"

plugin = (robot) ->
  apiKey = process.env.HUBOT_NEWRELIC_API_KEY
  apiHost = process.env.HUBOT_NEWRELIC_API_HOST
  apiBaseUrl = "https://#{apiHost}/v2/"
  config = {}

  keyword1 = 'nr'
  keyword2 = 'newrelic'

  switch robot.adapterName
    when "hipchat"
      config.up = '(continue)'
      config.down = '(failed)'

  request = (path, data, cb) ->
    robot.http(apiBaseUrl + path)
      .header('X-Api-Key', apiKey)
      .header("Content-Type","application/x-www-form-urlencoded")
      .post(data) (err, res, body) ->
        if err
          cb(err)
        else
          json = JSON.parse(body)
          if json.error
            cb(new Error(body))
          else
            cb(null, json)

  robot.respond ///(#{keyword1}|#{keyword2})\s+help\s*$///i, (msg) ->
    msg.send "
#{robot.name} #{keyword1}|#{keyword2} help\n
#{robot.name} #{keyword1}|#{keyword2} apps\n
#{robot.name} #{keyword1}|#{keyword2} apps name <filter_string>\n
#{robot.name} #{keyword1}|#{keyword2} apps instances <app_id>\n
#{robot.name} #{keyword1}|#{keyword2} apps hosts <app_id>\n
#{robot.name} #{keyword1}|#{keyword2} apps metrics <app_id>\n
#{robot.name} #{keyword1}|#{keyword2} apps metrics <app_id> name <filter_string>\n
#{robot.name} #{keyword1}|#{keyword2} apps metrics <app_id> chart <metric_name> <metric_type>\n
#{robot.name} #{keyword1}|#{keyword2} ktrans\n
#{robot.name} #{keyword1}|#{keyword2} ktrans id <ktrans_id>\n
#{robot.name} #{keyword1}|#{keyword2} servers\n
#{robot.name} #{keyword1}|#{keyword2} servers name <filter_string>\n
#{robot.name} #{keyword1}|#{keyword2} servers metrics <server_id>\n
#{robot.name} #{keyword1}|#{keyword2} apps metrics <app_id> name <filter_string>\n
#{robot.name} #{keyword1}|#{keyword2} apps metrics <app_id> chart <metric_name> <metric_type>\n
#{robot.name} #{keyword1}|#{keyword2} users\n
#{robot.name} #{keyword1}|#{keyword2} user email <filter_string>"

  robot.respond ///(#{keyword1}|#{keyword2})\s+apps\s*$///i, (msg) ->
    request 'applications.json', '', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else 
        msg.send plugin.apps json.applications, config

  robot.respond ///(#{keyword1}|#{keyword2})\s+ktrans\s*$///i, (msg) ->
    request 'key_transactions.json', '', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.ktrans json.key_transactions, config

  robot.respond ///(#{keyword1}|#{keyword2})\s+servers\s*$///i, (msg) ->
    request 'servers.json', '', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.servers json.servers, config

  robot.respond ///(#{keyword1}|#{keyword2})\s+users\s*$///i, (msg) ->
    request 'users.json', '', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.users json.users, config

  robot.respond ///(#{keyword1}|#{keyword2})\s+apps\s+name\s+([\s\S]+)\s*$///i, (msg) ->
    data = encodeURIComponent('filter[name]') + '=' +  encodeURIComponent(msg.match[2])
    request 'applications.json', data, (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.apps json.applications, config

  robot.respond ///(#{keyword1}|#{keyword2})\s+apps\s+hosts\s+([0-9]+)\s*$///i, (msg) ->
    request "applications/#{msg.match[2]}/hosts.json", '', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.hosts json.application_hosts, config

  robot.respond ///(#{keyword1}|#{keyword2})\s+apps\s+instances\s+([0-9]+)\s*$///i, (msg) ->
    request "applications/#{msg.match[2]}/instances.json", '', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.instances json.application_instances, config

  robot.respond ///(#{keyword1}|#{keyword2})\s+apps\s+metrics\s+([0-9]+)\s*$///i, (msg) ->
    request "applications/#{msg.match[2]}/metrics.json", '', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.metrics json.metrics, config

  robot.respond ///(#{keyword1}|#{keyword2})\s+apps\s+metrics\s+([0-9]+)\s+name\s+([\s\S]+)\s*$///i, (msg) ->
    data = encodeURIComponent('name') + '=' +  encodeURIComponent(msg.match[3])
    request "applications/#{msg.match[2]}/metrics.json", data, (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.values json.metrics, config

  robot.respond ///(#{keyword1}|#{keyword2})\s+apps\s+metrics\s+([0-9]+)\s+graph\s+([\s\S]+)\s+([\s\S]+)\s*$///i, (msg) ->
    data = encodeURIComponent('names[]') + '=' + encodeURIComponent(msg.match[3]) + '&' +
           encodeURIComponent('values[]') + '=' + encodeURIComponent(msg.match[4]) + '&summarize=false&raw=true'

    request "applications/#{msg.match[2]}/metrics/data.json", data, (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        graph_data = plugin.graph json.metric_data, msg.match[3], msg.match[4], config
        plugin.uploadChart msg, plugin.buildChart graph_data

  robot.respond ///(#{keyword1}|#{keyword2})\s+ktrans\s+id\s+([0-9]+)\s*$///i, (msg) ->
    request "key_transactions/#{msg.match[2]}.json", '', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.ktran json.key_transaction, config

  robot.respond ///(#{keyword1}|#{keyword2})\s+servers\s+name\s+([a-zA-Z0-9\-.]+)\s*$///i, (msg) ->
    data = encodeURIComponent('filter[name]') + '=' +  encodeURIComponent(msg.match[2])
    request 'servers.json', data, (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.servers json.servers, config

  robot.respond ///(#{keyword1}|#{keyword2})\s+servers\s+metrics\s+([0-9]+)\s*$///i, (msg) ->
    request "servers/#{msg.match[2]}/metrics.json", '', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.metrics json.metrics, config

  robot.respond ///(#{keyword1}|#{keyword2})\s+servers\s+metrics\s+([0-9]+)\s+name\s+([\s\S]+)\s*$///i, (msg) ->
    data = encodeURIComponent('name') + '=' +  encodeURIComponent(msg.match[3])
    request "servers/#{msg.match[2]}/metrics.json", data, (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.values json.metrics, config

  robot.respond ///(#{keyword1}|#{keyword2})\s+servers\s+metrics\s+([0-9]+)\s+graph\s+([\s\S]+)\s+([\s\S]+)\s*$///i, (msg) ->
    data = encodeURIComponent('names[]') + '=' + encodeURIComponent(msg.match[3]) + '&' + encodeURIComponent('values[]') + '=' + encodeURIComponent(msg.match[4]) + '&summarize=false&raw=true'
    request "servers/#{msg.match[2]}/metrics/data.json", data, (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        graph_data = plugin.graph json.metric_data, msg.match[3], msg.match[4], config
        plugin.uploadChart msg, plugin.buildChart graph_data

  robot.respond ///(#{keyword1}|#{keyword2})\s+users\s+email\s+([a-zA-Z0-9.@]+)\s*$///i, (msg) ->
    data = encodeURIComponent('filter[email]') + '=' +  encodeURIComponent(msg.match[2])
    request 'users.json', data, (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.users json.users, config

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

    line.push "#{a.name} (#{a.id})"

    if isFinite(summary.response_time)
      line.push "Res:#{summary.response_time}ms"

    if isFinite(summary.throughput)
      line.push "RPM:#{summary.throughput}"

    if isFinite(summary.error_rate)
      line.push "Err:#{summary.error_rate}%"

    line.join "  "

  lines.join("\n")

plugin.hosts = (hosts, opts = {}) ->

  lines = hosts.map (h) ->
    line = []
    summary = h.application_summary || {}

    line.push h.application_name
    line.push h.host

    if isFinite(summary.response_time)
      line.push "Res:#{summary.response_time}ms"

    if isFinite(summary.throughput)
      line.push "RPM:#{summary.throughput}"

    if isFinite(summary.error_rate)
      line.push "Err:#{summary.error_rate}%"

    line.join "  "

  lines.join("\n")

plugin.instances = (instances, opts = {}) ->

  lines = instances.map (i) ->
    line = []
    summary = i.application_summary || {}

    line.push i.application_name
    line.push i.host

    if isFinite(summary.response_time)
      line.push "Res:#{summary.response_time}ms"

    if isFinite(summary.throughput)
      line.push "RPM:#{summary.throughput}"

    if isFinite(summary.error_rate)
      line.push "Err:#{summary.error_rate}%"

    line.join "  "

  lines.join("\n")

plugin.ktrans = (ktrans, opts = {}) ->

  lines = ktrans.map (k) ->
    line = []
    a_summary = k.application_summary || {}
    u_summary = k.end_user_summary || {}

    line.push "#{k.name} (#{k.id})"

    if isFinite(a_summary.response_time)
      line.push "Res:#{a_summary.response_time}ms"

    if isFinite(u_summary.response_time)
      line.push "URes:#{u_summary.response_time}ms"

    if isFinite(a_summary.throughput)
      line.push "RPM:#{a_summary.throughput}"

    if isFinite(u_summary.throughput)
      line.push "URPM:#{u_summary.throughput}"

    if isFinite(a_summary.error_rate)
      line.push "Err:#{a_summary.error_rate}%"

    line.join "  "

  lines.join("\n")

plugin.ktran = (ktran, opts = {}) ->

  result = [ktran]

  lines = result.map (t) ->
    line = []
    a_summary = t.application_summary || {}

    line.push t.name

    if isFinite(a_summary.response_time)
      line.push "Res:#{a_summary.response_time}ms"

    if isFinite(a_summary.throughput)
      line.push "RPM:#{a_summary.throughput}"

    if isFinite(a_summary.error_rate)
      line.push "Err:#{a_summary.error_rate}%"

    line.join "  "

  lines.join("\n")

plugin.values = (values, opts = {}) ->
  lines = values.map (m) ->
    line = []
    m_values = m.values || {}

    line.push m.name
    line.push "\n"

    line.push "Values:  #{m_values.join()}"

    line.join "  "
  lines.join("\n\n")

plugin.metrics = (metrics, opts = {}) ->
  lines = metrics.map (m) ->
    line = []

    line.push m.name

    line.join "  "
  lines.join("\n")

# Builds image with canvas and nchart
plugin.buildChart = (graph_data) ->
  nr_light = 'rgba(152,220,220,1)'
  nr_dark  = 'rgba(50,134,152,1)'
  jsonData = {}

  jsonData.labels = [-30..-1].map (a) ->
    a = a.toString()
  jsonData.datasets = [{}]
  jsonData.datasets[0].fillColor = nr_light
  jsonData.datasets[0].strokeColor = nr_dark
  jsonData.datasets[0].pointColor = "rgba(255,255,255,1)"
  jsonData.datasets[0].pointStrokeColor = "#000"
  jsonData.datasets[0].data = graph_data

  chart = new canvas(1000, 800)
  ctx = chart.getContext("2d")
  ctx.fillStyle = '#000'
  max = Math.max.apply(Math, graph_data)
  steps = 10

  nchart(ctx).Line jsonData,
    scaleOverlay: not true
    scaleOverride: true
    scaleSteps: steps
    scaleStartValue: 0
    scaleStepWidth: Math.ceil(max / steps)
  return chart

# Write and upload chart to S3
plugin.uploadChart = (msg, chart) ->
  timeStamp = plugin.formatDate (new Date())
  imageName = "chart-#{timeStamp}.png"

  client = s3.createClient(
    maxAsyncS3: 20
    s3RetryCount: 3
    s3RetryDelay: 1000
    multipartUploadThreshold: 20971520
    multipartUploadSize: 15728640
    s3Options:
      accessKeyId: awsKey
      secretAccessKey: awsSecret
  )

  chart.toBuffer (err, buf) ->
    throw err  if err
    fs.writeFile __dirname + "/chart.png", buf

    params =
      localFile: __dirname + "/chart.png"
      s3Params:
        Bucket: s3Bucket
        Key: imageName

    uploader = client.uploadFile(params)
    uploader.on "error", (err) ->
      console.error "unable to upload:", err.stack
      return

    uploader.on "progress", ->
      console.log "progress", uploader.progressMd5Amount, uploader.progressAmount, uploader.progressTotal
      return

    uploader.on "end", ->
      console.log "done uploading"
      fs.unlink( __dirname + '/chart.png' )
      msg.send s3BaseUrl + imageName
      return
      
plugin.graph = (graph, metric_name, value_name, opts = {}) ->
  result = [graph]

  line = []

  result.map (g) ->
    metrics = g.metrics

    metrics.map (m) ->

      if m.name == metric_name
        ts = m.timeslices

        ts.map (t) ->
          values = [t.values]
          value = ''

          values.map (v) ->
            value = v[value_name]
            if isNaN(value)
              throw "No-numeric value detected.";

          line.push parseFloat(value)

  return line

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

    line.push "#{s.name} (#{s.id})"

    if isFinite(summary.cpu)
      line.push "CPU:#{summary.cpu}%"

    if isFinite(summary.memory)
      line.push "Mem:#{summary.memory}%"

    if isFinite(summary.fullest_disk)
      line.push "Disk:#{summary.fullest_disk}%"

    line.join "  "

  lines.join("\n")

plugin.users = (users, opts = {}) ->

  lines = users.map (u) ->
    line = []

    line.push "#{u.first_name} #{u.last_name}"
    line.push "Email: #{u.email}"
    line.push "Role: #{u.role}"

    line.join "  "

  lines.join("\n")

plugin.formatDate = (date) ->
  timeStamp = [date.getFullYear(), (date.getMonth() + 1), date.getDate(), date.getHours(), date.getMinutes(), date.getSeconds()].join(" ")
  RE_findSingleDigits = /\b(\d)\b/g

  # Places a `0` in front of single digit numbers.
  timeStamp = timeStamp.replace( RE_findSingleDigits, "0$1" )
  timeStamp.replace /\s/g, ""

module.exports = plugin
