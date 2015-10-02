require_relative "../helper"
require "ag/adapters/memory"
require "ag/spec/adapter"
require "securerandom"

class AdaptersMemoryTest < Ag::Test
  def setup
    @source = {}
  end

  def adapter
    @adapter ||= Ag::Adapters::Memory.new(@source)
  end

  include Ag::Spec::Adapter
end
