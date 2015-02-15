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

    @db.create_table :events do
      primary_key :id
      String :producer_id
      String :producer_type
      String :object_id
      String :object_type
      String :verb
      Time :created_at
    end
  end

  def adapter
    @adapter ||= Ag::Adapters::Sequel.new(@db)
  end

  include Ag::Spec::Adapter

  private

  def connections
    @db[:connections].map { |row|
      Ag::Connection.new({
        id: row[:id],
        created_at: row[:created_at],
        consumer: Ag::Object.new(row[:consumer_type], row[:consumer_id]),
        producer: Ag::Object.new(row[:producer_type], row[:producer_id]),
      })
    }
  end

  def connect(consumer, producer)
    @db[:connections].insert({
      consumer_id: consumer.id,
      consumer_type: consumer.type,
      producer_id: producer.id,
      producer_type: producer.type,
    })
  end

  def events
    @db[:events].map { |row|
      Ag::Event.new({
        id: row[:id],
        verb: row[:verb],
        created_at: row[:created_at],
        producer: Ag::Object.new(row[:producer_type], row[:producer_id]),
        object: Ag::Object.new(row[:object_type], row[:object_id]),
      })
    }
  end
end
