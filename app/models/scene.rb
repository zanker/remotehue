class Scene
  include MongoMapper::Document

  PHILIPS, CUSTOM = 0, 1

  key :source, Integer, :default => CUSTOM
  key :last_mod, Time
  key :name, String
  key :sid, Integer
  key :image_path, String
  key :light_state, Array, :default => []
  # Unknown, probably internal ID (defaultSID)
  key :meethue_id, Integer

  belongs_to :bridge
  belongs_to :user

  many :devices

  ensure_index [[:user_id, Mongo::ASCENDING], [:bridge_id, Mongo::ASCENDING]]
end