source "https://rubygems.org"

gem "rails", "~>3.2.13"

gem "bcrypt-ruby", "~>3.0.1"

gem "airbrake", "~>3.1.11"

gem "puma", "~>2.0.1"

gem "excon", "~>0.16.0"

gem "newrelic_rpm", "~>3.6.1.88"
gem "newrelic-redis", "~>1.4.0"

gem "statsd-ruby", "~>1.2.0", :require => "statsd"

gem "nori", "~>2.2.0"

#gem "easy-gtalk-bot", "~>1.0.2"
gem "omniauth", "~>1.1.4"
gem "omniauth-google-oauth2", "~>0.1.17"
gem "omniauth-facebook", :git => "git://github.com/mkdynamic/omniauth-facebook.git"

gem "mongo_mapper", :git => "git://github.com/jnunemaker/mongomapper.git"
gem "mongo", "~>1.8.5"

gem "haml", "~>4.0.2"

gem "sidekiq", "~>2.11.2"
gem "rufus-scheduler", "~>2.0.19"

group :assets do
  gem "i18n-js", "~>3.0.0.rc5"

  gem "sprockets", "2.2.2"

  gem "less-rails", "~>2.3.3"
  gem "less", "~>2.3.2"

  gem "sass-rails", "~>3.2.6"
  gem "sass", "~>3.2.0"

  gem "turbo-sprockets-rails3", "~>0.3.6"

  gem "compass", "~>0.12.2"
  gem "compass-rails", "~>1.0.3"

  gem "therubyrhino", "~>2.0.2", :platform => :jruby
  gem "therubyracer", "~>0.11.4", :platform => :ruby
  gem "uglifier", "~>2.0.1"
end

group :development do
  gem "capistrano"
  gem "capistrano_colors"

  gem "rails-dev-tweaks"

  gem "zeus", :platform => :ruby
end

group :test do
  gem "rspec"
  gem "rspec-rails"

  gem "guard"
  gem "guard-rspec"

  gem "factory_girl"
  gem "factory_girl_rails"

  gem "timecop"

  gem "vcr", :git => "git://github.com/vcr/vcr.git"
  gem "webmock", "~>1.10.0"

  gem "rspec-sidekiq"
end
