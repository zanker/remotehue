class Usercp::SettingsController < Usercp::BaseController
  def index

  end

  def edit

  end

  def update
    user = User.where(:_id => current_user._id).first
    user.full_name = params[:full_name].to_s
    user.email = params[:email].to_s
    user.timezone = params[:timezone].to_s
    user.time_mode = params[:time_mode].to_i
    user.latitude = params[:latitude].to_f
    user.longitude = params[:longitude].to_f
    user.email_market = params[:email_market] != "false"

    if user.valid?
      flash[:success] = t("usercp.settings.edit.settings_updated")
    end

    user.save
    respond_with_model(user)
  end


  def inline_location
    current_user.latitude = params[:latitude].to_f
    current_user.longitude = params[:longitude].to_f
    current_user.save

    solar_events
  end

  def solar_events
    require Rails.root.join("lib", "solar_event")
    se = SolarEvent.new(Date.today, params[:latitude].to_f.to_d, params[:longitude].to_f.to_d)
    sunrise = se.send("compute_official_sunrise", current_user.timezone)
    sunset = se.send("compute_official_sunset", current_user.timezone)

    render :json => {:sunrise => current_user.formatted_hour(sunrise, false), :sunset => current_user.formatted_hour(sunset, false), :timezone => current_user.with_time_zone.zone}
  end
end