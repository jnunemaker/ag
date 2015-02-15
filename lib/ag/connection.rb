require "forwardable"

module Ag
  class Connection
    attr_reader :id
    attr_reader :producer
    attr_reader :consumer
    attr_reader :created_at

    def initialize(attributes = {})
      @id = attributes[:id]
      @producer = attributes[:producer]
      @consumer = attributes[:consumer]
      @created_at = attributes[:created_at]
    end
  end
end
