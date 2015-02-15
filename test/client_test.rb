require "helper"

class ClientTest < Ag::Test
  def test_initializes_with_adapter
    adapter = Ag::Adapters::Memory.new
    client = Ag::Client.new(adapter)
    assert_instance_of Ag::Client, client
  end

  def test_forwards_connect_to_adapter
    args = [consumer, producer]
    result = true
    mock_adapter = Minitest::Mock.new
    mock_adapter.expect(:connect, result, args)

    client = Ag::Client.new(mock_adapter)
    assert_equal result, client.connect(*args)

    mock_adapter.verify
  end

  def test_forwards_connected_to_adapter
    args = [consumer, producer]
    result = true
    mock_adapter = Minitest::Mock.new
    mock_adapter.expect(:connected?, result, args)

    client = Ag::Client.new(mock_adapter)
    assert_equal result, client.connected?(*args)

    mock_adapter.verify
  end

  def test_forwards_consumers_to_adapter
    args = [producer]
    result = [consumer]
    mock_adapter = Minitest::Mock.new
    mock_adapter.expect(:consumers, result, args)

    client = Ag::Client.new(mock_adapter)
    assert_equal result, client.consumers(*args)

    mock_adapter.verify
  end

  def test_forwards_producers_to_adapter
    args = [consumer]
    result = [producer]
    mock_adapter = Minitest::Mock.new
    mock_adapter.expect(:producers, result, args)

    client = Ag::Client.new(mock_adapter)
    assert_equal result, client.producers(*args)

    mock_adapter.verify
  end

  def test_forwards_producers_to_adapter
    args = [event]
    result = [producer]
    mock_adapter = Minitest::Mock.new
    mock_adapter.expect(:producers, result, args)

    client = Ag::Client.new(mock_adapter)
    assert_equal result, client.producers(*args)

    mock_adapter.verify
  end

  private

  def event
    @event ||= Ag::Event.new({
      producer: producer,
      object: object,
      verb: verb,
    })
  end

  def verb
    "follow"
  end

  def consumer
    @consumer ||= Ag::Consumer.new("User", "1")
  end

  def producer
    @producer ||= Ag::Producer.new("User", "1")
  end

  def object
    @object ||= Ag::Object.new("User", "2")
  end
end
