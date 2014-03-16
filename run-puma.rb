require "rubygems"

begin
  require "./lib/monkeypatches/jruby_gc.rb"
  GC::Profiler.enable

  # Run puma
  require "bundler/setup"
  require "puma/cli"

  # Puma will parse the options when run is called
  cli = Puma::CLI.new(%w{-C config/puma.rb -e production})
  cli.parse_options
  cli.write_pid

  # While ugly, this is the easiest way of resetting Puma state so it doesn't double parse config
  # and try to bind to the same port twice
  cli = Puma::CLI.new(%w{-C config/puma.rb -e production})

  # Puma doesn't support signals to reopen FD by default
  trap("HUP") do
    cli.redirect_io
    cli.log "Logs rotated"
  end

  cli.run

  cli.delete_pidfile

rescue SystemExit, SignalException
rescue Exception => e
  puts "#{e.class}: #{e.message}"
  puts e.backtrace.join("\n")

  require "airbrake"
  require "config/initializers/airbrake"

  res = Airbrake.notify_or_ignore(e, {:parameters => {}, :session_data => {}, :controller => "internal", :action => "script", :url => "", :cgi_data => {}})
  sleep 5
  puts "Logger response #{res}"

ensure
  if defined?(::NewRelic)
    ::NewRelic::Agent.shutdown
  end
end