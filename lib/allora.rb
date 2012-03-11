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

require "allora/version"

require "allora/scheduler"

require "allora/backend"
require "allora/backend/memory"
require "allora/backend/redis"

require "allora/cron_line"

require "allora/job"
require "allora/job/every_job"
require "allora/job/cron_job"

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
