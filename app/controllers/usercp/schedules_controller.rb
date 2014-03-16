class Usercp::SchedulesController < Usercp::BaseController
  def index
    @schedules = current_user.schedules.sort_by {|t| t.name}
  end

  def new
    @schedule = Schedule.new
    @has_location = current_user.latitude? && current_user.longitude?

    render :manage
  end

  def create
    manage_schedule(Schedule.new(:user => current_user))
  end

  def history
    @schedule = current_user.schedules.where(:_id => params[:id].to_s).only(:name).first
    return render_404 unless @schedule

    @history = current_user.schedule_history.where(:schedule_id => @schedule._id).sort(:_id.desc).map {|h| h}
    render :layout => false
  end

  def edit
    @schedule = current_user.schedules.where(:_id => params[:id].to_s).first
    return render_404 unless @schedule
    @has_location = current_user.latitude? && current_user.longitude?

    render :manage
  end

  def update
    schedule = current_user.schedules.where(:_id => params[:id].to_s).first
    return render_404 unless schedule
    manage_schedule(schedule)
  end

  def destroy
    schedule = current_user.schedules.where(:_id => params[:id].to_s).first
    if schedule
      schedule.destroy
    end

    render :nothing => true, :status => :no_content
  end

  private
  def manage_schedule(schedule)
    schedule.name = params[:name].to_s
    schedule.enabled = params[:enabled] == "true"
    schedule.mode = case params[:type]
      when "sunset" then Schedule::SUNSET
      when "sunrise" then Schedule::SUNRISE
      else Schedule::TIME
    end
    schedule.days = []

    if params[:days].is_a?(Array)
      params[:days].each do |day|
        day = day.to_i

        schedule.days.push(day) if day >= 1 and day <= 7
      end
    end

    if params[:trigger_ids].is_a?(Array)
      ids = params[:trigger_ids].select {|id| BSON::ObjectId.legal?(id)}
      schedule.trigger_ids = current_user.triggers.where(:_id.in => ids).only(:_id).map do |trigger|
        trigger._id
      end

    else
      schedule.trigger_ids = []
    end

    schedule.run_unless = params[:run_unless].to_i

    if schedule.mode == Schedule::TIME
      schedule.run_hour = params[:run_hour].to_s.gsub(/[^\sapm0-9:]+/i, "")
    elsif schedule.mode == Schedule::SUNRISE
      schedule.sun_offset = params[:sun_offset].to_i
    elsif schedule.mode == Schedule::SUNSET
      schedule.sun_offset = params[:sun_offset].to_i
    end

    if schedule.valid?
      schedule.next_run_at = schedule.calc_next_run
    end
    schedule.save

    if schedule.errors.empty? and schedule.next_run_at <= 10.minutes.from_now.utc
      SchedulerDispatch.perform_async
    end

    if schedule.errors.empty?
      flash[:success] = t("usercp.schedules.manage.schedule_#{params[:action] == "create" ? "created" : "updated"}", :name => schedule.name)
    end

    respond_with_model(schedule)
  end
end