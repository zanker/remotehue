class Usercp::HelpController < Usercp::BaseController
  def meethue

  end

  def ifttt
    @trigger = current_user.triggers.where(:_id => params[:trigger_id].to_s).first
    return render_404 unless @trigger
  end
end