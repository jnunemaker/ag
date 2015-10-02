module Ag
  class Object
    Separator = ":".freeze

    def self.from_key(key, separator = Separator)
      new(*key.split(Separator))
    end

    attr_reader :type
    attr_reader :id

    def initialize(type, id)
      @type = type
      @id = id
    end

    def key(*suffixes)
      [@type, @id].concat(Array(suffixes)).join(Separator)
    end

    def ==(other)
      self.class == other.class &&
        self.type == other.type &&
        self.id == other.id
    end
  end
end
