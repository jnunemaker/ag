module Ag
  module Spec
    module Adapter
      def test_connect
        consumer = Ag::Object.new("User", "1")
        producer = Ag::Object.new("User", "2")

        adapter.connect(consumer, producer)

        record = connections.first
        assert_equal consumer.id, record[:consumer_id]
        assert_equal consumer.type, record[:consumer_type]
        assert_equal producer.id, record[:producer_id]
        assert_equal producer.type, record[:producer_type]
        assert_in_delta Time.now.utc, record[:created_at], 1
      end

      def test_connected
        consumer = Ag::Object.new("User", "1")
        producer = Ag::Object.new("User", "2")
        connect(consumer, producer)

        assert_equal true, adapter.connected?(consumer, producer)
        assert_equal false, adapter.connected?(producer, consumer)
      end

      def test_consumers
        consumer1 = Ag::Object.new("User", "1")
        consumer2 = Ag::Object.new("User", "2")
        consumer3 = Ag::Object.new("User", "3")
        producer = Ag::Object.new("User", "4")
        connect(consumer1, producer)
        connect(consumer2, producer)

        consumers = adapter.consumers(producer)
        assert_equal 2, consumers.size
        assert_equal "2", consumers[0].consumer_id
        assert_equal "1", consumers[1].consumer_id
      end

      def test_producers
        consumer1 = Ag::Object.new("User", "1")
        consumer2 = Ag::Object.new("User", "2")
        producer1 = Ag::Object.new("User", "3")
        producer2 = Ag::Object.new("User", "4")
        producer3 = Ag::Object.new("User", "5")
        connect(consumer1, producer1)
        connect(consumer1, producer2)
        connect(consumer2, producer3)

        producers = adapter.producers(consumer1)
        assert_equal 2, producers.size
        assert_equal "4", producers[0].producer_id
        assert_equal "3", producers[1].producer_id
      end

      def test_produce
        producer = Ag::Object.new("User", "1")
        object = Ag::Object.new("User", "2")
        event = Ag::Event.new({
          producer: producer,
          object: object,
          verb: "follow",
        })

        adapter.produce(event)

        record = events.first
        assert_equal producer.id, record[:producer_id]
        assert_equal producer.type, record[:producer_type]
        assert_equal object.id, record[:object_id]
        assert_equal object.type, record[:object_type]
        assert_in_delta Time.now.utc, record[:created_at], 1
      end
    end
  end
end
