class Usercp::BridgesController < Usercp::BaseController
  def new
    @bridge = Bridge.new
    @bridge.api_key = Digest::SHA1.hexdigest("#{current_user._id}#{CONFIG[:bridge_secret]}#{current_user.created_at}")

    render :manage
  end

  def edit
    @bridge = Bridge.where(:_id => params[:id].to_s, :user_id => current_user._id).first
    return render_404 unless @bridge

    render :manage
  end

  def update
    bridge = Bridge.where(:_id => params[:id].to_s, :user_id => current_user._id).first
    return render_404 unless bridge

    bridge.api_key = params[:api_key].to_s
    bridge.local_ip = params[:ip].to_s
    bridge.save

    respond_with_model(bridge)
  end

  def resync
    bridge = Bridge.where(:_id => params[:id].to_s, :user_id => current_user._id).first
    return render_404 unless bridge

    unless bridge.manually_resynced?
      bridge.load_data
      bridge.save

      bridge.set(:manually_resynced => true)

      flash[:success] = t("usercp.bridges.index.bridge_resynced", :name => bridge.name)
    end

    render :nothing => true, :status => :no_content
  end

  def meethue_check
    bridge = Bridge.where(:_id => params[:id].to_s, :user_id => current_user._id).first
    return render_404 unless bridge

    bridge.load_data
    bridge.save
    flash[:success] = t("usercp.bridges.manage.bridge_saved", :name => bridge.name) if bridge.errors.empty?

    respond_with_model(bridge)
  end

  def meethue_login
    if params[:id]
      bridge = Bridge.where(:_id => params[:id].to_s, :user_id => current_user._id).first
      return render_404 unless bridge
    else
      bridge = Bridge.new
      bridge.user = current_user
      bridge.api_key = params[:api_key].to_s
      bridge.local_ip = params[:ip].to_s
    end

    email, password = params[:email].to_s.strip, params[:password].to_s.strip
    bridge_id = params[:bridge_id].to_s.strip
    if email.blank? or password.blank? or bridge_id !~ /\A[a-z0-9]+\z/
      return render_404
    end

    # Get our session
    res = Stats.network("meethue.gettoken") do
      Excon.get("https://www.meethue.com/en-US/api/gettoken?devicename=Remote+Hue&appid=hueapp&deviceid=#{bridge.api_key}", :headers => {"User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.65 Safari/537.36"})
    end
    cookie = res.headers["Set-Cookie"]
    unless cookie.match(/PLAY_SESSION="(.+)"/)
      return render :json => {:error => "session"}, :status => :bad_request
    end

    # Login as the user
    last_url = "https://www.meethue.com/en-US/api/gettoken?devicename=Remote+Hue&appid=hueapp&deviceid=#{bridge.api_key}"
    res = Stats.network("meethue.getaccesstoken") do
      Excon.post("https://www.meethue.com/en-US/api/getaccesstokengivepermission", :headers => {"Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8", "Cookie" => "PLAY_SESSION=\"#{$1}\"", "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.65 Safari/537.36", :"Referer" => last_url}, :body => {:email => email, :password => password}.to_query)
    end
    if res.status == 302
      if res.headers["Set-Cookie"] =~ /PLAY_FLASH="(.+)"/
        return render :json => {:error => $1 =~ /authentication/i ? "auth" : "unknown0"}, :status => :bad_request
      else
        return render :json => {:error => "unknown1"}, :status => :bad_request
      end

    elsif res.status != 200 or res.body !~ /requesting access/i
      return render :json => {:error => "unknown2"}, :status => :bad_request
    end

    # Get any updated session info
    cookie = res.headers["Set-Cookie"]
    unless cookie.match(/PLAY_SESSION="(.+)"/)
      return render :json => {:error => "session"}, :status => :bad_request
    end

    # Now do the last bit of confirmation that we confirm
    last_url = "https://www.meethue.com/en-US/api/getaccesstokengivepermission"
    res = Stats.network("meethue.getaccesstokenpost") do
      Excon.get("https://www.meethue.com/en-US/api/getaccesstokenpost", :headers => {:"Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8", "Cookie" => "PLAY_SESSION=\"#{$1}\"", :"Referer" => last_url, :"User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/27.0.1453.65 Safari/537.36"})
    end
    if res.status == 200
      if res.body =~ %r{phhueapp://sdk/login/([a-zA-Z0-9/=\+]+)}
        current_user.set(:pending_token => $1)

        bridge.bridge_id = bridge_id
        bridge.meethue_token = $1
        bridge.load_data
        bridge.next_update_at = Time.now.utc + rand(4).hours
        bridge.save

        current_user.unset(:pending_token)

        flash[:success] = t("usercp.bridges.manage.#{!params[:id] ? "bridge_created" : "bridge_saved"}", :name => bridge.name) if bridge.errors.empty?
        respond_with_model(bridge, :created)
      else
        return render :json => {:error => "unknown3"}, :status => :bad_request
      end
    else
      return render :json => {:error => "unknown4"}, :status => :bad_request
    end
  end

  def index
    @bridges = current_user.bridges.sort_by {|b| b.name}

  end

  def update_software

  end

  def confirm_destroy

  end

  private
end