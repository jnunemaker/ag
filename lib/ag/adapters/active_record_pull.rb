require "active_record"

module Ag
  module Adapters
    class ActiveRecordPull
      # Private: Do not use outside of this adapter.
      class Connection < ::ActiveRecord::Base
        self.table_name = [
          ::ActiveRecord::Base.table_name_prefix,
          "ag_connections",
          ::ActiveRecord::Base.table_name_suffix,
        ].join
      end

      # Private: Do not use outside of this adapter.
      class Event < ::ActiveRecord::Base
        self.table_name = [
          ::ActiveRecord::Base.table_name_prefix,
          "ag_events",
          ::ActiveRecord::Base.table_name_suffix,
        ].join
      end

      def connect(consumer, producer)
        created_at = Time.now.utc
        connection = Connection.create({
          consumer_id: consumer.id,
          consumer_type: consumer.type,
          producer_id: producer.id,
          producer_type: producer.type,
          created_at: created_at,
        })

        Ag::Connection.new({
          id: connection.id,
          created_at: created_at,
          consumer: consumer,
          producer: producer,
        })
      end

      def produce(event)
        created_at = Time.now.utc
        ar_event = Event.create({
          producer_type: event.producer.type,
          producer_id: event.producer.id,
          object_type: event.object.type,
          object_id: event.object.id,
          verb: event.verb,
          created_at: created_at,
        })

        Ag::Event.new({
          id: ar_event.id,
          created_at: created_at,
          producer: event.producer,
          object: event.object,
          verb: event.verb,
        })
      end

      def connected?(consumer, producer)
        Connection.
          where(consumer_id: consumer.id, consumer_type: consumer.type).
          where(producer_id: producer.id, producer_type: producer.type).
          exists?
      end

      def consumers(producer, options = {})
        connections = Connection.
          select(:id, :created_at, :consumer_id, :consumer_type, :producer_id, :producer_type).
          where(producer_id: producer.id, producer_type: producer.type).
          order("id DESC").
          limit(options.fetch(:limit, 30)).
          offset(options.fetch(:offset, 0))

        connections.map do |connection|
          Ag::Connection.new({
            id: connection.id,
            created_at: connection.created_at,
            consumer: Ag::Object.new(connection.consumer_type, connection.consumer_id),
            producer: Ag::Object.new(connection.producer_type, connection.producer_id),
          })
        end
      end

      def producers(consumer, options = {})
        connections = Connection.
          select(:id, :created_at, :consumer_id, :consumer_type, :producer_id, :producer_type).
          where(consumer_id: consumer.id, consumer_type: consumer.type).
          order("id DESC").
          limit(options.fetch(:limit, 30)).
          offset(options.fetch(:offset, 0))

        connections.map do |connection|
          Ag::Connection.new({
            id: connection.id,
            created_at: connection.created_at,
            consumer: Ag::Object.new(connection.consumer_type, connection.consumer_id),
            producer: Ag::Object.new(connection.producer_type, connection.producer_id),
          })
        end
      end

      def timeline(consumer, options = {})
        joins = <<-SQL
          INNER JOIN #{Connection.table_name} ON
            #{Event.table_name}.producer_id = #{Connection.table_name}.producer_id AND
            #{Event.table_name}.producer_type = #{Connection.table_name}.producer_type
        SQL
        events = Event.
          select("#{Event.table_name}.*").
          joins(joins).
          where("#{Connection.table_name}.consumer_id = :consumer_id", consumer_id: consumer.id).
          where("#{Connection.table_name}.consumer_type = :consumer_type", consumer_type: consumer.type).
          order("#{Event.table_name}.created_at DESC").
          limit(options.fetch(:limit, 30)).
          offset(options.fetch(:offset, 0))

        events.map do |event|
          Ag::Event.new({
            id: event.id,
            created_at: event.created_at,
            producer: Ag::Object.new(event.producer_type, event.producer_id),
            object: Ag::Object.new(event.object_type, event.object_id),
            verb: event.verb,
          })
        end
      end
    end
  end
end
