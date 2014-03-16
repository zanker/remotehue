require "spec_helper"

describe SchedulerDispatch do
  before :all do
    @user = create(:user)
    @time_now = @user.with_time_zone.time_zone
  end

  it "queues a schedule that is ready soon" do
    Timecop.freeze(@time_now.local(2013, 5, 7, 5)) do
      future_schedule = create(:schedule, :days => [2, 4], :run_hour => "3:23 PM", :next_run_at => 30.minutes.from_now.utc, :user => @user)
      inactive_schedule = create(:schedule, :enabled => false, :days => [2, 4], :run_hour => "3:23 PM", :next_run_at => 5.minutes.from_now.utc, :user => @user)
      schedule = create(:schedule, :days => [2, 4], :run_hour => "3:23 PM", :next_run_at => 5.minutes.from_now.utc, :user => @user)
      next_run = schedule.next_run_at

      described_class.new.perform

      schedule.reload
      schedule.last_run_at.to_i.should be_within(1).of(Time.now.utc.to_i)
      schedule.next_run_at.should == Time.parse("Thu, 09 May 2013 22:23:00 UTC +00:00")
      @user.with_time_zone(schedule.next_run_at).should == Time.parse("Thu, 09 May 2013 15:23:00 PDT")

      expect(ScheduleRunner).to have_enqueued_job(@user._id.to_s, schedule._id.to_s)
      ScheduleRunner.jobs.should have(1).job

      job = ScheduleRunner.jobs.first
      job["at"].should == (next_run - 10.seconds).to_i
    end
  end
end