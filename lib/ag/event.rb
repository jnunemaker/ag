require "forwardable"

module Ag
  class Event
    extend Forwardable

    attr_reader :producer
    attr_reader :object
    attr_reader :verb
    attr_reader :created_at

    def_delegator :@producer, :id, :producer_id
    def_delegator :@producer, :type, :producer_type

    def_delegator :@object, :id, :object_id
    def_delegator :@object, :type, :object_type

    def initialize(attrs = {})
      @producer = attrs.fetch(:producer)
      @object = attrs.fetch(:object)
      @verb = attrs.fetch(:verb)
      @created_at = attrs.fetch(:created_at) { Time.now.utc }
    end
  end
end
