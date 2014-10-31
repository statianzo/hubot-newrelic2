module.exports = ->
  {
    "servers": [
      {
        "id": 999,
        "account_id": 123456,
        "name": "web",
        "host": "web.example.com",
        "health_status": "green",
        "reporting": true,
        "last_reported_at": "2014-10-31T16:58:00+00:00"
      },
      {
        "id": 888,
        "account_id": 123456,
        "name": "database",
        "host": "db.example.com",
        "health_status": "red",
        "reporting": false
      }
    ]
  }
