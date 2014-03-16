class Light
  include MongoMapper::EmbeddedDocument

  key :light_id, Integer
  key :name, String
  key :swversion, String
  key :model_id, String
  key :base_model, String
  key :type, String

  key :created_at, Time
  key :updated_at, Time

  embedded_in :bridge

  before_update do
    self.base_model = self.model_id.gsub(/[!A-Z]/i, "")
  end

  def color?
    self.model_id =~ /^(LCT|LLC)/
  end

  def allowed_fields
    if self.model_id =~ /^(LWL|LWB)/
      [:bri, :on]
    elsif self.model_id =~ /^LLC/
      [:bri, :on, :colormode, :xy, :hue, :sat]
    elsif self.model_id =~ /^LCT/
      [:bri, :on, :colormode, :xy, :hue, :sat, :ct]
    end
  end
end