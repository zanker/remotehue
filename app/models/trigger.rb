class Trigger
  include MongoMapper::Document

  key :name, String
  key :secret, String
  key :secondary_delay, Integer, :default => 0

  timestamps!
  safe

  belongs_to :secondary_trigger, :class_name => "Trigger"
  belongs_to :user

  ensure_index [[:user_id, Mongo::ASCENDING]]

  validates_length_of :name, :minimum => 1, :maximum => 20
  validates_numericality_of :secondary_delay, :minimum => 15, :maximum => 600, :allow_nil => true

  before_create :generate_secret

  def generate_secret
    self.secret = SecureRandom.hex(10)
  end

  def regenerate_secret!
    self.generate_secret
    self.save(:validate => false)
  end

  def mail_tag
    "RemoteHue:#{self.user_id}:#{self.secret}"
  end

  def run_with_log(from, args={})
    history = TriggerHistory.new(args.merge(:user_id => self.user_id, :trigger_id => self._id, :secret => self.secret, :from => from, :created_at => Time.now.utc))
    start = Time.now.to_f

    self.run
    history.results = TriggerHistory::OK

  rescue Exception => e
    history.results = TriggerHistory::EXCEPTION

    raise

  ensure
    history.runtime = Time.now.to_f - start
    history.save
  end

  # MM doesn't handle polymorphic callbacks apparently
  before_save do
    if self.respond_to?(:bridges)
      self.bridges.each {|b| b.run_callbacks(:save)}
    end

    if self.respond_to?(:color)
      self.color.run_callbacks(:save)
    end
  end

  before_validation(:if => lambda {|r| r.respond_to?(:bridges)}) do
    errors.add(:bridges, :at_least) if self.bridges.empty?
  end

  before_validation(:if => lambda {|r| r.respond_to?(:color)}) do
    errors.add(:color, :set) unless self.color?
  end
end