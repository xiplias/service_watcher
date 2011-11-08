$schema = {
  "tables" => {
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
        {"name" => "plugin", "type" => "varchar"}
      ]
    },
    "User" => {
      "columns" => [
        {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
        {"name" => "username", "type" => "varchar"},
        {"name" => "password", "type" => "varchar", "maxlength" => 160}
      ]
    }
  }
}