require_relative "../helper"
require "ag/adapters/sequel_pull_compact"
require "ag/spec/adapter"

class AdaptersSequelPullCompactTest < Ag::Test
  def setup
    Sequel.default_timezone = :utc
    @db = Sequel.sqlite

    @db.create_table :connections do
      primary_key :id
      String :consumer_id
      String :producer_id
      Time :created_at
      index [:consumer_id, :producer_id], unique: true
    end

    @db.create_table :events do
      primary_key :id
      String :producer_id
      String :object_id
      String :verb
      Time :created_at
    end
  end

  def adapter
    @adapter ||= Ag::Adapters::SequelPullCompact.new(@db)
  end

  include Ag::Spec::Adapter

  private

  def connections
    @db[:connections].map { |row|
      Ag::Connection.new({
        id: row[:id],
        created_at: row[:created_at],
        consumer: Ag::Adapters::SequelPullCompact.hydrate(row[:consumer_id]),
        producer: Ag::Adapters::SequelPullCompact.hydrate(row[:producer_id]),
      })
    }
  end

  def events
    @db[:events].map { |row|
      Ag::Event.new({
        id: row[:id],
        verb: row[:verb],
        created_at: row[:created_at],
        producer: Ag::Adapters::SequelPullCompact.hydrate(row[:producer_id]),
        object: Ag::Adapters::SequelPullCompact.hydrate(row[:object_id]),
      })
    }
  end

  def connect(consumer, producer)
    @db[:connections].insert({
      consumer_id: Ag::Adapters::SequelPullCompact.dehydrate(consumer),
      producer_id: Ag::Adapters::SequelPullCompact.dehydrate(producer),
    })
  end

  def produce(event)
    @db[:events].insert({
      producer_id: Ag::Adapters::SequelPullCompact.dehydrate(event.producer),
      object_id: Ag::Adapters::SequelPullCompact.dehydrate(event.object),
      created_at: Time.now.utc,
    })
  end
end
