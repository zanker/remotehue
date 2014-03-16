class SchedulerDispatch
  include Sidekiq::Worker
  sidekiq_options :queue => :critical, :retry => true

  def perform
    Schedule.where(:enabled => true, :next_run_at.lte => 10.minutes.from_now.utc).each do |schedule|
      # If a schedule is more than 10 minutes off, will ignore it and run it next time it's eligible
      # this it to try and stop us from rerunning overdue schedules at 3 AM for people
      overdue = schedule.next_run_at < 10.minutes.ago.utc
      if overdue
        Stats.batch.increment("scheduler.queued/overdue")
        ScheduleHistory.create(:schedule_id => schedule._id, :user_id => schedule.user_id, :results => ScheduleHistory::OVERDUE, :created_at => Time.now.utc)

      else
        Stats.batch.increment("scheduler.queued/#{schedule.mode == Schedule::TIME && "time" || schedule.mode == Schedule::SUNRISE && "sunrise" || "sunset"}")
        ScheduleRunner.perform_at(schedule.next_run_at - 10.seconds, schedule.user_id, schedule._id)
      end

      # Immediately update the schedule assuming it ran so it doesn't double queue
      schedule.last_run_at = Time.now.utc
      schedule.next_run_at = schedule.calc_next_run(Time.now, true)
      schedule.save(:validate => false)
    end
  end
end