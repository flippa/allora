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
  # A backend that uses Redis to maintain schedule state.
  #
  # When using this backend, it is possible to run the scheduler process
  # on more than one machine in the network, connected to the same Redis
  # instace. Whichever scheduler finds a runnable job first updates the
  # 'next run time' information in Redis, using an optimistic locking
  # strategy, then executes the job if the write succeeds.  No two
  # machines will ever run the same job twice.
  class Backend::Redis < Backend
    attr_reader :redis
    attr_reader :prefix

    # Initialize the Redis backed with the given options.
    #
    # Options:
    #   client: an already instantiated Redis client object.
    #   host:   the hostname of a Redis server
    #   port:   the port number of a Redis server
    #   prefix: a namespace prefix to use
    #   reset:  delete existing job timing keys in Redis
    #
    # @param [Hash] opts
    #   options for the Redis backend
    def initialize(opts = {})
      @redis  = create_redis(opts)
      @prefix = opts.fetch(:prefix, "allora")

      reset! if opts.fetch(:reset, true)
    end

    def reschedule(jobs)
      current_time = Time.now
      last_time    = send(:last_time)
      set_last_time(current_time)

      jobs.select do |name, job|
        redis.setnx(job_info_key(name), time_to_int(job.next_at(last_time)))
        update_job_info(job, name, current_time)
      end
    end

    private

    def create_redis(opts)
      return opts[:client] if opts.key?(:client)

      ::Redis.new(redis_opts(opts).merge(:thread_safe => true))
    end

    def redis_opts(opts)
      keys = [:host, :port, :db, :url, :path, :password]
      keys.each_with_object({}) { |k, hash| hash[k] = opts[k] if opts.has_key?(k) }
    end

    # Forces all job data to be re-entered into Redis at the next poll
    def reset!
      redis.keys(job_info_key("*")).each { |k| redis.del(k) }
    end

    # Returns a Boolean specifying if the job can be run and no race condition occurred updating its info
    def update_job_info(job, name, time)
      redis.watch(job_info_key(name))
      run_at = int_to_time(redis.get(job_info_key(name)))

      if run_at <= time
        redis.multi do
          redis.set(job_info_key(name), time_to_int(job.next_at(time)))
        end
      else
        redis.unwatch && false
      end
    end

    def job_info_key(name)
      "#{prefix}_job_#{name}"
    end

    def last_time_key
      "#{prefix}_last_run"
    end

    # Returns the last time at which polling occurred
    #
    # This is used as a re-entry mechanism if the scheduler stops
    def last_time
      redis.setnx(last_time_key, time_to_int(Time.now))
      int_to_time(redis.get(last_time_key))
    end

    def set_last_time(t)
      redis.set(last_time_key, time_to_int(t))
    end

    def time_to_int(t)
      t.to_i
    end

    def int_to_time(i)
      Time.at(i.to_i)
    end
  end
end
