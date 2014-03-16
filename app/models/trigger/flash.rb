class Trigger::Flash < Trigger::On
  key :duration, Integer, :default => 0

  def remote_command
    {:alert => self.duration == 0 ? "select" : "lselect"}
  end

  before_validation do
    if self.duration > 0 and !self.color.on
      errors.add(:color, :cant_be_off_multi)
    end
  end
end