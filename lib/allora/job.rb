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
  # Abstract job class providing a wrapper around job execution.
  #
  # Subclasses must be able to provide a time for the job to run,
  # given a start time.
  class Job
    attr_reader :block

    # Initialize the job with the given block to invoke during execution.
    def initialize(&block)
      @block = block
    end

    # Execute the job.
    #
    # Execution happens inside a forked and detached child.
    def execute
      Process.detach(fork { @block.call })
    end

    # Returns the next time at which this job should run.
    #
    # Subclasses must implement this method.
    #
    # @param [Time] from_time
    #   the time from which to calculate the next run time
    #
    # @return [Time]
    #   the time at which the job should next run
    def next_at(from_time)
      raise NotImplementedError, "Abstract method #next_at must be overridden by subclasses"
    end
  end
end
