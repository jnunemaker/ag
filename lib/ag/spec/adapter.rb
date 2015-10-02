module Ag
  module Spec
    module Adapter
      def test_connect
        consumer = Ag::Object.new("User", "1")
        producer = Ag::Object.new("User", "2")

        adapter.connect(consumer, producer)

        connection = producers(consumer).first
        refute_nil connection
        assert_equal consumer.id, connection.consumer.id
        assert_equal consumer.type, connection.consumer.type
        assert_equal producer.id, connection.producer.id
        assert_equal producer.type, connection.producer.type
        assert_in_delta Time.now.utc, connection.created_at, 1
      end

      def test_produce
        producer = Ag::Object.new("User", "1")
        object = Ag::Object.new("User", "2")
        event = Ag::Event.new({
          producer: producer,
          object: object,
          verb: "follow",
        })

        result = adapter.produce(event)

        event = events.first
        assert_equal event.id, result.id
        assert_equal producer.id, event.producer.id
        assert_equal producer.type, event.producer.type
        assert_equal object.id, event.object.id
        assert_equal object.type, event.object.type
        assert_in_delta Time.now.utc, event.created_at, 1
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
        assert_equal "2", consumers[0].consumer.id
        assert_equal "1", consumers[1].consumer.id
      end

      def test_consumers_limit
        producer = Ag::Object.new("User", "99")
        consumers = (0..9).to_a.map { |n|
          Ag::Object.new("User", n.to_s).tap { |consumer|
            connect consumer, producer
          }
        }
        assert_equal 5, adapter.consumers(producer, limit: 5).size
        assert_equal consumers[5..9].reverse,
          adapter.consumers(producer, limit: 5).map(&:consumer)
      end

      def test_consumers_offset
        producer = Ag::Object.new("User", "99")
        consumers = (0..9).to_a.map { |n|
          Ag::Object.new("User", n.to_s).tap { |consumer|
            connect consumer, producer
          }
        }
        assert_equal consumers[0..4].reverse,
          adapter.consumers(producer, offset: 5).map(&:consumer)
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
        assert_equal "4", producers[0].producer.id
        assert_equal "3", producers[1].producer.id
      end

      def test_producers_limit
        consumer = Ag::Object.new("User", "99")
        producers = (0..9).to_a.map { |n|
          Ag::Object.new("User", n.to_s).tap { |producer|
            connect consumer, producer
          }
        }
        assert_equal 5, adapter.producers(consumer, limit: 5).size
        assert_equal producers[5..9].reverse,
          adapter.producers(consumer, limit: 5).map(&:producer)
      end

      def test_producers_offset
        consumer = Ag::Object.new("User", "99")
        producers = (0..9).to_a.map { |n|
          Ag::Object.new("User", n.to_s).tap { |producer|
            connect consumer, producer
          }
        }
        assert_equal producers[0..4].reverse,
          adapter.producers(consumer, offset: 5).map(&:producer)
      end

      def test_timeline
        john = Ag::Object.new("User", "1")
        steve = Ag::Object.new("User", "2")
        presentation = Ag::Object.new("Presentation", "1")
        connect john, steve
        produce Ag::Event.new(producer: steve, object: presentation, verb: "publish")

        events = adapter.timeline(john)
        assert_equal 1, events.size
      end

      def test_timeline_limit
        john = Ag::Object.new("User", "1")
        steve = Ag::Object.new("User", "2")
        connect john, steve

        presentations = (0..9).to_a.map { |n|
          Ag::Object.new("Presentation", n.to_s)
        }

        presentations.each do |presentation|
          produce Ag::Event.new({
            producer: steve,
            object: presentation,
            verb: "publish",
          })
        end

        events = adapter.timeline(john, limit: 5)
        assert_equal 5, events.size
        assert_equal presentations[5..9].reverse, events.map(&:object)
      end

      def test_timeline_offset
        john = Ag::Object.new("User", "1")
        steve = Ag::Object.new("User", "2")
        connect john, steve

        presentations = (0..9).to_a.map { |n|
          Ag::Object.new("Presentation", n.to_s)
        }

        presentations.each do |presentation|
          produce Ag::Event.new({
            producer: steve,
            object: presentation,
            verb: "publish",
          })
        end

        events = adapter.timeline(john, offset: 5)
        assert_equal 5, events.size
        assert_equal presentations[0..4].reverse, events.map(&:object)
      end
    end
  end
end
