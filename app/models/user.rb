class User
  include MongoMapper::Document

  TWELVE, TWENTYFOUR = 0, 1

  key :analytics_id, String
  key :full_name, String
  key :email, String, :format => /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
  key :timezone, String, :default => "PST8PDT"

  key :flags, Hash, :default => {}
  key :limits, Hash, :default => {}

  key :time_mode, Integer, :default => TWELVE

  key :latitude, Float
  key :longitude, Float

  key :oauth, Hash, :default => {}
  key :uid, String, :required => true
  key :provider, String, :required => true
  key :remember_token, String

  key :email_token, :type => String
  key :email_market, :type => Boolean, :default => true

  key :current_sign_in_ip, String
  key :current_sign_in_at, Time
  key :last_sign_in_at, Time

  ensure_index [[:provider, Mongo::ASCENDING], [:uid, Mongo::ASCENDING]]

  timestamps!
  safe

  one :subscription
  many :bridges, :dependent => :destroy
  many :scenes, :dependent => :destroy
  many :triggers, :dependent => :destroy
  many :schedules, :dependent => :destroy
  many :trigger_history, :dependent => :destroy
  many :schedule_history, :dependent => :destroy

  validates_numericality_of :latitude, :minimum => -90, :maximum => 90, :allow_nil => true
  validates_numericality_of :longitude, :minimum => -180, :maximum => 180, :allow_nil => true
  validates_numericality_of :time_mode, :minimum => TWELVE, :maximum => TWENTYFOUR

  def has_feature?(type)
    return true if CONFIG[:subscriptions][:free][:features][type]
    self.subscription ? !!CONFIG[:subscriptions][self.subscription.plan][:features][type] : false
  end

  def feature_limit(type)
    plan = self.subscription ? self.subscription.plan : :free
    CONFIG[:subscriptions][plan][:features][type]
  end

  def with_time_zone(time=Time.now)
    time.in_time_zone(self.timezone)
  end

  def formatted_hour(time, seconds=false)
    if self.time_mode == TWENTYFOUR
      self.with_time_zone(time).strftime(seconds ? "%H:%M:%S" : "%H:%M")
    else
      self.with_time_zone(time).strftime(seconds ? "%I:%M:%S %p" : "%I:%M %p")
    end
  end

  def formatted_time(time, seconds=false)
    if self.time_mode == TWENTYFOUR
      self.with_time_zone(time).strftime(self.time_format(seconds))
    else
      self.with_time_zone(time).strftime(self.time_format(seconds))
    end
  end

  def time_format(seconds=false)
    if self.time_mode == TWENTYFOUR
      "%Y/%m/%d #{seconds ? "%H:%M:%S" : "%H:%M"}"
    else
      "%Y/%m/%d #{seconds ? "%I:%M:%S %p" : "%I:%M %p"}"
    end
  end

  def solar_event_at(type)
    if self.latitude? and self.longitude?
      require Rails.root.join("lib", "solar_event")
      se = SolarEvent.new(Date.today, self.latitude.to_d, self.longitude.to_d)
      self.formatted_hour(se.send("compute_official_#{type == :sunrise ? :sunrise : :sunset}", self.timezone))
    end
  end

  before_create do
    self.email_token = SecureRandom.base64(50).tr("+/=", "Atb")
    self.analytics_id ||= self._id
  end

  before_validation(:if => :timezone_changed?) do
    valid = self.timezone == "PST8PDT"
    ActiveSupport::TimeZone::MAPPING.each do |name, zone|
      if zone == self.timezone
        valid = true
        break
      end
    end

    errors.add(:timezone, :invalid) unless valid
  end
end