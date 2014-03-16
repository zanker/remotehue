class InternalController < ApplicationController
  skip_before_filter :authenticate_user
  newrelic_ignore

  def ping
    render :text => "pong"
  end

  def state
    render :text => "0,#{DEPLOY_ID}"
  end
end