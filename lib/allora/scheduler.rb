module Allora
  # Worker daemon, dealing with a Backend to execute jobs at regular intervals.
  class Scheduler
    attr_reader :jobs
    attr_reader :backend

    # Initialize the Scheduler with the given options.
    #
    # Options:
    #   backend:  an instance of any Backend class (defaults to Memory)
    #   interval: a floating point specifying how frequently to poll (defaults to 0.333)
    #   *other:   any additonal parameters are passed to the Backend
    #
    # @param [Hash] options
    #   options for the scheduler, if any
    def initialize(opts = {})
      @backend  = opts.fetch(:backend, Backend::Memory.new)
      @interval = opts.fetch(:interval, 0.333)
      @jobs     = {}
    end

    # Register a new job for the given options.
    #
    # Options:
    #   every: a number of seconds at which to repeat the job
    #   cron:  a cron string specifying how often to repeat the job
    #
    # @param [String] name
    #   a unique name to give this job (used for locking)
    #
    # @param [Hash] opts
    #   options specifying when to run the job (:every, or :cron)
    #
    # @return [Job]
    #   the job instance added to the schedule
    def add(name, opts = {}, &block)
      jobs[name.to_s] = create_job(opts, &block)
    end

    # Starts running the scheduler in a new Thread, and returns that Thread.
    #
    # @return [Thread]
    #   the scheduler polling Thread
    def start
      @thread = Thread.new do
        loop do
          @backend.reschedule(@jobs).each { |name, job| job.execute }

          sleep(@interval)
        end
      end
    end

    # Stop the currently running scheduler Thread
    def stop
      @thread.exit
    end

    # Join the currently running scheduler Thread.
    #
    # This should be invoked to prevent the parent Thread from terminating.
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
