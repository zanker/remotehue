class Transaction
  include MongoMapper::EmbeddedDocument

  NEW, CHARGED, CANCELED, FAILED, REFUND = 0, 1, 2, 3, 4

  key :type, Integer
  key :product, String
  key :reference, String
  key :amount, Float, :default => 0.0

  belongs_to :user
end
