class Api::BaseController < ApplicationController
  skip_before_filter :authenticate_user

  if Rails.env.production?
    rescue_from ActionController::RoutingError, :with => :render_404
    rescue_from ActionController::MethodNotAllowed, :with => :render_home
    rescue_from Exception, :with => :handle_exception
  end

  def activate_trigger(type, user_id, trigger_secret)
    user = User.where(:_id => user_id).only(:_id).first
    unless user
      Stats.batch.increment("api.triggers/user.missing")
      return 400, "user_not_found"
    end

    trigger = Trigger.where(:user_id => user._id, :secret => trigger_secret).first
    unless trigger
      TriggerHistory.create(:user_id => user._id, :results => TriggerHistory::MISSING, :secret => trigger_secret, :from => type == :ifttt ? TriggerHistory::IFTTT : TriggerHistory::API)
      Stats.batch.increment("api.triggers/trigger.missing")
      return 400, "trigger_not_found"
    end

    start = Time.now.to_f
    trigger.run_with_log(type == :ifttt ? TriggerHistory::IFTTT : TriggerHistory::API)

    Stats.batch.increment("api.triggers/#{type}")

    if trigger.secondary_trigger_id?
      SecondaryTrigger.perform_in(trigger.secondary_delay, trigger.secondary_trigger_id)
    end

    return 201, ""
  end

  def render_404
    return render :json => {:error => "page_not_found"}, :status => 404, :layout => false
  end

  def render_error(error)
    return render :json => {:error => error}, :status => 400, :layout => false
  end

  def handle_exception(exception)
    notify_airbrake(exception)

    return render :json => {:error => "server_error"}, :status => 500, :layout => false
  end
end
