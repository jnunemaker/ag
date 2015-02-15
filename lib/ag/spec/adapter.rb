module Ag
  module Spec
    module Adapter
      def test_connect
        consumer = Ag::Consumer.new("User", "1")
        producer = Ag::Producer.new("User", "2")

        adapter.connect(consumer, producer)

        record = connections.first
        assert_equal consumer.id, record[:consumer_id]
        assert_equal consumer.type, record[:consumer_type]
        assert_equal producer.id, record[:producer_id]
        assert_equal producer.type, record[:producer_type]
        assert_in_delta Time.now.utc, record[:created_at], 1
      end

      def test_connected
        consumer = Ag::Consumer.new("User", "1")
        producer = Ag::Producer.new("User", "2")
        connect(consumer, producer)

        assert_equal true, adapter.connected?(consumer, producer)
        assert_equal false, adapter.connected?(producer, consumer)
      end

      def test_consumers
        consumer1 = Ag::Consumer.new("User", "1")
        consumer2 = Ag::Consumer.new("User", "2")
        consumer3 = Ag::Consumer.new("User", "3")
        producer = Ag::Producer.new("User", "4")
        connect(consumer1, producer)
        connect(consumer2, producer)

        assert_equal [consumer2, consumer1], adapter.consumers(producer)
      end

      def test_producers
        consumer1 = Ag::Consumer.new("User", "1")
        consumer2 = Ag::Consumer.new("User", "2")
        producer1 = Ag::Producer.new("User", "3")
        producer2 = Ag::Producer.new("User", "4")
        producer3 = Ag::Producer.new("User", "5")
        connect(consumer1, producer1)
        connect(consumer1, producer2)
        connect(consumer2, producer3)

        assert_equal [producer2, producer1], adapter.producers(consumer1)
      end

      def test_produce
        producer = Ag::Producer.new("User", "1")
        object = Ag::Object.new("User", "1")
        actor = Ag::Actor.new("User", "1")
        event = Ag::Event.new({
          producer: producer,
          object: object,
          actor: actor,
          verb: "follow",
        })

        adapter.produce(event)

        record = events.first
        assert_equal producer.id, record[:producer_id]
        assert_equal producer.type, record[:producer_type]
        assert_equal object.id, record[:object_id]
        assert_equal object.type, record[:object_type]
        assert_equal actor.id, record[:actor_id]
        assert_equal actor.type, record[:actor_type]
        assert_in_delta Time.now.utc, record[:created_at], 1
      end
    end
  end
end
