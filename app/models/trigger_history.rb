class TriggerHistory
  include MongoMapper::Document

  OK, MISSING, OVERLIMIT, EXCEPTION = 0, 1, 2
  MAILGUN, API, SCHEDULE, SECONDARY, IFTTT = 0, 1, 2, 3, 4

  key :results, Integer, :default => OK
  key :secret, String
  key :runtime, Float, :default => 0
  key :created_at, Time
  key :from, Integer

  belongs_to :trigger
  belongs_to :schedule
  belongs_to :user
end