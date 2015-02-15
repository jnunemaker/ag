module Ag
  class Actor
    attr_reader :type
    attr_reader :id

    def initialize(type, id)
      @type = type
      @id = id
    end

    def ==(other)
      self.class == other.class &&
        self.type == other.type &&
        self.id == other.id
    end
  end
end
