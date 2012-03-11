# Allora: A distributed cron daemon in ruby

Allora (*Italian: at that time*) allows you to run a cron scheduler (yes, the actual
scheduler) on multiple machines within a network, without the worry of multiple
machines processing the same job on the schedule.

A centralized backend is used (by default redis) in order to maintain a shared state.
Allora also provides a basic in-memory backend, which can be used to expressly allow
jobs to run on more than one machine (e.g. to perform some file cleanup operations
directly on the machine).

I am a firm believer in keeping it simple, so you'll find Allora weighs in at just
a couple of hundred SLOC and doesn't provide a bajillion features you aren't likely
to use.

Schedules are written in pure ruby, not YAML.

The scheduler process is reentrant.  That is to say, if the scheduler is due to run
a job at midnight and the process is stopped at 23:59, then restarted at 00:01, the
midnight job will still run.  Reentry is smart, however: it catches back up as soon
as it has processed any overdue jobs (so it doesn't get stuck in the past).

## Installation

Via rubygems:

    gem install allora

## Creating a schedule

The schedule is a ruby file.  You execute this ruby file to start the daemon running.

If you don't have ActiveSupport available, replace `1.hour`, for example with `3600`
(seconds).

Create a file, for example "schedule.rb":

    Allora.start(:join => true) do |s|
      # a job that runs hourly
      s.add("empty_cache", :every => 1.hour) { `rm -f /path/to/cache/*` }
      
      # a job that runs based on a cron string
      s.add("update_stats", :cron => "0 2,14 * * *") { Resque.enqueue(UpdateStatsJob) }
    end

When you run this file with ruby, it will remain in the foreground, providing log
output.  It is *currently* your responsibility to daemonize the process.

Note that the above example, we're only using the in-memory backend, so this
probably shouldn't be run on multiple machines.

In the following example, we specify to use a Redis backend, which is safe to run on
multiple machines:

    Allora.start(:backend => :redis, :host => "redis.lan", :join => true) do |s|
      # a job that runs hourly
      s.add("empty_cache", :every => 1.hour) { `rm -f /path/to/cache/*` }
      
      # a job that runs based on a cron string
      s.add("update_stats", :cron => "0 2,14 * * *") { Resque.enqueue(UpdateStatsJob) }
    end

We specify a redis host (and port) so that schedule data can be shared.

## Accessing your application environment

Allora will not make any assumptions about your application.  It is your responsibility
to load it, if you need it.  For Rails 3.x applications, add the following to the top
of your schedule:

    require File.expand_path("../config/environment", __FILE__)

Assuming "../config/environment" resolves to the actual path where your environment.rb is
found.

## Implementation notes

Disclaimer: The scheduler is not intended to be 100% accurate.  A job set to run every
second will probably run every second, but occasionally, if polling is slow, 2 seconds
may pass between runs.  If this is a problem for your application, you should not use
this gem.  The focus of this gem is to support running the scheduler on multiple machines.

In order to run the scheduler on more than one machine, Allora uses a `Backend` class to
maintain state.  The timestamp at which a job should next run is kept in the backend.
When the scheduler polls, it asks the backend to return any jobs that can be run *and*
update the time at which they should next run.  A locking strategy is used to ensure no
two machines update the schedule information at the same time.

In short, whichever running scheduler finds a job to do is the same scheduler the sets the
next time that job should run.

Jobs are executed in forked children, so that if they crash, the scheduler does not
exit.

## Custom Job classes

Allora offers two types of Job, which make sense for scheduling work at set intervals.
These are the `:every` and `:cron` types of job, which map to `Allora::Job::EveryJob` and
`Allora::Job::CronJob` internally.  You may write your own subclass of `Allora::Job`, if
you have some specific need that is not met by either of these job types.

Job classes simply need to implement the `#next_at` method, which accepts a `Time` as
input and returns a time after that at which the job should run.  `Allora::Job` will
handle the execution of the job itself.

Here's the implementation of the `EveryJob` class:

    module Allora
      class Job::EveryJob < Job
        def initialize(n, &block)
          @duration = n

          super(&block)
        end

        def next_at(from_time)
          from_time + @duration
        end
      end
    end

Quite simply it adds whatever the duration is to the given time.

To use your custom Job class, pass the instance to `Scheduler#add`:

    s.add("foo", MyJob.new { puts "Running custom job" })

## Custom Backend classes

It is more likely that you will wish to write a custom backend, than a custom job.  In
particular if you do not wish to use Redis, which is currently the only provided option.

Backend classes subclass `Allora::Backend` and implement `#reschedule`.  The `#reschedule`
method accepts a Hash of jobs to check and does two things:

  1. Returns a new Hash containing any jobs that can run now
  2. Internally updates the time at which the job should next run

A locking strategy should be used in order to ensure the backend supports running on
multiple machines.

For the sake of clarity and brevity, here is a pseudo-code example:

    class MyBackend < Allora::Backend
      def reschedule(jobs)
        now = Time.now
        jobs.select do |name, job|
          schedule_if_new(name, job.next_at(now))
          lock_job(name) do # returns the result of the block only if successful
            next_run = scheduled_time(name)
            if next_run <= now
              update_schedule(name, job.next_at(now))
              true
            else
              false
            end
          end
        end
      end
    end

The backend sets a new time into its internal schedule if none is present for that job.

It then tries to gain a lock on the schedule information for that job, returning false
if not possible (and this not selecting the job from the input Hash).

If a lock was acquired, the time at which the job should run is checked.  If it is in the
past, the scheule information is advanced to the next time at which the job should run and
the job is selected, else the job is not selected.

## Credits

Big thanks for jmettraux for rufus-scheduler, which I have borrowed the cron parsing logic
from.

## Disclaimer

Most of this work is the result of a quick code spike on a Sunday afternoon.  There are no
specs right now.  Use at your own risk.  I will add specs in the next day or two, if you
prefer to wait.

## Copyright & License

Copyright &copy; 2012 Flippa.com Pty. Ltd. See LICENSE file for details.
