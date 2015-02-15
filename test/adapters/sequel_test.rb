require_relative "../helper"
require "ag/adapters/sequel"

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

  def test_connect
    adapter = Ag::Adapters::Sequel.new(@db)
    consumer = Ag::Consumer.new("User", "1")
    producer = Ag::Producer.new("User", "2")

    adapter.connect(consumer, producer)

    record = @db[:connections].first
    assert_equal 1, record[:id]
    assert_equal consumer.id, record[:consumer_id]
    assert_equal consumer.type, record[:consumer_type]
    assert_equal producer.id, record[:producer_id]
    assert_equal producer.type, record[:producer_type]
    assert_in_delta Time.now.utc, record[:created_at], 1
  end

  def test_connected
    adapter = Ag::Adapters::Sequel.new(@db)
    consumer = Ag::Consumer.new("User", "1")
    producer = Ag::Producer.new("User", "2")
    create_follow(consumer, producer)

    assert_equal true, adapter.connected?(consumer, producer)
    assert_equal false, adapter.connected?(producer, consumer)
  end

  def test_consumers
    adapter = Ag::Adapters::Sequel.new(@db)
    consumer1 = Ag::Consumer.new("User", "1")
    consumer2 = Ag::Consumer.new("User", "2")
    consumer3 = Ag::Consumer.new("User", "3")
    producer = Ag::Producer.new("User", "4")
    create_follow(consumer1, producer)
    create_follow(consumer2, producer)

    assert_equal [consumer2, consumer1], adapter.consumers(producer)
  end

  def test_producers
    adapter = Ag::Adapters::Sequel.new(@db)
    consumer1 = Ag::Consumer.new("User", "1")
    consumer2 = Ag::Consumer.new("User", "2")
    producer1 = Ag::Producer.new("User", "3")
    producer2 = Ag::Producer.new("User", "4")
    producer3 = Ag::Producer.new("User", "5")
    create_follow(consumer1, producer1)
    create_follow(consumer1, producer2)
    create_follow(consumer2, producer3)

    assert_equal [producer2, producer1], adapter.producers(consumer1)
  end

  private

  def create_follow(consumer, producer)
    @db[:connections].insert({
      consumer_id: consumer.id,
      consumer_type: consumer.type,
      producer_id: producer.id,
      producer_type: producer.type,
    })
  end
end
