# General
set :normalize_asset_timestamps, false

# Colorizing
require "capistrano_colors"
Capistrano::Logger.add_color_matcher({:match => /\**.*/, :color => :magenta, :level => 1, :prio => -10})
Capistrano::Logger.add_color_matcher({:match => /\*\**.*/, :color => :red, :level => 0, :prio => -10})

# Set the Ruby to use
set :default_shell, "rvm-shell 'jruby-1.7.2'"

# Directory to put the files into
set :application, "remotehue"

# Keep the last 5 deploys
set :keep_releases, 5
after "deploy:update", "deploy:cleanup"

# Bundler config
set :bundle_without, [:development, :test]
set :bundle_flags, "--deployment --quiet"

# Git setup
set :repository, "file:///repos/remotehue"
set :local_repository, "file://."
set :scm, "git"
set :user, "cap-deploy"

set :branch, "master"

# Server config
set :deploy_to, "/var/www/vhosts/remotehue"
set :use_sudo, false

# Server definition
server "remotehue.com", :web, :app

# Trigger newrelic deployment
require "newrelic_rpm"
after "deploy:update", "newrelic:notice_deployment"

# Puma restart
before "deploy:update_code", "deploy:prepare"

namespace :deploy do
  task :prepare, :except => {:no_release => true} do
    # Not using right now, our equivalent to USR1
    #run "kill -TTOU /var/www/vhosts/remotehue/shared/pids/sidekiq.pid"
  end

  task :restart, :except => {:no_release => true} do
    parallel(:pty => true) do |session|
      session.when "in?(:web)", "sudo puma_zdt_restart remotehue"
      session.when "in?(:app)", "cd #{latest_release}; bundle exec sidekiqctl stop /var/www/vhosts/remotehue/shared/pids/sidekiq.pid 60; nohup bundle exec sidekiq -e production -C /var/www/vhosts/remotehue/current/config/sidekiq.yml -i 0 -P /var/www/vhosts/remotehue/shared/pids/sidekiq.pid >> /var/www/vhosts/remotehue/current/log/sidekiq.log 2>&1 &"
    end
  end
end
