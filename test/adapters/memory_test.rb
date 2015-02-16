require_relative "../helper"
require "ag/adapters/memory"
require "ag/spec/adapter"
require "securerandom"

class AdaptersMemoryTest < Ag::Test
  def setup
    @source = {}
  end

  def adapter
    @adapter ||= Ag::Adapters::Memory.new(@source)
  end

  include Ag::Spec::Adapter

  private

  def producers(consumer)
    @source[:connections].select { |connection|
      connection.consumer == consumer
    }
  end

  def events
    @source[:events]
  end

  def connect(consumer, producer)
    @source[:connections] ||= []
    @source[:connections] << Ag::Connection.new({
      id: SecureRandom.uuid,
      created_at: Time.now.utc,
      consumer: consumer,
      producer: producer,
    })
  end

  def produce(event)
    @source[:events] ||= []
    @source[:events] << event
  end
end
