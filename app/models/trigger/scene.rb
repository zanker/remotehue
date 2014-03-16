class Trigger::Scene < Trigger
  belongs_to :scene

  def run
    self.scene.run
  end
end