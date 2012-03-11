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
  class Backend
    attr_reader :options

    # Initialize the backend with the given options Hash.
    #
    # @param [Hash] opts
    #   options for the backend, if the backend requires any
    def initialize(opts = {})
      @options = opts
    end

    # Reschedules jobs in the given Hash and returns those that should run now.
    #
    # Subclasses should take an approach that tracks the run time information and updates
    # it in a way that avoids race conditions.  The job should not be run until it can be
    # guaranteed that it has been rescheduled for a future time and no other scheduler
    # process executed the job first.
    #
    # @param [Hash] jobs
    #   a Hash mapping job names with their job classes
    #
    # @return [Hash]
    #   a Hash containing the jobs to be run now, if any
    def reschedule(jobs)
      raise NotImplementedError, "Abstract method #reschedule must be implemented by subclass"
    end
  end
end
