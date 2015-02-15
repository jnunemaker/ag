module Ag
  module Adapters
    class Memory
      def initialize(source = {})
        @source = source
      end

      def connect(consumer, producer)
        @source[:connections] ||= []
        @source[:connections] << [consumer, producer, Time.now.utc]
      end

      def connected?(consumer, producer)
        consumers(producer).include?(consumer)
      end

      def consumers(producer)
        @source[:connections].select { |connection|
          connection_consumer, connection_producer, _ = connection
          producer == connection_producer
        }.map { |connection|
          connection_consumer, _ = connection
          connection_consumer
        }.reverse
      end

      def producers(consumer)
        @source[:connections].select { |connection|
          connection_consumer, connection_producer, _ = connection
          consumer == connection_consumer
        }.map { |connection|
          _, connection_producer = connection
          connection_producer
        }.reverse
      end

      def produce(event)
        @source[:events] ||= []
        @source[:events] << event
      end
    end
  end
end
