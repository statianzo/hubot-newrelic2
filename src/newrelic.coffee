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
#   hubot newrelic set date format <date_format>
#                  see https://github.com/pillarsjs/date.format for date formats
#   hubot newrelic apps - Returns statistics for all applications from New Relic
#   hubot newrelic apps errors - Returns statistics for applications with errors from New Relic
#   hubot newrelic apps name <filter_string> - Returns a filtered list of applications
#   hubot newrelic apps instances <app_id> - Returns a list of one application's instances
#   hubot newrelic apps hosts <app_id> - Returns a list of one application's hosts
#   hubot newrelic deployments <app_id> - Returns a filtered list of application deployment events
#   hubot newrelic ktrans - Lists stats for all key transactions from New Relic
#   hubot newrelic ktrans id <ktrans_id> - Returns a single key transaction
#   hubot newrelic servers - Returns statistics for all servers from New Relic
#   hubot newrelic servers name <filter_string> - Returns a filtered list of servers
#   hubot newrelic users - Returns a list of all account users from New Relic
#   hubot newrelic user email <filter_string> - Returns a filtered list of account users
#
# Authors:
#   statianzo
#
# Contributors:
#   spkane
#   cmckni3
#

require('date.format')

DATE_FORMAT_KEY     = 'newrelic_date_format'
DEFAULT_DATE_FORMAT = '{Y}-{M}-{D} at {h}:{m}:{s}'

plugin = (robot) ->
  apiKey = process.env.HUBOT_NEWRELIC_API_KEY
  apiHost = process.env.HUBOT_NEWRELIC_API_HOST or 'api.newrelic.com'
  apiBaseUrl = "https://#{apiHost}/v2/"
  config = {}

  date_format = robot.brain.get(DATE_FORMAT_KEY)

  if !date_format? or date_format is ''
    robot.brain.set DATE_FORMAT_KEY, DEFAULT_DATE_FORMAT

  switch robot.adapterName
    when "hipchat"
      config.up = '(continue)'
      config.down = '(failed)'
      config.blockquote = '/code '
    when "slack"
      config.up = ':white_check_mark:'
      config.down = ':no_entry_sign:'
      config.blockquote = '>>> '

  _parse_response = (cb) ->
    (err, res, body) ->
      if err
        cb(err)
      else
        json = JSON.parse(body)
        if json.error
          cb(new Error(body))
        else
          cb(null, json)

  _request = (path, cb) ->
    robot.http(apiBaseUrl + path)
      .header('X-Api-Key', apiKey)
      .header('Content-Type','application/x-www-form-urlencoded')

  get = (path, cb) ->
    return cb({message:'HUBOT_NEWRELIC_API_KEY is not set'}) if !apiKey
    _request(path).get() _parse_response(cb)
  post = (path, data, cb) ->
    return cb({message:'HUBOT_NEWRELIC_API_KEY is not set'}) if !apiKey
    _request(path).post(data) _parse_response(cb)

  robot.respond /(newrelic|nr) help$/i, (msg) ->
    msg.send "
Note: In these commands you can shorten newrelic to nr.\n
#{robot.name} newrelic help\n
#{robot.name} newrelic set date format <date_format>\n
              see https://github.com/pillarsjs/date.format for date formats\n
#{robot.name} newrelic apps\n
#{robot.name} newrelic apps errors\n
#{robot.name} newrelic apps name <filter_string>\n
#{robot.name} newrelic apps instances <app_id>\n
#{robot.name} newrelic apps hosts <app_id>\n
#{robot.name} newrelic deployments <app_id>\n
#{robot.name} newrelic ktrans\n
#{robot.name} newrelic ktrans id <ktrans_id>\n
#{robot.name} newrelic servers\n
#{robot.name} newrelic servers name <filter_string>\n
#{robot.name} newrelic users\n
#{robot.name} newrelic user email <filter_string>"

  robot.respond /(newrelic|nr) set date format (.+)$/i, (msg) ->
    new_date_format = msg.match[2]
    robot.brain.set DATE_FORMAT_KEY, new_date_format
    msg.send "Date format set to #{new_date_format}"

  robot.respond /(newrelic|nr) apps$/i, (msg) ->
    get 'applications.json', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.apps json.applications, config

  robot.respond /(newrelic|nr) apps errors$/i, (msg) ->
    get 'applications.json', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        result = (item for item in json.applications when item.error_rate > 0)
        if result.length > 0
          msg.send plugin.apps result, config
        else
          msg.send "No applications with errors."

  robot.respond /(newrelic|nr) ktrans$/i, (msg) ->
    get 'key_transactions.json', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.ktrans json.key_transactions, config

  robot.respond /(newrelic|nr) servers$/i, (msg) ->
    get 'servers.json', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.servers json.servers, config

  robot.respond /(newrelic|nr) users$/i, (msg) ->
    get 'users.json', (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.users json.users, config

  robot.respond /(newrelic|nr) apps name ([\s\S]+)$/i, (msg) ->
    data = encodeURIComponent('filter[name]') + '=' +  encodeURIComponent(msg.match[2])
    post 'applications.json', data, (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.apps json.applications, config

  robot.respond /(newrelic|nr) apps hosts ([0-9]+)$/i, (msg) ->
    get "applications/#{msg.match[2]}/hosts.json", (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.hosts json.application_hosts, config

  robot.respond /(newrelic|nr) apps instances ([0-9]+)$/i, (msg) ->
    get "applications/#{msg.match[2]}/instances.json", (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.instances json.application_instances, config

  robot.respond /(newrelic|nr) ktrans id ([0-9]+)$/i, (msg) ->
    get "key_transactions/#{msg.match[2]}.json", (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.ktran json.key_transaction, config

  robot.respond /(newrelic|nr) servers name ([a-zA-Z0-9\-.]+)$/i, (msg) ->
    data = encodeURIComponent('filter[name]') + '=' +  encodeURIComponent(msg.match[2])
    post 'servers.json', data, (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.servers json.servers, config

  robot.respond /(newrelic|nr) users email ([a-zA-Z0-9.@]+)$/i, (msg) ->
    data = encodeURIComponent('filter[email]') + '=' +  encodeURIComponent(msg.match[2])
    post 'users.json', data, (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        msg.send plugin.users json.users, config

  robot.respond /(newrelic|nr) deployments ([0-9]+)$/i, (msg) ->
    get "applications/#{msg.match[2]}/deployments.json", (err, json) ->
      if err
        msg.send "Failed: #{err.message}"
      else
        opts = Object.assign(
          {},
          config,
          {date_format: robot.brain.get(DATE_FORMAT_KEY)}
        )
        msg.send plugin.deployments json.deployments, opts

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

plugin.deployments = (deployments, opts = {}) ->

  lines = deployments.map (d) ->
    line = []

    line.push d.user
    line.push 'deployed'
    line.push d.revision
    line.push 'on'
    line.push(new Date(d.timestamp).format(opts.date_format))
    line.push "\n\n"
    line.push d.description
    line.push "\n\nCHANGELOG\n"
    line.push d.changelog

    line.join " "

  "#{opts.blockquote}#{lines.join("\n")}"

module.exports = plugin
