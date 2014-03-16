class Color::Temperature < Color
  key :ct, Integer

  validates_numericality_of :ct, :greater_than_or_equal_to => HUE_DATA[:ct][:min], :less_than_or_equal_to => HUE_DATA[:ct][:max]
end