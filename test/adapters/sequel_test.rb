require_relative "../helper"
require "ag/adapters/sequel"
require "ag/spec/adapter"

class AdaptersSequelTest < Ag::Test
  def setup
    Sequel.default_timezone = :utc
    @db = Sequel.sqlite
    @db.create_table :connections do
      primary_key :id
      String :consumer_id
      String :consumer_type
      String :producer_id
      String :producer_type
      Time :created_at
    end
  end

  def adapter
    @adapter ||= Ag::Adapters::Sequel.new(@db)
  end

  include Ag::Spec::Adapter

  private

  def connections
    @db[:connections]
  end

  def connect(consumer, producer)
    @db[:connections].insert({
      consumer_id: consumer.id,
      consumer_type: consumer.type,
      producer_id: producer.id,
      producer_type: producer.type,
    })
  end
end
