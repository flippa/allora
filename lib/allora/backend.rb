module Allora
  class Backend
    attr_reader :options

    # Initialize the backend with the given options Hash.
    #
    # @param [Hash] opts
    #   options for the backend, if the backend requires any
    def initialize(opts = {})
      @options = opts
    end

    # Reschedules jobs in the given Hash and returns those that should run now.
    #
    # Subclasses should take an approach that tracks the run time information and updates
    # it in a way that avoids race conditions.  The job should not be run until it can be
    # guaranteed that it has been rescheduled for a future time and no other scheduler
    # process executed the job first.
    #
    # @param [Hash] jobs
    #   a Hash mapping job names with their job classes
    #
    # @return [Hash]
    #   a Hash containing the jobs to be run now, if any
    def reschedule(jobs)
      raise NotImplementedError, "Abstract method #reschedule must be implemented by subclass"
    end
  end
end
