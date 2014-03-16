require "spec_helper"

describe Api::TriggerController do
  before :all do
    @user = create(:user)
    @secondary_trigger = create(:trigger_on, :user => @user)
    @trigger = create(:trigger_on, :user => @user, :secondary_trigger => @secondary_trigger, :secondary_delay => 30)
  end

  before :each do
    TriggerHistory.delete_all
  end

  it "activates a trigger" do
    Trigger::On.any_instance.should_receive(:run).once

    put :activate, :user_id => @user._id.to_s, :trigger_id => @trigger.secret
    response.code.should == "204"

    TriggerHistory.where(:trigger_id => @trigger._id, :results => TriggerHistory::OK, :from => TriggerHistory::API).exists?.should be_true

    SecondaryTrigger.jobs.should have(1).job
    job = SecondaryTrigger.jobs.last
    job["args"].first.should == @secondary_trigger._id.to_s
    job["at"].should be_within(2).of((Time.now.utc + @trigger.secondary_delay).to_i)
  end

  it "handles a missing user" do
    Trigger::On.any_instance.should_not_receive(:run).once

    put :activate, :user_id => "foobar", :trigger_id => @trigger.secret
    response.code.should == "400"
    response.body.should == '{"error":"user_not_found"}'
  end

  it "handles a missing trigger" do
    Trigger::On.any_instance.should_not_receive(:run).once

    put :activate, :user_id => @user._id.to_s, :trigger_id => "foobar"
    response.code.should == "400"
    response.body.should == '{"error":"trigger_not_found"}'

    TriggerHistory.where(:results => TriggerHistory::MISSING, :from => TriggerHistory::API).exists?.should be_true
  end
end