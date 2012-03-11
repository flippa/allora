require "allora/version"

require "allora/scheduler"

require "allora/backend"
require "allora/backend/memory"

require "allora/job"
require "allora/job/every_job"

module Allora
  class << self
    # Create a new Scheduler, yield it and then start it.
    #
    # If the `:join` option is specified, the scheduler Thread is joined.
    #
    # @params [Hash] opts
    #   options specifying a Backend to use, and any backend-specific options
    #
    # @return [Scheduler]
    #   the running scheduler
    def start(opts = {})
      Scheduler.new(opts).tap do |s|
        yield s
        s.start
        s.join if opts[:join]
      end
    end
  end
end
