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
  # A classic cron style job, with support for seconds.
  class Job::CronJob < Job
    # Initialize the CronJob with the given cron string.
    #
    # @param [String] cron_str
    #   any valid cron string, which may include seconds
    #
    # @example
    #   CronJob.new("*/5 * * * * *") # every 5s
    #   CronJob.new("0,30 * * * *")  # the 0th and 30th min of each hour
    #   CronJob.new("0 3-6 * * *")   # on the hour, every hour between 3am and 6am
    def initialize(cron_str, &block)
      super(&block)

      @cron_line = CronLine.new(cron_str)
    end

    def next_at(from_time)
      @cron_line.next_time(from_time)
    end
  end
end
