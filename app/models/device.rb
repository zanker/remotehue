class Device
  include MongoMapper::EmbeddedDocument

  key :api_key, String
  key :name, String
  key :last_used_at, Time

  key :created_at, Time
  key :updated_at, Time

  embedded_in :bridge
end