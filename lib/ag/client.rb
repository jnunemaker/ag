module Ag
  class Client
    def initialize(adapter)
      @adapter = adapter
    end

    def connect(consumer, producer)
      adapter.connect(consumer, producer)
    end

    def connected?(consumer, producer)
      adapter.connected?(consumer, producer)
    end

    def consumers(producer)
      adapter.consumers(producer)
    end

    def producers(consumer)
      adapter.producers(consumer)
    end
  end
end
