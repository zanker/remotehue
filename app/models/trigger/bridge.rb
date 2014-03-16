class Trigger::Bridge
  include MongoMapper::EmbeddedDocument

  key :light_ids, Array
  key :group_ids, Array
  belongs_to :bridge

  embedded_in :trigger

  before_save do
    self.light_ids.reject! {|id| !BSON::ObjectId.legal?(id)}
    self.light_ids.map! {|id| id.is_a?(BSON::ObjectId) ? id : BSON::ObjectId(id)}

    self.group_ids.reject! {|id| !BSON::ObjectId.legal?(id)}
    self.group_ids.map! {|id| id.is_a?(BSON::ObjectId) ? id : BSON::ObjectId(id)}
  end

  before_validation do
    if !self.light_ids? and !self.group_ids?
      errors.add(:light_ids, :at_least)
    end
  end
end