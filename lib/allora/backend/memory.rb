module Allora
  class Backend::Memory < Backend
    def initialize(opts = {})
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
