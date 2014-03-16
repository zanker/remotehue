type = ENV["SERVER_TYPE"] == "primary" ? :primary : :secondary

pidfile "/var/run/puma/remotehue-#{type}.pid"
state_path "/var/run/puma/remotehue-#{type}.yml"

stdout_redirect "/var/log/puma/remotehue-#{type}-out", "/var/log/puma/remotehue-#{type}-err", true

bind "tcp://0.0.0.0:#{type == :primary ? "8100" : "8200"}"

rackup "/var/www/vhosts/remotehue/current/config.ru"

threads 8, 12