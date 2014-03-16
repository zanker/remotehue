module Sidekiq
  module Plugins
    class Librato
      def initialize(options={})

      end

      def call(worker_instance, msg, queue)
        t = Time.now
        yield
        elapsed = (Time.now - t).to_f

        sidekiq = ::Sidekiq::Stats.new

        ::Stats.batch.increment("sidekiq.all.processed")
        ::Stats.batch.gauge("sidekiq.all.enqueued", sidekiq.enqueued)
        ::Stats.batch.gauge("sidekiq.all.failed", sidekiq.failed)

        ::Stats.batch.increment("sidekiq.#{queue}.processed")
        ::Stats.batch.gauge("sidekiq.#{queue}.runtime", elapsed)
        ::Stats.batch.gauge("sidekiq.#{queue}.enqueued", sidekiq.queues[queue])

        ::Stats.batch.increment("sidekiq.#{queue}.#{msg["class"]}.processed")
        ::Stats.batch.gauge("sidekiq.#{queue}.#{msg["class"]}.runtime", elapsed)
        ::Stats.batch.flush
      end
    end
  end
end