# hubot-newrelic2

New Relic stats from hubot

![newrelic servers](https://raw.githubusercontent.com/statianzo/hubot-newrelic2/master/doc/newrelicservers.png)

## Installation

```
npm install --save hubot-newrelic2
```

Add `"hubot-newrelic2"` into your hubot project's `external-scripts.json`

Set `HUBOT_NEWRELIC_API_KEY` to your New Relic API key
Set `HUBOT_NEWRELIC_API_HOST` to `api.newrelic.com` (usually)

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

#### Key Transaction Related Commands

* List all key transactions
```
hubot newrelic ktrans
```

* Filtered list of key transactions
```
hubot newrelic ktrans name <filter_string>
```

#### Server Related Commands

* List all servers
```
hubot newrelic servers
```

* Filtered list of servers
```
hubot newrelic server name <filter_string>
```

#### User Related Commands

* List all users
```
hubot newrelic users
```

* Filtered list of users
```
hubot newrelic user email <filter_string>
```
