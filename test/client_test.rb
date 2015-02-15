require "helper"
require "ag/adapters/memory"

class ClientTest < Ag::Test
  def test_initializes_with_adapter
    adapter = Ag::Adapters::Memory.new
    client = Ag::Client.new(adapter)
    assert_instance_of Ag::Client, client
  end
end
