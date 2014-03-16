if defined?(Sidekiq::CLI)
  module Sidekiq
    class CLI
      alias_method :orig_run, :run

      def run(*args)
        trap("TTOU") do
          Sidekiq.logger.info "Received TTOU, no longer accepting new work"
          launcher.manager.async.stop
        end

        orig_run(*args)
      end
    end
  end
end

# Don't raise errors in development env
class OmniAuth::FailureEndpoint
  def call
    redirect_to_failure
  end
end

# Silence the annoying asset log messages
Rails::Rack::Logger.class_eval do
  def call_with_quiet_assets(env)
    previous_level = Rails.logger.level
    if env['PATH_INFO'].index("/assets/") == 0 or env["PATH_INFO"].index("/ping") == 0
      Rails.logger.level = Logger::ERROR
    end

    call_without_quiet_assets(env).tap do
      Rails.logger.level = previous_level
    end
  end

  alias_method_chain :call, :quiet_assets
end