class Schedule
  include MongoMapper::Document

  TIME, SUNRISE, SUNSET = 0, 1, 2
  NONE, SUNDOWN, SUNUP = 0, 1, 2

  key :mode, Integer, :default => TIME

  key :name, String

  key :enabled, Boolean, :default => true

  key :repeats, Integer, :default => 1
  key :days, Array, :default => []

  key :sun_offset, Integer, :default => 0

  key :run_hour, String

  key :start_at, Time
  key :end_at, Time

  key :last_run_at, Time
  key :next_run_at, Time

  key :run_unless, Integer, :default => NONE

  key :trigger_ids, Array, :default => []

  ensure_index [[:user_id, Mongo::ASCENDING]]
  ensure_index [[:next_run_at, Mongo::ASCENDING]]

  timestamps!
  safe

  belongs_to :user

  validates_numericality_of :sun_offset, :minimum => -3600, :maximum => 3600, :allow_nil => true
  validates_numericality_of :mode, :minimum => TIME, :maximum => SUNSET
  validates_numericality_of :repeats, :minimum => 1, :maximum => 52
  validates_numericality_of :run_unless, :minimum => NONE, :maximum => SUNUP

  many :triggers, :in => :trigger_ids

  def days_to_next_run(skip_today=nil)
    now = self.user.with_time_zone

    crt_day = now.strftime("%u").to_i

    # Skipping today so the next day is actually tomorrow
    if skip_today
      next_day = crt_day == 7 ? 1 : (crt_day + 1)
    else
      next_day = crt_day
    end

    next_day = self.days.select {|d| d >= next_day}.min

    # We're running next week
    if !next_day
      next_day = self.days.min
      wait_in_days = (next_day + (7 - crt_day))
    else
      wait_in_days = next_day - crt_day
    end

    wait_in_days.days
  end

  def calc_next_run(crt_time=Time.now, skip_today=nil)
    # Schedule has ended, no more runs
    if self.end_at? and self.end_at <= crt_time.utc
      return
    end

    # We haven't started yet, calculate against when we do
    if self.start_at? and self.start_at >= crt_time.utc
      now = self.user.with_time_zone(self.start_at)
    else
      now = self.user.with_time_zone(crt_time)
    end

    wait_in_days = self.days_to_next_run(skip_today)

    # Figure out sunrise or sunset
    if self.mode == SUNRISE or self.mode == SUNSET
      require Rails.root.join("lib", "solar_event")
      se = SolarEvent.new((now + wait_in_days).to_date, self.user.latitude.to_d, self.user.longitude.to_d)
      run_at = se.send(self.mode == SUNRISE ? "compute_official_sunrise" : "compute_official_sunset", self.user.timezone)
      # Any kind of offset the user wants relative to the sun
      run_at += self.sun_offset.seconds
      run_at = run_at.to_time

    # Using Time.parse ensures we don't get messed up by DST
    elsif self.mode == TIME
      run_at = (now + wait_in_days)
      parsed = Time.parse(self.run_hour, run_at)
      run_at = run_at.change(:hour => parsed.hour, :min => parsed.min)
    end

    # The next run is today and it's already passed. Recalculate skipping today
    if wait_in_days == 0 and now >= run_at
      return self.calc_next_run(crt_time, true)
    end

    run_at.utc
  end


  before_validation do
    if self.trigger_ids.length > CONFIG[:limit][:schedule_triggers]
      errors.add(:triggers, :too_many, :limit => CONFIG[:limit][:schedule_triggers])
    end

    if self.start_at? and self.end_at? and self.end_at <= self.start_at
      errors.add(:end_at, :before_start)
    end

    if self.mode == TIME and ( !self.run_hour? or !(Time.parse(self.run_hour) rescue nil) )
      errors.add(:run_hour, :invalid)
    end

    self.days.delete_if {|d| d > 7 or d < 1}
    unless self.days?
      errors.add(:days, :at_least_one)
    end
  end
end