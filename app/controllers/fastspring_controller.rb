class FastspringController < ApplicationController
  before_filter do
    if params[:secret] != CONFIG[:fastspring_secret]
      return render_404
    end

    if Digest::MD5.hexdigest("#{params[:security_data]}#{CONFIG[:fastspring_keys][params[:action]]}") != params[:security_hash]
      return render_404
    end
  end

  # Called when a subscription is initially activated
  def sub_activated
    update_subscription(:new, :id => params[:SubscriptionReferrer], :price => params[:SubscriptionPrice], :reference => params[:SubscriptionReference])
    render :nothing => true, :status => :no_content
  end

  # Called when a subscription is officially canceled and they should lose the subscription
  def sub_canceled
    update_subscription(:cancel, :id => params[:SubscriptionReferrer], :reference => params[:SubscriptionReference])
    render :nothing => true, :status => :no_content
  end

  # Called when a subscription changes with an end date in mind or perhaps none
  def sub_changed
    update_subscription(:changed, :id => params[:SubscriptionReferrer], :reference => params[:SubscriptionReference])
    render :nothing => true, :status => :no_content
  end

  # Called when billing failed
  def sub_failed
    update_subscription(:failed, :id => params[:SubscriptionReferrer], :reference => params[:SubscriptionReference])
    render :nothing => true, :status => :no_content
  end

  # Subscription refunded
  def sub_refund
    update_subscription(:refund, :id => params[:Reference], :price => params[:TotalUsd].to_f, :reference => params[:Id])

    render :nothing => true, :status => :no_content
  end

  def order_notification
    update_subscription(:charged, :id => params[:OrderReferrer], :price => params[:OrderTotalUSD].to_f, :reference => params[:OrderID])

    render :nothing => true, :status => :no_content
  end

  private
  def update_subscription(type, args)
    user = User.find(args[:id])

    if args[:reference] =~ /S$/

      # Pull down data from FastSpring
      res = Excon.get("https://api.fastspring.com/company/1234/subscription/#{args[:reference]}?user=api&pass=1234")
      unless res.status == 200
        raise "Bad response #{res.status}, #{res.body}"
      end

      res = Nori.parse(res.body)

      user.build_subscription unless user.subscription
      user.subscription.plan = res["subscription"]["productName"] == "Premium" ? :premium : :starter
      user.subscription.cancelable = res["subscription"]["cancelable"]

      # They are on the trial period right now
      if !user.subscription.trial? and !user.subscription.next_bill_at? and !user.subscription.end_at?
        user.subscription.trial = true
      end

      if res["subscription"]["nextPeriodDate"]
        user.subscription.next_bill_at = res["subscription"]["nextPeriodDate"].to_time
        user.subscription.end_at = nil

      elsif res["subscription"]["end"]
        user.subscription.end_at = res["subscription"]["end"].to_time
        user.subscription.next_bill_at = nil
      end

      if res["subscription"]["status"] == "inactive"
        user.subscription = nil
      end

      user.save(:validate => false)
    end

    unless type == :changed
      trans = Transaction.new
      tarns.user = user

      trans.type = case type
        when :new then Transaction::NEW
        when :cancel then Transaction::CANCELED
        when :failed then Transaction::FAILED
        when :refund then Transaction::REFUND
        when :charged then Transaction::CHARGED
      end

      trans.amount = params[:price]
      trans.reference = args[:reference]
      trans.product = product
      tarns.save
    end

  end
end