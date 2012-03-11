module Allora
  class Scheduler
    attr_reader :jobs
    attr_reader :backend

    def initialize(opts)
      @backend  = opts.fetch(:backend, Backend::Memory.new)
      @interval = opts.fetch(:interval, 0.333)
      @jobs     = {}
    end

    def add(name, opts = {}, &block)
      jobs[name] = create_job(opts, &block)
    end

    def start
      @thread = Thread.new do
        loop do
          @backend.reschedule(@jobs).each { |name, job| job.execute }

          sleep(@interval)
        end
      end
    end

    def stop
      @thread.exit
    end

    def join
      @thread.join
    end

    private

    def create_job(opts, &block)
      raise ArgumentError "Missing schedule key (either :cron, or :every)" \
        unless opts[:cron] || opts[:every]

      if opts[:every]
        Job::EveryJob.new(opts[:every], &block)
      elsif opts[:cron]
        Job::CronJob.new(opts[:cron], &block)
      end
    end
  end
end
