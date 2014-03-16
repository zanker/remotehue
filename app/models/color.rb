class Color
  include MongoMapper::EmbeddedDocument

  key :on, Boolean
  key :bri, Integer
  key :transitiontime, Integer, :default => 0

  embedded_in :trigger
  embedded_in :scene

  validates_numericality_of :bri, :greater_than_or_equal_to => HUE_DATA[:bri][:min], :less_than_or_equal_to => HUE_DATA[:bri][:max]
  validates_numericality_of :transitiontime, :greater_than_or_equal_to => 0, :less_than => 36000
end