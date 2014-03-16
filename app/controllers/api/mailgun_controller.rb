class Api::MailgunController < Api::BaseController
  before_filter do
    if params[:secret] != CONFIG[:mailgun_secret]
      return render :status => :bad_request
    end
  end

  def trigger
    unless params["body-plain"] =~ /^(RemoteHue:)?([a-z0-9]{24}):([a-z0-9]+)/i
      Stats.batch.increment("api.triggers/malformed")
      Stats.batch.increment("api.mailgun/malformed")
      return render :nothing => true
    end

    body = params["body-plain"].to_s.gsub(/RemoteHue:/i, "")
    user_id, trigger_id = body.split("\r\n", 2).first.to_s.split(":", 2)

    code, type = activate_trigger(:ifttt, user_id, trigger_id)

    Stats.batch.increment("api.mailgun/#{code == 201 ? "success" : type}")
    render :nothing => true
  end
end