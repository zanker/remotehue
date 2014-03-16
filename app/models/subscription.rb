class Subscription
  include MongoMapper::EmbeddedDocument

  key :plan, String, :required => true
  key :status, String
  key :cancelable, Boolean
  key :trial, Boolean
  key :next_bill_at, Time
  key :end_at, Time
  key :started_at, Time
end
