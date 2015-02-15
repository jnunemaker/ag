require "securerandom"

module Ag
  module Adapters
    class Memory
      def initialize(source = {})
        @source = source
      end

      def connect(consumer, producer)
        @source[:connections] ||= []
        @source[:connections] << Connection.new({
          id: SecureRandom.uuid,
          created_at: Time.now.utc,
          consumer: consumer,
          producer: producer,
        })
      end

      def produce(event)
        result = Ag::Event.new({
          id: SecureRandom.uuid,
          producer: event.producer,
          object: event.object,
          verb: event.verb,
        })
        @source[:events] ||= []
        @source[:events] << result
        result
      end

      def connected?(consumer, producer)
        !@source[:connections].detect { |connection|
          connection.consumer == consumer &&
            connection.producer == producer
        }.nil?
      end

      def consumers(producer, options = {})
        @source[:connections].select { |connection|
          connection.producer == producer
        }.reverse
      end

      def producers(consumer, options = {})
        @source[:connections].select { |connection|
          connection.consumer == consumer
        }.reverse
      end

      def timeline(consumer, options = {})
        producers = producers(consumer).map(&:producer)

        Array(@source[:events]).select { |event|
          producers.include?(event.producer)
        }.sort_by { |event|
          -event.created_at.to_f
        }[options.fetch(:offset, 0), options.fetch(:limit, 30)]
      end
    end
  end
end
