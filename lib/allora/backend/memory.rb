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
  # A basic, single-process backend using a Hash.
  #
  # You should not run this on multiple machines on the same network.
  class Backend::Memory < Backend
    # Initialize a new Memory backend.
    #
    # @params [Hash] opts
    #   this backend does not accept any options
    def initialize(opts = {})
      super

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
