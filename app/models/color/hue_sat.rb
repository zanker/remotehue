class Color::HueSat < Color
  key :hue, Integer
  key :sat, Integer

  validates_numericality_of :hue, :greater_than_or_equal_to => HUE_DATA[:hue][:min], :less_than_or_equal_to => HUE_DATA[:hue][:max]
  validates_numericality_of :sat, :greater_than_or_equal_to => HUE_DATA[:sat][:min], :less_than_or_equal_to => HUE_DATA[:sat][:max]
end