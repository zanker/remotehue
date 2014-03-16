if Rails.env.production?
  auth = {:user_name => CONFIG[:mailgun][:username], :password => CONFIG[:mailgun][:password], :domain => "1234", :address => "1234", :port => 587, :authentication => :plain, :enable_starttls_auto => true}

  ActionMailer::Base.add_delivery_method :smtp, Mail::SMTP, auth
  ActionMailer::Base.delivery_method = :smtp

  Mail.defaults do
    delivery_method :smtp, auth
  end
else
  ActionMailer::Base.delivery_method = :test

  Mail.defaults do
    delivery_method :test
  end
end