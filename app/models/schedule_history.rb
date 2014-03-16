class ScheduleHistory
  include MongoMapper::Document

  SUCCESS, ERROR, OVERDUE = 0, 1, 2
  EXCEPTION_RETRY, EXCEPTION_LIMIT = 0, 1

  key :results, Integer, :default => SUCCESS
  key :error_code, Integer
  key :runtime, Float, :default => 0
  key :created_at, Time
  key :trigger_ids, Array

  belongs_to :user
  belongs_to :schedule

  ensure_index [[:user_id, Mongo::ASCENDING], [:schedule_id, Mongo::ASCENDING]]
end