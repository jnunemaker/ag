require_relative "../helper"
require "ag/adapters/sequel_pull"
require "ag/spec/adapter"

class AdaptersSequelPullTest < Ag::Test
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
      index [:consumer_id, :consumer_type, :producer_id, :producer_type], unique: true
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
    @adapter ||= Ag::Adapters::SequelPull.new(@db)
  end

  include Ag::Spec::Adapter

  private

  def producers(consumer)
    @db[:connections].where(consumer_id: consumer.id, consumer_type: consumer.type).map { |row|
      Ag::Connection.new({
        id: row[:id],
        created_at: row[:created_at],
        consumer: Ag::Object.new(row[:consumer_type], row[:consumer_id]),
        producer: Ag::Object.new(row[:producer_type], row[:producer_id]),
      })
    }
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

  def connect(consumer, producer)
    @db[:connections].insert({
      consumer_id: consumer.id,
      consumer_type: consumer.type,
      producer_id: producer.id,
      producer_type: producer.type,
    })
  end

  def produce(event)
    @db[:events].insert({
      producer_type: event.producer.type,
      producer_id: event.producer.id,
      object_type: event.object.type,
      object_id: event.object.id,
      created_at: Time.now.utc,
    })
  end
end
