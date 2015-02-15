require "sequel"

module Ag
  module Adapters
    # Adapter that uses the minimum amount of writes while still allowing full
    # historic assembly of timelines. This comes at the cost of slower reads.
    class SequelPullCompact
      def self.dehydrate(object)
        [object.type, object.id].join(":")
      end

      def self.hydrate(id)
        Ag::Object.new(*id.split(":"))
      end

      def initialize(db)
        @db = db
      end

      def connect(consumer, producer)
        created_at = Time.now.utc
        id = @db[:connections].insert({
          consumer_id: self.class.dehydrate(consumer),
          producer_id: self.class.dehydrate(producer),
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
        created_at = event.created_at || Time.now.utc
        id = @db[:events].insert({
          producer_id: self.class.dehydrate(event.producer),
          object_id: self.class.dehydrate(event.object),
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
        !@db[:connections].select(:id).where({
          consumer_id: self.class.dehydrate(consumer),
          producer_id: self.class.dehydrate(producer),
        }).first.nil?
      end

      def consumers(producer, options = {})
        @db[:connections].
          where({
            producer_id: self.class.dehydrate(producer),
          }).
          limit(options.fetch(:limit, 30)).
          offset(options.fetch(:offset, 0)).
          order(Sequel.desc(:id)).
          map { |row|
            Connection.new({
              id: row[:id],
              created_at: row[:created_at],
              consumer: self.class.hydrate(row[:consumer_id]),
              producer: self.class.hydrate(row[:producer_id]),
            })
          }
      end

      def producers(consumer, options = {})
        @db[:connections].
          where({
            consumer_id: self.class.dehydrate(consumer),
          }).
          limit(options.fetch(:limit, 30)).
          offset(options.fetch(:offset, 0)).
          order(Sequel.desc(:id)).
          map { |row|
            Connection.new({
              id: row[:id],
              created_at: row[:created_at],
              consumer: self.class.hydrate(row[:consumer_id]),
              producer: self.class.hydrate(row[:producer_id]),
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
              e.producer_id = c.producer_id
          WHERE
            c.consumer_id = :consumer_id
          ORDER BY
            e.created_at DESC
          LIMIT :limit
          OFFSET :offset
        SQL

        binds = {
          consumer_id: self.class.dehydrate(consumer),
          limit: options.fetch(:limit, 30),
          offset: options.fetch(:offset, 0),
        }

        @db[statement, binds].to_a.map { |row|
          Ag::Event.new({
            id: row[:id],
            created_at: row[:created_at],
            producer: self.class.hydrate(row[:producer_id]),
            object: self.class.hydrate(row[:object_id]),
            verb: row[:verb],
          })
        }
      end
    end
  end
end
