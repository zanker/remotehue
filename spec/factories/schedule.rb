FactoryGirl.define do
  factory :schedule do
    run_hour "3:00 AM"
    days { [1] }
  end
end