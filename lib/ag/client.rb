module Ag
  class Client
    def initialize(adapter)
      @adapter = adapter
    end

    def connect(consumer, producer)
      @adapter.connect(consumer, producer)
    end

    def produce(event)
      @adapter.produce(event)
    end

    def connected?(consumer, producer)
      @adapter.connected?(consumer, producer)
    end

    def consumers(producer, options = {})
      @adapter.consumers(producer, options)
    end

    def producers(consumer, options = {})
      @adapter.producers(consumer, options)
    end

    def timeline(consumer, options = {})
      @adapter.timeline(consumer, options)
    end
  end
end
