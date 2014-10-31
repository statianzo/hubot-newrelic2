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
        "summary": {
          "cpu": 2.07,
          "cpu_stolen": 0,
          "disk_io": 0.03,
          "memory": 22.3,
          "memory_used": 232783872,
          "memory_total": 1042284544,
          "fullest_disk": 22,
          "fullest_disk_free": 24047000000
        }
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
