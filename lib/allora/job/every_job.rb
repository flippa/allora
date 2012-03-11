module Allora
  # A very simple job type that simply repeats every +n+ seconds.
  class Job::EveryJob < Job
    # Initialize the job to run every +n+ seconds.
    #
    # @param [Integer] n
    #   the number of seconds to wait between executions
    #
    # You may use ActiveSupport's numeric helpers, if you have ActiveSupport
    # available.
    #
    # @example Using ActiveSupport
    #   EveryJob.new(15.seconds) { puts "Boo!" }
    #
    def initialize(n, &block)
      @duration = n

      super(&block)
    end

    def next_at(from_time)
      from_time + @duration
    end
  end
end
