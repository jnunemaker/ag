require "sequel"

module Ag
  module Adapters
    class Sequel
      def initialize(db)
        @db = db
      end

      def connect(consumer, producer)
        @db[:connections].insert({
          consumer_id: consumer.id,
          consumer_type: consumer.type,
          producer_id: producer.id,
          producer_type: producer.type,
          created_at: Time.now.utc,
        })
      end

      def connected?(consumer, producer)
        !@db[:connections].select(:id).where({
          consumer_id: consumer.id,
          consumer_type: consumer.type,
          producer_id: producer.id,
          producer_type: producer.type,
        }).first.nil?
      end

      def consumers(producer)
        @db[:connections].select(:consumer_id, :consumer_type).where({
          producer_id: producer.id,
          producer_type: producer.type,
        }).order(::Sequel.desc(:id)).map { |row|
          Consumer.new(row[:consumer_type], row[:consumer_id])
        }
      end

      def producers(consumer)
        @db[:connections].select(:producer_id, :producer_type).where({
          consumer_id: consumer.id,
          consumer_type: consumer.type,
        }).order(::Sequel.desc(:id)).map { |row|
          Producer.new(row[:producer_type], row[:producer_id])
        }
      end
    end
  end
end
