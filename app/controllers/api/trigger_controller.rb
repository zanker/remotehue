class Api::TriggerController < Api::BaseController
  def activate
    res, type = activate_trigger(:api, params[:user_id].to_s, params[:trigger_id].to_s)
    if res == 201
      render :nothing => true, :status => :no_content
    else
      render_error(type)
    end
  end
end