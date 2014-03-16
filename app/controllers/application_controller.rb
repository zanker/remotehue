class ApplicationController < ActionController::Base
  before_filter :authenticate_user
  after_filter { Stats.batch.flush }

  protect_from_forgery
  helper_method :current_user, :user_signed_in?, :analytics_id

  if Rails.env.production?
    rescue_from ActionController::RoutingError, :with => :render_404
    rescue_from ActionController::MethodNotAllowed, :with => :render_home
    rescue_from Exception, :with => :handle_exception
  end

  def render_404
    return render "errors/404", :formats => [:html], :status => 404
  end

  protected
  def analytics_id
    if @current_user
      @current_user.analytics_id
    else
      unless cookies.signed[:aid]
        cookies.permanent.signed[:aid] = SecureRandom.hex(12)
      end

      cookies.signed[:aid]
    end
  end

  def require_logged_in
    unless @current_user
      return redirect_to new_session_path(:origin => request.fullpath), :alert => t("page_errors.must_login")
    end
  end

  def require_logged_out
    if @current_user
      return redirect_to websites_path, :alert => t("page_errors.logged_in")
    end
  end

  def authenticate_user
    if session[:user_id] and cookies.signed[:remember_token]
      @current_user = User.where(:_id => session[:user_id].to_s, :remember_token => cookies.signed[:remember_token].to_s).first
    elsif cookies.signed[:remember_token]
      @current_user = User.where(:remember_token => cookies.signed[:remember_token].to_s).first
      # Restart the session
      session[:user_id] = @current_user._id if @current_user
    end

    # Keep track of logins
    if @current_user and ( !@current_user.current_sign_in_at? or @current_user.current_sign_in_at <= 1.hour.ago.utc )
      @current_user.set(:current_sign_in_at => Time.now.utc, :last_sign_in_at => @current_user.current_sign_in_at, :current_sign_in_ip => request.ip)
    end
  end

  def user_signed_in?; !!@current_user end
  def current_user; @current_user end

  private
  def handle_exception(exception)
     notify_airbrake(exception)

     return render "public/500", :formats => [:html], :status => 500, :layout => false
  end
end
