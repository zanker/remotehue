class Notification < ActionMailer::Base
  default(:from => "Support <1234>")

  def trial_will_end(user_id)
    @user = User.where(:_id => user_id).only(:email, :subscription, :stripe_card).first
    return unless @user and @user.subscription and @user.subscription.status == "trialing"

    mail(:to => @user.email, :subject => t("mailer.notification.trial_will_end.subject", :plan => t("js.sub_plans.#{@user.subscription.plan}"))) do |format|
      format.html { render :layout => true }
      format.text { render :layout => true }
    end
  end

  def invoice_payment_succeeded(user_id, data)
    @user = User.where(:_id => user_id).only(:email, :subscription, :stripe_card).first
    return unless @user
    @event_data = data

    mail(:to => @user.email, :subject => t("mailer.notification.invoice_payment_succeeded.subject")) do |format|
      format.html { render :layout => true }
      format.text { render :layout => true }
    end
  end

  def invoice_payment_failed(user_id, data)
    @user = User.where(:_id => user_id).only(:email, :subscription, :stripe_card).first
    return unless @user
    @event_data = data

    mail(:to => @user.email, :subject => t("mailer.notification.invoice_payment_failed.subject")) do |format|
      format.html { render :layout => true }
      format.text { render :layout => true }
    end
  end
end
