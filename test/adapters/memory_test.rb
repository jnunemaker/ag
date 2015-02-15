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
    @source[:connections].map(&:to_hash)
  end

  def connect(consumer, producer)
    @source[:connections] ||= []
    @source[:connections] << Ag::Connection.new({
      id: SecureRandom.hex(20),
      created_at: Time.now.utc,
      consumer: consumer,
      producer: producer,
    })
  end

  def events
    @source[:events].map(&:to_hash)
  end
end
