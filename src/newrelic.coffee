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
#   hubot newrelic apps errors - Returns statistics for applications with errors from New Relic
#   hubot newrelic apps name <filter_string> - Returns a filtered list of applications
#   hubot newrelic apps instances <app_id> - Returns a list of one application's instances
#   hubot newrelic apps hosts <app_id> - Returns a list of one application's hosts
#   hubot newrelic apps metrics <app_id> - Returns a list of one application's metric names
#   hubot newrelic apps metrics <app_id> name <filter_string> - Returns a filtered list of metric names and all valid types
#   hubot newrelic apps metrics <app_id> graph <metric_name> <metric_type> - Returns a graph for the metric/type based on the last 30 minutes of data
#   hubot newrelic ktrans - Lists stats for all key transactions from New Relic
#   hubot newrelic ktrans id <ktrans_id> - Returns a single key transaction
#   hubot newrelic servers - Returns statistics for all servers from New Relic
#   hubot newrelic servers name <filter_string> - Returns a filtered list of servers
#   hubot newrelic servers metrics <server_id> - Returns a list of one server's metric names
#   hubot newrelic servers metrics <server_id> name <filter_string> - Returns a filtered list of metric names and all valid types
#   hubot newrelic servers metrics <server_id||filter_string> graph <metric_name> <metric_type> - Returns a graph for the metric/type based on the last 30 minutes of data
#
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
    when "slack"
      config.up = ':green_circle:'
      config.down = ':red_circle:'

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

  # Helper function for building a New Relic UI URL
  buildURL = (server, graph_type) ->
    base_url = process.env.HUBOT_NEWRELIC_URL

    if (! base_url?)
      return "HUBOT_NEWRELIC_URL environment variable not defined."

    if (! server.account_id?)
      return "Unable to find account ID in server object."

    built_url = base_url + "/accounts/" + server.account_id + "/servers/" + server.id

    if graph_type.match(/disk/i)
      return built_url + "/disks"
    else if graph_type.match(/network/i)
      return built_url + "/network"
    else if graph_type.match(/process/i)
      return built_url + "/processes"
    else
      # Overview
      return built_url

  # Helper function for fetching server(s) by name or ID
  getServer = (server, cb) ->
    filter = 'filter[name]'

    if server.match(/^\d+$/g)
      filter = 'filter[ids]'

    data = encodeURIComponent(filter) + '=' +  encodeURIComponent(server)

    request 'servers.json', data, (err, json) ->
      if err
        cb(false, err.message)
      else
        cb(true, json)


  getServerVerify = (status, details, msg) ->
    if ! status
      msg.send "Failed: #{details}"
      return false

    if details.servers.length == 0
      msg.send "No servers found by that name/id."
      return false

    if details.servers.length > 1
      msg.send "Result set contains #{details.servers.length} servers; please clarify:"
      servers = details.servers.map (server) -> server.name
      msg.send servers.join(', ')
      return false

    return true

  # Helper function for fetching app(s) by name or ID
  getApps = (app, cb) ->
    filter = 'filter[name]'

    if app.match(/^\d+$/g)
      filter = 'filter[ids]'

    data = encodeURIComponent(filter) + '=' +  encodeURIComponent(app)

    request 'applications.json', data, (err, json) ->
      if err
        cb(false, err.message)
      else
        cb(true, json)

  getAppsVerify = (status, details, msg) ->
    if ! status
      msg.send "Failed: #{details}"
      return false

    if details.applications.length == 0
      msg.send "No apps found by that name/ID."
      return false

    if details.applications.length > 1
      msg.send "Result set contains #{details.applications.length} servers; please clarify:"
      apps = details.applications.map (app) -> app.name + " (#{app.id})"
      msg.send apps.join(', ')
      return false

    return true

  robot.respond ///(#{keyword1}|#{keyword2})\s+help\s*$///i, (msg) ->
    msg.send "```Commands:\n
    #{robot.name} #{keyword1} | #{keyword2} help\n
    #{robot.name} #{keyword1} | #{keyword2} apps\n
    #{robot.name} #{keyword1} | #{keyword2} apps errors\n
    #{robot.name} #{keyword1} | #{keyword2} apps name <filter_string>\n
    #{robot.name} #{keyword1} | #{keyword2} apps instances <app_id>\n
    #{robot.name} #{keyword1} | #{keyword2} apps hosts <app_id>\n
    #{robot.name} #{keyword1} | #{keyword2} apps metrics <app_id>\n
    #{robot.name} #{keyword1} | #{keyword2} apps metrics <app_id> name <filter_string>\n
    #{robot.name} #{keyword1} | #{keyword2} apps metrics <app_id> graph <metric_name> <metric_type>\n
    #{robot.name} #{keyword1} | #{keyword2} ktrans\n
    #{robot.name} #{keyword1} | #{keyword2} ktrans id <ktrans_id>\n
    #{robot.name} #{keyword1} | #{keyword2} servers\n
    #{robot.name} #{keyword1} | #{keyword2} servers name <filter_string>\n
    #{robot.name} #{keyword1} | #{keyword2} servers metrics <server_id>\n
    #{robot.name} #{keyword1} | #{keyword2} servers metrics <app_id||filter_string> graph <metric_name> <metric_type>\n
    #{robot.name} #{keyword1} | #{keyword2} servers <app_id||filter_string> graph load||disk||net||network||cpu||mem||memory\n
    #{robot.name} #{keyword1} | #{keyword2} apps metrics <app_id> name <filter_string>\n
    #{robot.name} #{keyword1} | #{keyword2} apps metrics <app_id> graph <metric_name> <metric_type>\n
    #{robot.name} #{keyword1} | #{keyword2} apps metrics <app_id|\"filter string\"> graph rpm||errors\n
    #{robot.name} #{keyword1} | #{keyword2} users\n
    #{robot.name} #{keyword1} | #{keyword2} user email <filter_string> ```"

  robot.respond ///(#{keyword1}|#{keyword2})\s+apps\s*$///i, (msg) ->
    request 'applications.json', '', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.apps json.applications, config

  robot.respond ///(#{keyword1}|#{keyword2})\s+apps\s+errors$///i, (msg) ->
    request 'applications.json', '', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        result = (item for item in json.applications when item.error_rate > 0)
        if result.length > 0
          msg.send plugin.apps result, config
        else
          msg.send "No applications with errors."

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
        graph_data = plugin.graph json.metric_data, [msg.match[3]], msg.match[4], config
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

  # Graph specific metric data for a given server (accepts server ID or name)
  robot.respond ///(#{keyword1}|#{keyword2})\s+servers\s+metrics\s+([a-zA-Z0-9_\-\.]+)\s+graph\s+([\s\S]+)\s+([\s\S]+)\s*$///i, (msg) ->
    getServer msg.match[2], (status, details) ->
      # Perform some basic checks
      if ! getServerVerify status, details, msg
        return

      server_id = details.servers[0].id
      nr_ui_url = buildURL details.servers[0], msg.match[3]

      data = encodeURIComponent('names[]') + '=' + encodeURIComponent(msg.match[3]) + '&' + encodeURIComponent('values[]') + '=' + encodeURIComponent(msg.match[4]) + '&summarize=false&raw=true'
      request "servers/#{server_id}/metrics/data.json", data, (err, json) ->
        if err
          msg.send "Failed: #{err.message}"
        else
          msg.send "New Relic UI: #{nr_ui_url}"
          graph_data = plugin.graph json.metric_data, [msg.match[3]], msg.match[4], config
          plugin.uploadChart msg, plugin.buildChart graph_data

  # 'Shortcut' graph function
  robot.respond ///(#{keyword1}|#{keyword2})\s+servers\s+([a-zA-Z0-9_\-\.]+)\s+graph\s+(load|network|net|disk|mem|memory|cpu)\s*$///i, (msg) ->
    getServer msg.match[2], (status, details) ->
      # Perform some basic checks
      if ! getServerVerify status, details, msg
        return

      server_id = details.servers[0].id
      metric_map = {'load'    : ['System/Load'],\
                    'cpu'     : ['System/CPU/IO Wait/percent',\
                                 'System/CPU/System/percent',\
                                 'System/CPU/User/percent'],\
                    'mem'     : ['System/Memory/Used/bytes'],\
                    'memory'  : ['System/Memory/Used/bytes'],\
                    'net'     : ['System/Network/All/Received/bytes/sec',\
                                 'System/Network/All/Transmitted/bytes/sec'],\
                    'network' : ['System/Network/All/Received/bytes/sec',\
                                 'System/Network/All/Transmitted/bytes/sec'],\
                    'disk'    : ['System/Disk/All/Reads/bytes/sec',\
                                 'System/Disk/All/Writes/bytes/sec']}

      graph_type = msg.match[3]
      value_type = 'average_value'
      data = ''

      if graph_type == "net" || graph_type == "network" || graph_type == 'disk'
        value_type = 'per_second'

      for value in metric_map[graph_type]
        data = data + encodeURIComponent('names[]') + '=' + encodeURIComponent(value) + '&'

      data = data + encodeURIComponent('values[]') + '=' + value_type + '&summarize=false&raw=true'

      request "servers/#{server_id}/metrics/data.json", data, (err, json) ->
        if err
          msg.send "Failed: #{err.message}"
        else
          graph_data = plugin.graph json.metric_data, metric_map[graph_type], value_type, config
          plugin.uploadChart msg, plugin.buildChart graph_data

  # 'Shortcut' app graph function
  ## Allows for '/nr apps 1234 graph rpm' OR '/nr apps "Some App" graph rpm'
  robot.respond ///(#{keyword1}|#{keyword2})\s+apps\s+([0-9]+|"[a-zA-Z0-9_\-\.\s\(\)]+")\s+graph\s+(rpm|errors)\s*$///i, (msg) ->
    app_id = msg.match[2].replace(/"/g, "")

    getApps app_id, (status, details) ->
      # Perform some basic checks
      if ! getAppsVerify status, details, msg
        return

      app_id = details.applications[0].id
      metric_map = {'errors' : {'name'  : ['Errors/all'],\
                                'value' : 'errors_per_minute'},\
                    'rpm'    : {'name'  : ['OtherTransaction/all'],\
                                'value' : 'requests_per_minute'}}

      graph_type = msg.match[3]
      data = ''

      for value in metric_map[graph_type]['name']
        data = data + encodeURIComponent('names[]') + '=' + encodeURIComponent(value) + '&'

      data = data + encodeURIComponent('values[]') + '=' + metric_map[graph_type]['value'] + '&summarize=false&raw=true'

      request "applications/#{app_id}/metrics/data.json", data, (err, json) ->
        if err
          msg.send "Failed: #{err.message}"
        else
          graph_data = plugin.graph json.metric_data, metric_map[graph_type]['name'], metric_map[graph_type]['value'], config
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
      line.push "" + up
    else
      line.push down

    line.push "#{a.name} (#{a.id})"

    if isFinite(summary.response_time)
      line.push "Res:#{summary.response_time}ms"

    if isFinite(summary.throughput)
      line.push "RPM:#{summary.throughput}"

    if isFinite(summary.error_rate)
      line.push "Err:#{summary.error_rate}% "

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

# Build a multi-plot chart (limitation: max 5 separate data plots)
plugin.buildChart = (graph_data) ->
  colors = ["rgba(50,134,152,0.4)",\  # NR light
            "rgba(166,209,123,0.4)",\ # Green
            "rgba(241,128,107,0.4)",\ # Salmon
            "rgba(241,209,102,0.4)",\ # Golden
            "rgba(168,119,179,0.4)"]  # Purple

  jsonData = {}

  jsonData.labels = [-30..-1].map (a) ->
    a = a.toString()

  # Hack: pad the first label with a few extra spaces so there's no clipping
  jsonData.labels[0] = '   -30'
  jsonData.datasets = [{}]
  i = 0

  if Object.keys(graph_data).length > colors.length
    throw "Got more data sets than we can handle (max #{colors.length}"

  for k, v of graph_data
    jsonData.datasets[i] = {}
    jsonData.datasets[i].label = k
    jsonData.datasets[i].fillColor = colors[i]
    jsonData.datasets[i].strokeColor = "rgba(50,134,152,1)" # NR dark
    jsonData.datasets[i].pointColor = "rgba(255,255,255,1)"
    jsonData.datasets[i].pointStrokeColor = "#000"
    jsonData.datasets[i].data = v
    i++

  chart = new canvas(1000, 800)
  ctx = chart.getContext("2d")
  ctx.fillStyle = '#000'
  max = Math.max.apply(Math, jsonData.datasets[0].data)
  steps = 10

  nchart(ctx).Line jsonData,
    scaleOverride: true
    scaleSteps: steps
    scaleStartValue: 0
    datasetFill : true
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

# Convert NR data set into a simpler object to be consumed by nchart lib
# Return data set: {'metric_name' : [1, 2, 3], 'metric_name2' : [1, 2, 3, 4]}
plugin.graph = (graph, metric_names, value_name, opts = {}) ->
  result = [graph]

  line = {}

  for i in metric_names
    line[i] = []

  result.map (g) ->
    metrics = g.metrics

    metrics.map (m) ->
      for metric_name in metric_names
        if m.name == metric_name
          ts = m.timeslices

          ts.map (t) ->
            values = [t.values]
            value = ''

            values.map (v) ->
              value = v[value_name]
              if isNaN(value)
                throw "No-numeric value detected.";

            line[metric_name].push parseFloat(value)

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