DependencyDetection.defer do
  @name = :mongodb

  depends_on do
    defined?(::Mongo) and not NewRelic::Control.instance['disable_mongodb']
  end

  executes do
    NewRelic::Agent.logger.debug 'Installing MongoDB instrumentation'
  end

  executes do
    ::Mongo::Logging.class_eval do
      include NewRelic::Agent::MethodTracer

      def sanitize_data(data)
        parsed = {}

        data.each do |key, value|
          if value.is_a?(Array)
            if key == "$or" or key == "$and" or key == "$and"
              parsed[key] = []
              value.each_index do |i|
                parsed[key][i] = sanitize_data(value[i])
              end

            else
              parsed[key] = "?"
            end

          elsif value.is_a?(Hash)
            parsed[key] = sanitize_data(value)

          # Allow true/false/nil as they don't have sensitive info and can change the results in a relevant way
          elsif value.is_a?(TrueClass) or value.is_a?(FalseClass) or value.is_a?(NilClass)
            parsed[key] = value

          else
            parsed[key] = "?"
          end
        end

        parsed
      end

      # This is an inefficient way of instrumenting and logging Mongo right now
      # but we can't really easily do this with regex because of how Mongo queries work
      def instrument_with_newrelic_trace(name, payload = {}, &blk)
        collection = payload[:collection]
        if collection == '$cmd'
          f = payload[:selector].first
          name, collection = f if f
        end

        log_payload = {:type => name, :collection => collection}

        if payload[:query]
          log_payload[:query] = sanitize_data(payload[:query])
        elsif payload[:documents]
          log_payload[:documents] = []
          payload[:documents].each_index do |i|
            log_payload[:documents][i] = sanitize_data(payload[:documents][i])
          end
        end

        if payload[:selector] and payload[:selector][:query]
          log_payload[:selector] = payload[:selector].dup
          log_payload[:selector][:query] = sanitize_data(payload[:selector][:query])

        elsif payload[:selector] and name != "mapreduce"
          log_payload[:selector] = sanitize_data(payload[:selector])
        end

        log_payload = log_payload.inspect
        log_payload.gsub!('"?"', "?")

        trace_execution_scoped("Database/#{collection}/#{name}") do
          t0 = Time.now
          begin
            res = instrument_without_newrelic_trace(name, payload, &blk)
          ensure
            elapsed = (Time.now - t0).to_f
            NewRelic::Agent.instance.transaction_sampler.notice_sql(log_payload, nil, elapsed)
            NewRelic::Agent.instance.sql_sampler.notice_sql(log_payload, nil, nil, elapsed)

            # https://newrelic.com/docs/instrumentation/metric-types
            NewRelic::Agent.instance.stats_engine.get_stats_no_scope("ActiveRecord/all").trace_call(elapsed)
            type = name == "insert" or name == "update" or name == "create" ? "save" : "find"
            NewRelic::Agent.instance.stats_engine.get_stats_no_scope("ActiveRecord/#{type}").trace_call(elapsed)
          end

          res
        end
      end

      alias_method :instrument_without_newrelic_trace, :instrument
      alias_method :instrument, :instrument_with_newrelic_trace
    end

    class Mongo::Collection; include Mongo::Logging; end
    class Mongo::Connection; include Mongo::Logging; end
    class Mongo::Cursor; include Mongo::Logging; end

    # cursor refresh is not currently instrumented in mongo driver, so not picked up by above - have to add our own here
    ::Mongo::Cursor.class_eval do
      include NewRelic::Agent::MethodTracer

      def send_get_more_with_newrelic_trace
        trace_execution_scoped(["ActiveRecord/all", "ActiveRecord/find", "Database/#{collection.name}/refresh"]) do
          send_get_more_without_newrelic_trace
        end
      end

      alias_method :send_get_more_without_newrelic_trace, :send_get_more
      alias_method :send_get_more, :send_get_more_with_newrelic_trace
      add_method_tracer :close, 'Database/#{collection.name}/close'
    end
 end
end