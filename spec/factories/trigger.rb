FactoryGirl.define do
  factory :trigger do
    name "Foo Bar"

    factory :trigger_on, :class => Trigger::On do
      color { build(:color) }
      bridges { [build(:trigger_bridge)] }
    end
  end

  factory :trigger_bridge, :class => Trigger::Bridge do
    light_ids [1]
    bridge { create(:bridge) }
  end
end