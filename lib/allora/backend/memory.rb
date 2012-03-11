module Allora
  # A basic, single-process backend using a Hash.
  #
  # You should not run this on multiple machines on the same network.
  class Backend::Memory < Backend
    # Initialize a new Memory backend.
    #
    # @params [Hash] opts
    #   this backend does not accept any options
    def initialize(opts = {})
      super

      @schedule = {}
    end

    def reschedule(jobs)
      current_time = Time.now
      last_time    = (@last_time ||= Time.now)
      @last_time   = current_time

      jobs.select do |name, job|
        @schedule[name] ||= job.next_at(last_time)
        @schedule[name] < current_time && @schedule[name] = job.next_at(current_time)
      end
    end
  end
end
