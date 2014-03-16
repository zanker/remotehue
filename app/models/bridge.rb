class Bridge
  include MongoMapper::Document

  UNKNOWN, INACTIVE, ACTIVE, UNAUTHORIZED, OFFLINE = 0, 1, 2, 3, 4
  UPDATE_AVAILABLE, UPDATING = 2, 3

  key :api_key, String
  key :meethue_token, String
  key :name, String
  key :bridge_id, String
  key :local_ip, Binary
  key :swversion, String
  key :status, Integer, :default => UNKNOWN
  key :mac, Binary
  key :update_state, Integer, :default => UNKNOWN
  key :last_seen, Time
  key :meethue_updated_at, Time
  key :next_update_at, Time
  key :manually_resynced, Boolean

  key :total_lights, Integer, :default => 0
  key :total_groups, Integer, :default => 0

  belongs_to :user
  many :devices
  many :lights
  many :groups
  many :triggers, :dependent => :destroy
  many :scenes, :dependent => :destroy

  ensure_index [[:user_id, Mongo::ASCENDING]]
  ensure_index [[:next_update_at, Mongo::ASCENDING]]

  timestamps!
  safe

  validates_format_of :api_key, :with => /\A([a-z0-9]{40})\z/
  validates_presence_of :local_ip

  attr_reader :bridge

  def local_ip=(local_ip)
    @local_ip = local_ip.split(".").map {|t| t.to_i}.pack("C*")
  end

  def local_ip_text
    self.local_ip? ? self.local_ip.unpack("C*").map {|t| t.to_i}.join(".") : nil
  end

  def mac=(mac)
    @mac = mac.split(":").map {|t| t.hex}.pack("C*")
  end

  def mac_text
    self.mac? ? self.mac.unpack("C*").map do |t|
      t = t.to_s(16)
      t = "0#{t}" if t.length == 1
      t
    end.join(":") : nil
  end

  def remote_command(command)
    res = Stats.network("meethue.sendmessage") do
      http = Net::HTTP.new("www.meethue.com", 443)
      http.use_ssl = true
      http.request_post("/api/sendmessage?token=#{CGI::escape(self.meethue_token)}", "clipmessage={ bridgeId: \"#{self.bridge_id}\", clipCommand: #{command.to_json}}")
    end

    if res.code == "500"
      body = JSON.parse(res.body)
      if body["code"] == 109
        self.set(:status => UNAUTHORIZED)
      end
    end

    res.code == "200"
  end

  def load_data
    return unless self.valid?

    res = Stats.network("meethue.getbridge") do
      Excon.get("https://www.meethue.com/api/getbridge", :query => {:token => self.meethue_token, :bridgeid => self.bridge_id})
    end

    unless res.status == 200
      return @extract_error = :getbridge
    end

    bridge = JSON.parse(res.body)

    # Store general info
    self.total_lights = bridge["lights"].length
    self.total_groups = bridge["groups"].length
    self.mac = bridge["config"]["mac"]
    self.name = bridge["config"]["name"]
    self.last_seen = Time.parse(bridge["lastHeardFrom"])
    self.swversion = bridge["config"]["swversion"]
    self.update_state = bridge["config"]["swupdate"]["updatestate"].to_i
    self.meethue_updated_at = Time.now.utc

    self.status = bridge["bridgeIsOnline"] ? ACTIVE : OFFLINE

    # Store devices
    active = {}
    self.devices.each {|device| active[device.api_key] = device}

    self.devices = []
    bridge["config"]["whitelist"].each do |api_key, data|
      device = active[api_key] || Device.new(:api_key => api_key)
      device.name = data["name"]
      device.created_at = Time.parse(data["create date"])
      device.last_used_at = Time.parse(data["last use date"])
      device.updated_at = Time.now.utc

      self.devices << device
    end

    # Store lights
    active = {}
    self.lights.each {|light| active[light.light_id] = light}

    self.lights = []

    light_map = {}
    bridge["lights"].each do |id, data|
      id = id.to_i

      light = active[id] || Light.new(:light_id => id)
      light.name = data["name"]
      light.type = data["type"]
      light.model_id = data["modelid"] || "LCT001"
      light.swversion = data["swversion"]
      light.updated_at = Time.now.utc
      light.created_at ||= Time.now.utc

      light_map[id] = light._id
      self.lights << light
    end

    # Store groups
    active = {}
    self.groups.each {|group| active[group.group_id] = group}

    self.groups = []

    group_map = {}
    # Seems to be possible to get a malformed groups that contains just a hash
    # with one group instead. So will try and fix that
    if bridge["groups"]["lights"]
      bridge["groups"] = {"1" => bridge["groups"]}
    end

    bridge["groups"].each do |id, data|
      # This is the remote that we need to skip
      next if data["name"] == /^VRC ([0-9]+)$/
      id = id.to_i

      group = active[id] || Group.new(:group_id => id)

      group.name = data["name"]
      group.updated_at = Time.now.utc
      group.created_at ||= Time.now.utc
      if data["lights"].is_a?(Array)
        group.light_ids = data["lights"].map {|id| light_map[id.to_i]}
      else
        group.light_ids = []
      end

      self.groups << group
    end
  end

  before_validation(:if => :local_ip?) do
    unless self.local_ip_text =~ /\A(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\z/
      errors.add(:local_ip, :invalid)
    end
  end

  before_validation do
    if @extract_error
      errors.add(:bridge, @extract_error)
      @extract_error = nil
    end
  end
end