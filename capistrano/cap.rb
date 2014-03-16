Capistrano::Configuration.instance(:must_exist).load do
  before "deploy" do
    logger.info "Pushing git repo for branch #{branch}"
    run_locally(source.scm("push", "origin", branch))

    #next if ENV["RSPEC"] == "0"
    #
    #logger.info "Running tests"
    #
    #results = system("rspec ./")
    #unless results
    #  raise Capistrano::Error.new("Test failure, deploy aborted")
    #end
  end

  after "deploy:update_code" do
    run_locally "mv public/assets-prod public/assets"
    run_locally "bundle exec rake RAILS_GROUPS=assets assets:precompile"
    run_locally "bundle exec rake RAILS_GROUPS=assets assets:clean_expired"

    find_servers.each do |server|
      run_locally "rsync --recursive --times --rsh=ssh --compress --human-readable --progress public/assets #{user}@#{server.host}:#{latest_release}/public"
    end

    run_locally "mv public/assets public/assets-prod"
  end
end