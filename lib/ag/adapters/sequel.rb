require "sequel"

module Ag
  module Adapters
    class Sequel
      def initialize(db)
        @db = db
      end

      def connect(consumer, producer)
        created_at = Time.now.utc
        id = @db[:connections].insert({
          consumer_id: consumer.id,
          consumer_type: consumer.type,
          producer_id: producer.id,
          producer_type: producer.type,
          created_at: created_at,
        })

        Connection.new({
          id: id,
          created_at: created_at,
          consumer: consumer,
          producer: producer,
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
          Connection.new({
            id: row[:id],
            created_at: row[:created_at],
            consumer: Object.new(row[:consumer_type], row[:consumer_id]),
            producer: Object.new(row[:producer_type], row[:producer_id]),
          })
        }
      end

      def producers(consumer)
        @db[:connections].where({
          consumer_id: consumer.id,
          consumer_type: consumer.type,
        }).order(::Sequel.desc(:id)).map { |row|
          Connection.new({
            id: row[:id],
            created_at: row[:created_at],
            consumer: Object.new(row[:consumer_type], row[:consumer_id]),
            producer: Object.new(row[:producer_type], row[:producer_id]),
          })
        }
      end

      def produce(event)
        @db[:events].insert({
          producer_type: event.producer.type,
          producer_id: event.producer.id,
          object_type: event.object.type,
          object_id: event.object.id,
          created_at: Time.now.utc,
        })
      end

      def timeline(consumer)
        statement = <<-SQL
          SELECT
            e.*
          FROM
            events e
          INNER JOIN
            connections c ON e.producer_id = c.producer_id AND e.producer_type = c.producer_type
          WHERE
            c.consumer_id = :consumer_id AND c.consumer_type = :consumer_type
        SQL
        binds = {
          consumer_id: consumer.id,
          consumer_type: consumer.type,
        }
        @db[statement, binds].to_a
      end
    end
  end
end
