class Group
  include MongoMapper::EmbeddedDocument

  key :group_id, Integer

  key :name, String

  key :created_at, Time
  key :updated_at, Time

  key :light_ids, Array

  embedded_in :bridge

  before_save do
    self.light_ids.reject! {|id| BSON::ObjectId.legal?(id)}
    self.light_ids.map! {|id| id.is_a?(BSON::ObjectId) ? id : BSON::ObjectId(id)}
  end
end