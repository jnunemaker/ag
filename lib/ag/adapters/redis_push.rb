require "redis"
require "json"
require "securerandom"

module Ag
  module Adapters
    class RedisPush
      def initialize(redis)
        @redis = redis
      end

      def connect(consumer, producer)
        @redis.pipelined do |redis|
          redis.zadd(producer.key("consumers"), Time.now.to_f, consumer.key)
          redis.zadd(consumer.key("producers"), Time.now.to_f, producer.key)
        end
      end

      def produce(event)
        value = {
          id: SecureRandom.uuid,
          producer_id: event.producer.id,
          producer_type: event.producer.type,
          object_id: event.object.id,
          object_type: event.object.type,
          verb: event.verb,
        }
        json_value = JSON.dump(value)
        created_at_float = event.created_at.to_f

        # FIXME: This is terrible for large number of consumers. Would be better
        # to do in consumer batches.
        consumers = consumers(event.producer)
        @redis.pipelined do |redis|
          redis.set("events:#{value[:id]}", json_value)
          redis.zadd("events", created_at_float, value[:id])
          consumers.each do |connection|
            redis.zadd(connection.consumer.key("timeline"), created_at_float, value[:id])
          end
        end

        Ag::Event.new({
          id: value[:id],
          producer: event.producer,
          object: event.object,
          verb: event.verb,
          created_at: event.created_at,
        })
      end

      def connected?(consumer, producer)
        !@redis.zscore(consumer.key("producers"), producer.key).nil?
      end

      def consumers(producer, options = {})
        limit = options.fetch(:limit, 30)
        offset = options.fetch(:offset, 0)
        start = offset
        finish = start + limit - 1

        @redis.zrevrange(producer.key("consumers"), start, finish, with_scores: true).map { |key, value|
          Ag::Connection.new({
            consumer: Ag::Object.from_key(key),
            producer: producer,
            created_at: Time.at(value).utc
          })
        }
      end

      def producers(consumer, options = {})
        limit = options.fetch(:limit, 30)
        offset = options.fetch(:offset, 0)
        start = offset
        finish = start + limit - 1

        @redis.zrevrange(consumer.key("producers"), start, finish, with_scores: true).map { |key, value|
          Ag::Connection.new({
            producer: Ag::Object.from_key(key),
            consumer: consumer,
            created_at: Time.at(value).utc
          })
        }
      end

      def timeline(consumer, options = {})
        limit = options.fetch(:limit, 30)
        offset = options.fetch(:offset, 0)
        start = offset
        finish = start + limit - 1

        # get all the event ids
        rows = @redis.zrevrange(consumer.key("timeline"), start, finish, with_scores: true)

        # mget all events
        # FIXME: this is most likely terrible for really large number
        # of events being fetched; should probably mget in batches
        event_keys = rows.map { |row| "events:#{row[0]}" }
        redis_events = @redis.mget(event_keys).inject({}) { |hash, json|
          event = JSON.load(json)
          hash[event["id"]] = event
          hash
        }

        # build the event instances
        rows.map { |row|
          event_id, score = row
          hash = redis_events.fetch(event_id)
          created_at = Time.at(score).utc
          producer = Ag::Object.new(hash["producer_type"], hash.fetch("producer_id"))
          object = Ag::Object.new(hash["object_type"], hash.fetch("object_id"))

          Ag::Event.new({
            id: event_id,
            producer: producer,
            object: object,
            verb: hash["verb"],
            created_at: created_at,
          })
        }
      end
    end
  end
end
