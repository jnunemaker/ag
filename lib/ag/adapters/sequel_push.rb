require "sequel/core"

module Ag
  module Adapters
    # Adapter that uses the maximum amount of writes in order to make
    # reading faster.
    class SequelPush
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

        result = Ag::Event.new({
          id: id,
          created_at: created_at,
          producer: event.producer,
          object: event.object,
          verb: event.verb,
        })

        # FIXME: don't want to transaction around this and event insert because
        # this could take a while and long transactions are terrible, but do
        # need to do some failure handling in here
        each_consumer(result.producer) do |consumer|
          @db[:timelines].insert({
            consumer_id: consumer.id,
            consumer_type: consumer.type,
            event_id: result.id,
            created_at: result.created_at,
          })
        end

        result
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
            e.id, e.created_at,
            e.object_type, e.object_id,
            e.producer_type, e.producer_id
          FROM
            events e
          INNER JOIN
            timelines t ON e.id = t.event_id
          WHERE
            t.consumer_id = :consumer_id AND
            t.consumer_type = :consumer_type
          ORDER BY
            t.created_at DESC
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

      private

      # FIXME: single query is terrible, need to do batches
      def each_consumer(producer)
        statement = <<-SQL
          SELECT
            consumer_id, consumer_type
          FROM
            connections
          WHERE
            producer_id = :producer_id AND
            producer_type = :producer_type
          ORDER BY
            id ASC
        SQL

        binds = {
          producer_id: producer.id,
          producer_type: producer.type,
        }

        @db[statement, binds].each do |row|
          yield Ag::Object.new(row[:consumer_type], row[:consumer_id])
        end
      end
    end
  end
end
