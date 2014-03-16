require "spec_helper"

describe ScheduleRunner do
  before :all do
    @user = create(:user)
    @time_now = @user.with_time_zone.time_zone
  end

  it "runs a trigger without issue" do
    schedule = create(:schedule, :triggers => [create(:trigger_on)], :user => @user)

    Trigger::On.any_instance.should_receive(:run).once
    described_class.new.perform(@user._id.to_s, schedule._id.to_s)

    TriggerHistory.where(:schedule_id => schedule._id).count.should == 1

    history = TriggerHistory.where(:schedule_id => schedule._id).last
    history.should_not be_nil
    history.results.should == TriggerHistory::OK
    history.trigger_id.should == schedule.trigger_ids.first
    history.secret.should == schedule.triggers.first.secret
    history.from.should == TriggerHistory::SCHEDULE
    history.schedule_id.should == schedule._id
    history.created_at.should be_within(1).of(Time.now.utc)
    history.runtime.should be >= 0

    history = ScheduleHistory.where(:schedule_id => schedule._id).last
    history.should_not be_nil
    history.user_id.should == @user._id
    history.results.should == ScheduleHistory::SUCCESS
    history.created_at.should be_within(1).of(Time.now.utc)
    history.runtime.should be >= 0
    history.trigger_ids.should == schedule.trigger_ids
  end

  it "runs a trigger and logs errors" do
    schedule = create(:schedule, :triggers => [create(:trigger_on)], :user => @user)

    Trigger::On.any_instance.should_receive(:run).and_raise(Exception)

    lambda { described_class.new.perform(@user._id.to_s, schedule._id.to_s) }.should raise_error(Exception)

    history = ScheduleHistory.where(:schedule_id => schedule._id).last
    history.should_not be_nil
    history.user_id.should == @user._id
    history.results.should == ScheduleHistory::ERROR
    history.error_code.should == ScheduleHistory::EXCEPTION_RETRY
    history.created_at.should be_within(1).of(Time.now.utc)
    history.runtime.should be >= 0
  end
end