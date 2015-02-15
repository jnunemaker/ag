module Ag
  class Event
    attr_reader :id
    attr_reader :producer
    attr_reader :object
    attr_reader :verb
    attr_reader :created_at

    def initialize(attrs = {})
      @id = attrs[:id]
      @producer = attrs.fetch(:producer)
      @object = attrs.fetch(:object)
      @verb = attrs.fetch(:verb)
      @created_at = attrs.fetch(:created_at) { Time.now.utc }
    end
  end
end
