require "allora/version"

require "allora/scheduler"

require "allora/backend"
require "allora/backend/memory"

require "allora/job"
require "allora/job/every_job"

module Allora
  class << self
    def start(opts = {})
      Scheduler.new(opts).tap do |s|
        yield s
        s.start
        s.join if opts[:join]
      end
    end
  end
end
