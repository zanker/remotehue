class Stats
  def self.client
    unless @client
      @client = Statsd.new
      @client.namespace = "remotehue"
    end

    @client
  end

  def self.batch
    unless @batch
      @batch = Statsd::Batch.new(self.client)
    end

    @batch
  end

  def self.timing(key)
    start = Time.now.to_f
    res = yield
    Stats.batch.gauge(key, Time.now.to_f - start)

    res
  end

  def self.network(key)
    start = Time.now.to_f
    res = yield
    Stats.batch.gauge("#{key}/#{res.respond_to?(:code) ? res.code : res.status}", Time.now.to_f - start)

    res
  end
end