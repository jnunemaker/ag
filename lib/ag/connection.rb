require "forwardable"

module Ag
  class Connection
    extend Forwardable

    attr_reader :id
    attr_reader :producer
    attr_reader :consumer
    attr_reader :created_at

    def_delegator :@consumer, :id, :consumer_id
    def_delegator :@consumer, :type, :consumer_type

    def_delegator :@producer, :id, :producer_id
    def_delegator :@producer, :type, :producer_type

    def initialize(attributes = {})
      @id = attributes[:id]
      @producer = attributes[:producer]
      @consumer = attributes[:consumer]
      @created_at = attributes[:created_at]
    end
  end
end
