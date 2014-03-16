require "spec_helper"

describe SecondaryTrigger do
  before :all do
    @user = create(:user)
  end

  it "queues a schedule that is ready soon" do
    trigger = create(:trigger_on, :user => @user)

    Trigger::On.any_instance.should_receive(:run)
    described_class.new.perform(trigger._id.to_s)

    TriggerHistory.where(:trigger_id => trigger._id, :from => TriggerHistory::SECONDARY).exists?.should be_true
  end
end