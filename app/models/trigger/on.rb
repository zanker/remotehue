class Trigger::On < Trigger
  one :color
  one :fallback_color, :class_name => "Color"

  many :bridges, :class_name => "Trigger::Bridge"

  validates_associated :bridges
  validates_associated :color
  validates_associated :fallback_color

  MAX_QUEUED = 2

  def run
    # Base state
    command = self.color.serializable_hash(:except => [:_type, :id])
    if self.respond_to?(:remote_command)
      command.merge!(self.remote_command)
    end

    command = command.to_json

    # Push it all into a list of the commands to run
    states = {}
    self.bridges.each do |data|
      bridge = ::Bridge.where(:_id => data.bridge_id).only("bridge_id", "meethue_token", "lights._id", "lights.light_id", "groups._id", "groups.group_id").first
      states[bridge] ||= []

      if data.light_ids?
        bridge.lights.each do |light|
          if data.light_ids.include?(light._id)
            states[bridge].push(:url => "/api/0/lights/#{light.light_id}/state", :method => "PUT", :body => command)
          end
        end
      end

      if data.group_ids?
        bridge.groups.each do |group|
          if data.group_ids.include?(group._id)
            states[bridge].push(:url => "/api/0/groups/#{group.group_id}/action", :method => "PUT", :body => command)
          end
        end
      end
    end

    # And start dispatching
    bridge_threads = states.map do |b, s|
      Thread.new(b, s) do |b2, states|
        master_threads = []
        offset = 0
        while states[offset] do
          threads = []
          MAX_QUEUED.times do |i|
            next unless states[offset + i]
            t = Thread.new(b2, states[offset + i]) {|bridge, state| bridge.remote_command(state)}
            master_threads << t
            threads << t
          end

          completed = 0
          threads.each do |t|
            t.join
            completed += 1
            break if completed >= MAX_QUEUED
          end

          offset += MAX_QUEUED
        end

        master_threads.each {|t| t.join if t.alive?}
      end
    end

    bridge_threads.each {|t| t.join if t.alive?}
  end

  before_validation(:if => lambda {|r| r.instance_of?(Trigger::On)}) do
    if self.color.bri <= 0 or !self.color.on?
      errors.add(:color, :cant_be_off)
    end
  end
end