[
  {
    "schema": {
      "dataSource": "dataSourceName",
      "aggregators": 
      [
        {
          "type": "count",
          "name": "name"
        }
      ],
      "indexGranularity": "minute",
      "shardSpec": 
      {
        "type": "none"
      }
    },
    "config": 
    {
      "maxRowsInMemory": 500000,
      "intermediatePersistPeriod": "PT10m"
    },
    "firehose": 
    {
        "type"    : "local",
        "filter"   : "*.json",
        "parser" : 
        {
          "timestampSpec": 
          {
            "column": "timestamp",
            "format": "yyyy-MM-dd HH:mm:ss"
          },
          "data": 
          {
            "format": "json",
            "columns": 
            [
              "name"
            ],
            "dimensions": 
            [
              "name"
            ]
          }
        }
    },
    "plumber": 
    {
      "type": "realtime",
      "windowPeriod": "PT10m",
      "segmentGranularity": "hour",
      "basePersistDirectory": "\/tmp\/realtime\/basePersist"
    }
  }
]
