require "spec_helper"

describe Schedule do
  before :all do
    @user = create(:user)
    @time_now = @user.with_time_zone.time_zone
  end

  context "start/end dates" do
    it "runs after the start date" do
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6, 3)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::TIME
        schedule.repeats = 1
        schedule.days = [3, 1]
        schedule.run_hour = "6:00 AM"
        schedule.start_at = @time_now.local(2013, 5, 5)

        schedule.calc_next_run.should == Time.parse("Wed, 05 May 2013 06:00:00 -0700")
      end
    end

    it "stops after the end date" do
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6, 3)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::TIME
        schedule.end_at = @time_now.local(2013, 4, 20)

        schedule.calc_next_run.should be_nil
      end
    end
  end

  context "sunrise schedule" do
    it "if it runs today" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6, 3)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::SUNRISE
        schedule.repeats = 1
        schedule.days = [3, 1]

        schedule.calc_next_run.should == Time.parse("Wed, 01 May 2013 06:14:00 -0700")
      end
    end

    it "if it runs today and it's passed" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 8, 6, 3)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::SUNRISE
        schedule.repeats = 1
        schedule.days = [3, 4]

        schedule.calc_next_run.should == Time.parse("Wed, 02 May 2013 06:12:00 -0700")
      end
    end

    it "if it runs today with a sun offset" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::SUNRISE
        schedule.repeats = 1
        schedule.days = [3, 1]
        schedule.sun_offset = -60

        schedule.calc_next_run.should == Time.parse("Wed, 01 May 2013 06:13:00 -0700")
      end
    end

    it "if it runs today with a sun offset that forces it below now" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::SUNRISE
        schedule.repeats = 1
        schedule.days = [3, 1]
        schedule.sun_offset = -3.hours.to_i

        schedule.calc_next_run.should == Time.parse("Wed, 06 May 2013 03:08:00 -0700")
      end
    end

    it "if it runs tomorrow" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::SUNRISE
        schedule.repeats = 1
        schedule.days = [4, 1]

        schedule.calc_next_run.should == Time.parse("Wed, 02 May 2013 06:12:00 -0700")
      end
    end

    it "if it runs later this week" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::SUNRISE
        schedule.repeats = 1
        schedule.days = [1, 7]

        schedule.calc_next_run.should == Time.parse("Wed, 05 May 2013 06:09:00 -0700")
      end
    end

    it "if it runs next week" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::SUNRISE
        schedule.repeats = 1
        schedule.days = [1]

        schedule.calc_next_run.should == Time.parse("Wed, 06 May 2013 06:08:00 -0700")
      end
    end
  end

  context "sunset schedule" do
    it "if it runs today" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6, 3)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::SUNSET
        schedule.repeats = 1
        schedule.days = [3, 1]

        schedule.calc_next_run.should == Time.parse("Wed, 01 May 2013 20:00:00 -0700")
      end
    end

    it "if it runs today but time is past" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 20, 6, 3)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::SUNSET
        schedule.repeats = 1
        schedule.days = [3, 4]

        schedule.calc_next_run.should == Time.parse("Wed, 02 May 2013 20:00:00 -0700")
      end
    end

    it "if it runs today with a sun offset" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::SUNSET
        schedule.repeats = 1
        schedule.days = [3, 1]
        schedule.sun_offset = -60

        schedule.calc_next_run.should == Time.parse("Wed, 01 May 2013 19:59:00 -0700")
      end
    end

    it "if it runs today with a sun offset that forces it below now" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 18, 6)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::SUNSET
        schedule.repeats = 1
        schedule.days = [3, 1]
        schedule.sun_offset = -3.hours.to_i

        schedule.calc_next_run.should == Time.parse("Wed, 06 May 2013 17:04:00 -0700")
      end
    end

    it "if it runs tomorrow" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::SUNSET
        schedule.repeats = 1
        schedule.days = [4, 1]

        schedule.calc_next_run.should == Time.parse("Wed, 02 May 2013 20:00:00 -0700")
      end
    end

    it "if it runs later this week" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::SUNSET
        schedule.repeats = 1
        schedule.days = [1, 7]

        schedule.calc_next_run.should == Time.parse("Wed, 05 May 2013 20:03:00 -0700")
      end
    end

    it "if it runs next week" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::SUNSET
        schedule.repeats = 1
        schedule.days = [1]

        schedule.calc_next_run.should == Time.parse("Wed, 06 May 2013 20:04:00 -0700")
      end
    end
  end

  context "time schedule" do
    it "if it runs today" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6, 3)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::TIME
        schedule.repeats = 1
        schedule.days = [3, 1]
        schedule.run_hour = "9:16 AM"

        schedule.calc_next_run.should == Time.parse("Wed, 01 May 2013 9:16:00 -0700")
      end
    end

    it "if it runs today but time is past" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 20, 6, 3)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::TIME
        schedule.repeats = 1
        schedule.days = [3, 4]
        schedule.run_hour = "2:10 AM"

        schedule.calc_next_run.should == Time.parse("Wed, 02 May 2013 02:10:00 -0700")
      end
    end

    it "if it runs on a day that DST starts but it hasn't yet" do
      Timecop.freeze(@time_now.local(2013, 3, 10, 0, 1)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::TIME
        schedule.repeats = 1
        schedule.days = [7, 1]
        schedule.run_hour = "3:00 AM"

        schedule.calc_next_run.should == Time.parse("Sun, 10 March 2013 03:00:00 -700")
      end
    end

    it "if it runs on a day that DST is running" do
      Timecop.freeze(@time_now.local(2013, 3, 10, 4, 1)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::TIME
        schedule.repeats = 1
        schedule.days = [7, 1]
        schedule.run_hour = "5:00 AM"

        schedule.calc_next_run.should == Time.parse("Sun, 10 March 2013 05:00:00 -700")
      end
    end

    it "if it runs on a day that DST ends but it hasn't yet" do
      Timecop.freeze(@time_now.local(2012, 11, 3, 1, 1)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::TIME
        schedule.repeats = 1
        schedule.days = [6, 1]
        schedule.run_hour = "3:00 AM"

        schedule.calc_next_run.should == Time.parse("Sun, 3 November 2012 03:00:00 -700")
      end
    end

    it "if it runs on a day that DST ended" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2012, 11, 3, 4, 1)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::TIME
        schedule.repeats = 1
        schedule.days = [6, 1]
        schedule.run_hour = "5:00 AM"

        schedule.calc_next_run.should == Time.parse("Sun, 3 November 2012 05:00:00 -700")
      end
    end

    it "if it runs tomorrow" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::TIME
        schedule.repeats = 1
        schedule.days = [4, 1]
        schedule.run_hour = "9:12 PM"

        schedule.calc_next_run.should == Time.parse("Wed, 02 May 2013 21:12:00 -0700")
      end
    end

    it "if it runs later this week" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::TIME
        schedule.repeats = 1
        schedule.days = [1, 7]
        schedule.run_hour = "1:21 AM"

        schedule.calc_next_run.should == Time.parse("Wed, 05 May 2013 01:21:00 -0700")
      end
    end

    it "if it runs next week" do
      # DST is in effect, it's a Wednesday (weekday 3)
      Timecop.freeze(@time_now.local(2013, 5, 1, 5, 6)) do
        schedule = Schedule.new(:user => @user)
        schedule.mode = Schedule::TIME
        schedule.repeats = 1
        schedule.days = [1]
        schedule.run_hour = "1:23 PM"

        schedule.calc_next_run.should == Time.parse("Wed, 06 May 2013 13:23:00 -0700")
      end
    end
  end
end