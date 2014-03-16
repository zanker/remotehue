FactoryGirl.define do
  factory :bridge do
    api_key Digest::SHA1.hexdigest("")
    local_ip "192.168.1.100"
  end
end