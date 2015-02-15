module Ag
  class Event
    attr_reader :producer
    attr_reader :object
    attr_reader :verb
    attr_reader :created_at

    def initialize(attrs = {})
      @producer = attrs.fetch(:producer)
      @verb = attrs.fetch(:verb)
      @object = attrs.fetch(:object)
      @created_at = attrs.fetch(:created_at) { Time.now.utc }
    end

    def to_hash
      {
        producer_type: @producer.type,
        producer_id: @producer.id,
        object_type: @object.type,
        object_id: @object.id,
        verb: @verb,
        created_at: @created_at,
      }
    end
  end
end
