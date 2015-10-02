require_relative "../helper"
require "ag/adapters/redis_push"
require "ag/spec/adapter"

class AdaptersRedisPushTest < Ag::Test
  def setup
    @redis = Redis.new(:port => ENV.fetch("GH_REDIS_PORT", 6379).to_i)
    @redis.flushdb
  end

  def adapter
    @adapter ||= Ag::Adapters::RedisPush.new(@redis)
  end

  include Ag::Spec::Adapter

  private

  def connections(consumer)
    @redis.zrevrange(consumer.key("producers"), 0, -1, with_scores: true).map { |key, value|
      Ag::Connection.new({
        producer: Ag::Object.from_key(key),
        consumer: consumer,
        created_at: Time.at(value).utc
      })
    }
  end

  def events
    @redis.zrevrange("events", 0, -1, with_scores: true).map { |row|
      event_id, score = row
      value = @redis.get("events:#{event_id}")
      hash = JSON.load(value)
      created_at = Time.at(score).utc
      producer = Ag::Object.new(hash["producer_type"], hash.fetch("producer_id"))
      object = Ag::Object.new(hash["object_type"], hash.fetch("object_id"))

      Ag::Event.new({
        id: hash["id"],
        producer: producer,
        object: object,
        verb: hash["verb"],
        created_at: created_at,
      })
    }
  end

  def connect(consumer, producer)
    @redis.pipelined do |redis|
      redis.zadd(producer.key("consumers"), Time.now.utc.to_i, consumer.key)
      redis.zadd(consumer.key("producers"), Time.now.utc.to_i, producer.key)
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
    consumers = consumers(event.producer)

    @redis.pipelined do |redis|
      redis.set("events:#{value[:id]}", json_value)
      redis.zadd("events", created_at_float, json_value)
      consumers.each do |consumer|
        redis.zadd(consumer.key("timeline"), created_at_float, value[:id])
      end
    end
  end

  def consumers(producer)
    @redis.zrevrange(producer.key("consumers"), 0, -1).map { |key|
      Ag::Object.from_key(key)
    }
  end
end
