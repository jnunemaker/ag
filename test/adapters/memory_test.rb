require_relative "../helper"
require "ag/adapters/memory"
require "ag/spec/adapter"

class AdaptersMemoryTest < Ag::Test
  def setup
    @source = {}
  end

  def adapter
    @adapter ||= Ag::Adapters::Memory.new(@source)
  end

  include Ag::Spec::Adapter

  private

  def connections
    @source[:connections].map { |connection|
      connection_consumer, connection_producer, created_at = connection
      {
        consumer_id: connection_consumer.id,
        consumer_type: connection_consumer.type,
        producer_id: connection_producer.id,
        producer_type: connection_producer.type,
        created_at: created_at,
      }
    }
  end

  def connect(consumer, producer)
    @source[:connections] ||= []
    @source[:connections] << [consumer, producer, Time.now.utc]
  end

  def events
    @source[:events].map(&:to_hash)
  end
end
