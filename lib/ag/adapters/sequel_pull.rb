require "sequel"

module Ag
  module Adapters
    # Adapter that uses the minimum amount of writes while still allowing full
    # historic assembly of timelines. This comes at the cost of slower reads.
    class SequelPull
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

      def produce(event)
        created_at = Time.now.utc
        id = @db[:events].insert({
          producer_type: event.producer.type,
          producer_id: event.producer.id,
          object_type: event.object.type,
          object_id: event.object.id,
          verb: event.verb,
          created_at: created_at,
        })

        Ag::Event.new({
          id: id,
          created_at: created_at,
          producer: event.producer,
          object: event.object,
          verb: event.verb,
        })
      end

      def connected?(consumer, producer)
        statement = <<-SQL
          SELECT
            1
          FROM
            connections
          WHERE
            consumer_id = :consumer_id AND
            producer_id = :producer_id
          LIMIT 1
        SQL

        binds = {
          consumer_id: consumer.id,
          consumer_type: consumer.type,
          producer_id: producer.id,
          producer_type: producer.type,
        }

        !@db[statement, binds].first.nil?
      end

      def consumers(producer, options = {})
        statement = <<-SQL
          SELECT
            id, created_at, consumer_id, consumer_type, producer_id, producer_type
          FROM
            connections
          WHERE
            producer_id = :producer_id AND
            producer_type = :producer_type
          ORDER BY
            id DESC
          LIMIT :limit
          OFFSET :offset
        SQL

        binds = {
          producer_id: producer.id,
          producer_type: producer.type,
          limit: options.fetch(:limit, 30),
          offset: options.fetch(:offset, 0),
        }

        @db[statement, binds].to_a.map { |row|
          Connection.new({
            id: row[:id],
            created_at: row[:created_at],
            consumer: Object.new(row[:consumer_type], row[:consumer_id]),
            producer: Object.new(row[:producer_type], row[:producer_id]),
          })
        }
      end

      def producers(consumer, options = {})
        statement = <<-SQL
          SELECT
            id, created_at, consumer_id, consumer_type, producer_id, producer_type
          FROM
            connections
          WHERE
            consumer_id = :consumer_id AND
            consumer_type = :consumer_type
          ORDER BY
            id DESC
          LIMIT :limit
          OFFSET :offset
        SQL

        binds = {
          consumer_id: consumer.id,
          consumer_type: consumer.type,
          limit: options.fetch(:limit, 30),
          offset: options.fetch(:offset, 0),
        }

        @db[statement, binds].to_a.map { |row|
          Connection.new({
            id: row[:id],
            created_at: row[:created_at],
            consumer: Object.new(row[:consumer_type], row[:consumer_id]),
            producer: Object.new(row[:producer_type], row[:producer_id]),
          })
        }
      end

      def timeline(consumer, options = {})
        statement = <<-SQL
          SELECT
            e.*
          FROM
            events e
          INNER JOIN
            connections c ON
              e.producer_id = c.producer_id AND
              e.producer_type = c.producer_type
          WHERE
            c.consumer_id = :consumer_id AND
            c.consumer_type = :consumer_type
          ORDER BY
            e.created_at DESC
          LIMIT :limit
          OFFSET :offset
        SQL

        binds = {
          consumer_id: consumer.id,
          consumer_type: consumer.type,
          limit: options.fetch(:limit, 30),
          offset: options.fetch(:offset, 0),
        }

        @db[statement, binds].to_a.map { |row|
          Ag::Event.new({
            id: row[:id],
            created_at: row[:created_at],
            producer: Ag::Object.new(row[:producer_type], row[:producer_id]),
            object: Ag::Object.new(row[:object_type], row[:object_id]),
            verb: row[:verb],
          })
        }
      end
    end
  end
end
