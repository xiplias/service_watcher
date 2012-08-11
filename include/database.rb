class Service_watcher::Database
  SCHEMA = {
    "tables" => {
      "Group" => {
        "columns" => [
          {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
          {"name" => "name", "type" => "varchar"}
        ]
      },
      "Group_reporterlink" => {
        "columns" => [
          {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
          {"name" => "group_id", "type" => "int"},
          {"name" => "reporter_id", "type" => "int"}
        ],
        "indexes" => [
          {"name" => "group_id", "columns" => ["group_id"]},
          {"name" => "reporter_id", "columns" => ["reporter_id"]}
        ]
      },
      "Option" => {
        "columns" => [
          {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
          {"name" => "object_class", "type" => "varchar"},
          {"name" => "object_id", "type" => "int"},
          {"name" => "key", "type" => "varchar"},
          {"name" => "value", "type" => "varchar"}
        ],
        "indexes" => [
          {"name" => "object_lookup", "columns" => ["object_class", "object_id"]}
        ]
      },
      "Reporter" => {
        "columns" => [
          {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
          {"name" => "name", "type" => "varchar"},
          {"name" => "plugin", "type" => "varchar"}
        ]
      },
      "Service" => {
        "columns" => [
          {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
          {"name" => "name", "type" => "varchar"},
          {"name" => "plugin", "type" => "varchar"},
          {"name" => "timeout", "type" => "int"},
          {"name" => "date_lastrun", "type" => "datetime"},
          {"name" => "group_id", "type" => "int"},
          {"name" => "failed", "type" => "enum", "maxlength" => "'0','1'", "default" => 0}
        ],
        "indexes" => [
          {"name" => "group_id", "columns" => ["group_id"]}
        ]
      },
      "Service_reporterlink" => {
        "columns" => [
          {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
          {"name" => "service_id", "type" => "int"},
          {"name" => "reporter_id", "type" => "int"}
        ],
        "indexes" => [
          {"name" => "service_id", "columns" => ["service_id"]},
          {"name" => "reporter_id", "columns" => ["reporter_id"]}
        ]
      },
      "User" => {
        "columns" => [
          {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
          {"name" => "username", "type" => "varchar"},
          {"name" => "password", "type" => "varchar", "maxlength" => 160}
        ],
        "on_create_after" => proc{|d|
          d["db"].insert(:User, {"username" => "admin", "password" => Digest::MD5.hexdigest("admin")})
        }
      }
    }
  }
end