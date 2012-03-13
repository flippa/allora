##
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Copyright &copy; 2012 Flippa.com Pty. Ltd.
##

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
    #   logger:   an instance of a ruby Logger, or nil to disable
    #   *other:   any additonal parameters are passed to the Backend
    #
    # @param [Hash] options
    #   options for the scheduler, if any
    def initialize(opts = {})
      require "logger"

      @backend  = create_backend(opts)
      @interval = opts.fetch(:interval, 0.333)
      @logger   = opts.fetch(:logger, default_logger)
      @jobs     = {}
    end

    # Register a new job for the given options.
    #
    # @example
    #   s.add("foo", :every => 5.seconds) { puts "Running!" }
    #   s.add("bar", :cron => "*/15 * 1,10,20 * *") { puts "Bonus!" }
    #
    # @param [String] name
    #   a unique name to give this job (used for locking)
    #
    # @param [Hash, Job] opts_or_job
    #   options specifying when to run the job (:every, or :cron), or a Job instance.
    #
    # @return [Job]
    #   the job instance added to the schedule
    def add(name, opts_or_job, &block)
      log "Loading into schedule '#{name}' #{opts_or_job.inspect}"

      jobs[name.to_s] = create_job(opts_or_job, &block)
    end

    # Starts running the scheduler in a new Thread, and returns that Thread.
    #
    # @return [Thread]
    #   the scheduler polling Thread
    def start
      log "Starting scheduler process, using #{@backend.class}"

      @thread = Thread.new do
        loop do
          @backend.reschedule(@jobs).each do |name, job|
            log "Running job '#{name}'"
            job.execute
          end

          sleep(@interval)
        end
      end
    end

    # Stop the currently running scheduler Thread
    def stop
      log "Exiting scheduler process"
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
      return opts if Job === opts

      raise ArgumentError "Missing schedule key (either :cron, or :every)" \
        unless opts.key?(:cron) || opts.key?(:every)

      if opts.key?(:every)
        Job::EveryJob.new(opts[:every], &block)
      elsif opts.key?(:cron)
        Job::CronJob.new(opts[:cron], &block)
      end
    end

    def create_backend(opts)
      return Backend::Memory.new unless opts.key?(:backend)

      case opts[:backend]
        when :memory then Backend::Memory.new
        when :redis  then Backend::Redis.new(opts)
        when Class   then opts[:backend].new(opts)
        when Backend then opts[:backend]
        else raise "Unsupported backend '#{opts[:backend].inspect}'"
      end
    end

    def log(str)
      @logger.info("Allora: #{str}") if @logger
    end

    def default_logger
      Logger.new(STDOUT).tap do |logger|
        logger.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime}: #{msg}\n"
        end
      end
    end
  end
end
