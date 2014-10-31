module.exports = ->
  {
    "applications": [
      {
        "id": 888,
        "name": "Ruby App",
        "language": "ruby",
        "health_status": "green",
        "reporting": true,
        "last_reported_at": "2014-10-31T21:02:21+00:00",
        "application_summary": {
          "response_time": 12.5,
          "throughput": 3,
          "error_rate": 0,
          "apdex_target": 3,
          "apdex_score": 1
        },
        "settings": {
          "app_apdex_threshold": 3,
          "end_user_apdex_threshold": 7,
          "enable_real_user_monitoring": false,
          "use_server_side_config": false
        },
        "links": {
          "application_instances": [
            123,
            456
          ],
          "alert_policy": 1000,
          "servers": [
            72727
          ],
          "application_hosts": [
            383838,
            382929
          ]
        }
      },
      {
        "id": 333,
        "name": "Python App",
        "language": "python",
        "health_status": "red",
        "reporting": false,
        "settings": {
          "app_apdex_threshold": 0.5,
          "end_user_apdex_threshold": 7,
          "enable_real_user_monitoring": false,
          "use_server_side_config": false
        },
        "links": {
          "application_instances": [
            38382,
            38383
          ],
          "alert_policy": 38382,
          "servers": [
            838432
          ],
          "application_hosts": [
            287223
          ]
        }
      }
    ]
  }
