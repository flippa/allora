module Allora
  class Job
    attr_reader :block

    def initialize(&block)
      @block = block
    end

    def execute
      @block.call
    end

    def next_at(from_time)
      raise NotImplementedError, "Abstract method #next_at must be overridden by subclasses"
    end
  end
end
