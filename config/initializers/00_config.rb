CONFIG = HashWithIndifferentAccess.new(YAML::load(File.read("#{Rails.root}/config/site_config.yml")))[Rails.env]

HUE_DATA = HashWithIndifferentAccess.new(YAML::load(File.read("#{Rails.root}/config/hue.yml")))