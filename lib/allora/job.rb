module Allora
  # Abstract job class providing a wrapper around job execution.
  #
  # Subclasses must be able to provide a time for the job to run,
  # given a start time.
  class Job
    attr_reader :block

    # Initialize the job with the given block to invoke during execution.
    def initialize(&block)
      @block = block
    end

    # Execute the job.
    #
    # Execution happens inside a forked and detached child.
    def execute
      Process.detach(fork { @block.call })
    end

    # Returns the next time at which this job should run.
    #
    # Subclasses must implement this method.
    #
    # @param [Time] from_time
    #   the time from which to calculate the next run time
    #
    # @return [Time]
    #   the time at which the job should next run
    def next_at(from_time)
      raise NotImplementedError, "Abstract method #next_at must be overridden by subclasses"
    end
  end
end
