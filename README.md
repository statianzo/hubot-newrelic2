# hubot-newrelic2

New Relic stats from hubot

![newrelic servers](https://raw.githubusercontent.com/statianzo/hubot-newrelic2/master/doc/newrelicservers.png)

## Installation


### Charting

* To support the charting feature you now need to install Cairo on the host system. This is the lower-level framework used by node-canvas.
* An Amazon S3 bucket is also utilized to save the dynamically generated charts.

#### OS X

* Install Node (for hubot)

```
$ brew install node
```

* Install Xquartz (for node-canvas)
  * http://xquartz.macosforge.org/landing/

* Install Cairo (for node-canvas)

```
$ brew install pkg-config pixman cairo freetype libpng giflib
```

* Ensure that npm sees everything that we just installed.

```
$ export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:/usr/local/lib/pkgconfig:/opt/X11/lib/pkgconfig
```

#### Others

See: https://github.com/Automattic/node-canvas/wiki

### Node Modules

```
npm install --save hubot-newrelic2
```

### Environment variables

* Add `"hubot-newrelic2"` into your hubot project's `external-scripts.json`
* Add `"hubot-newrelic2": "^0.2.0"` (or other version) into your `package.json`
* Set `HUBOT_NEWRELIC_API_KEY` to your New Relic API key
* Set `HUBOT_NEWRELIC_API_HOST` to `api.newrelic.com` (usually)
* Set `HUBOT_AWS_KEY` to a valid AWS key
* Set `HUBOT_AWS_SECRET` to the AWS secret for your AWS key
* Set `HUBOT_AWS_S3_BUCKET` to an S3 bucket that your key can write to and the world can read from.
* Set `HUBOT_NEWRELIC_URL` to New Relic's main UI address; ie. `https://newrelic.com`

## Usage

*Note*: You can replace 'newrelic' with 'nr' in all these commands.

* List all commands
```
hubot newrelic help
```

#### Application Related Commands

* List all applications
```
hubot newrelic apps
```

* Filtered list of applications
```
hubot newrelic apps name <filter_string>
```

* List of single application's instances
```
hubot newrelic apps instances <app_id>
```

* List of single application's hosts
```
hubot newrelic apps hosts <app_id>
```

* Returns a list of one application's metric names
```
hubot newrelic apps metrics <app_id>
```

* Returns a filtered list of metric names and all valid types
```
hubot newrelic apps metrics <app_id> name <filter_string>
```

* Returns a chart for the metric/type based on the last 30 minutes of data
```
hubot newrelic apps metrics <app_id> graph <metric_name> <metric_type>
```

* 'Shorthand' app graph functionality 
```
hubot newrelic apps <app_id||"filter string"> graph rpm
hubot newrelic apps <app_id||"filter string"> graph errors
# Both '/nr apps 12345 graph rpm' and '/nr apps "Some App" graph rpm' are valid
```

#### Key Transaction Related Commands

* List of all key transactions
```
hubot newrelic ktrans
```

* Returns a single key transaction
```
hubot newrelic ktrans id <ktrans_id>
```

#### Server Related Commands

* List all servers
```
hubot newrelic servers
```

* Filtered list of servers
```
hubot newrelic servers name <filter_string>
```

* Returns a list of one server's metric names
```
hubot newrelic servers metrics <app_id>
```

* Returns a filtered list of metric names and all valid types
```
hubot newrelic servers metrics <app_id> name <filter_string>
```

* Returns a graph for the metric/type based on the last 30 minutes of data
```
hubot newrelic servers metrics <app_id||filter_string> graph <metric_name> <metric_type>
```
** NOTE: If specifying a filter and more than 1 result is returned, the bot will echo the list of all matched servers and ask for you to clarify which server you meant to query

* 'Shorthand' graph functionality
```
hubot newrelic servers <app_id||filter_string> graph load
hubot newrelic servers <app_id||filter_string> graph cpu
hubot newrelic servers <app_id||filter_string> graph mem||memory
hubot newrelic servers <app_id||filter_string> graph net||network
hubot newrelic servers <app_id||filter_string> graph disk
```


#### User Related Commands

* List all account users
```
hubot newrelic users
```

* Filtered list of account users
```
hubot newrelic user email <filter_string>
```
