#--
# Copyright (c) 2006-2012, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

# This is almost entirely lifted from https://github.com/jmettraux/rufus-scheduler/blob/master/lib/rufus/sc/cronline.rb
module Allora
  # Parses a crontab string to determine the times it represents.
  class CronLine
    attr_reader :seconds
    attr_reader :minutes
    attr_reader :hours
    attr_reader :days
    attr_reader :months
    attr_reader :weekdays
    attr_reader :monthdays
    attr_reader :timezone

    def initialize(line)
      items = line.split

      raise ArgumentError.new("not a valid cronline : '#{line}'") \
        unless items.length == 5 or items.length == 6

      offset = items.length - 5

      @seconds = offset == 1 ? parse_item(items[0], 0, 59) : [0]
      @minutes = parse_item(items[0 + offset], 0, 59)
      @hours   = parse_item(items[1 + offset], 0, 24)
      @days    = parse_item(items[2 + offset], 1, 31)
      @months  = parse_item(items[3 + offset], 1, 12)

      @weekdays, @monthdays = parse_weekdays(items[4 + offset])
    end

    # Returns the next time that this cron line is supposed to 'fire'
    #
    # Note that the time instance returned will be in the same time zone that
    # the given start point Time (thus a result in the local time zone will
    # be passed if no start time is specified (search start time set to
    # Time.now))
    #
    # @example
    #
    #   Allora::CronLine.new('30 7 * * *').next_time(
    #     Time.mktime(2008, 10, 24, 7, 29))
    #   #=> Fri Oct 24 07:30:00 -0500 2008
    #
    #   Allora::CronLine.new('30 7 * * *').next_time(
    #     Time.utc(2008, 10, 24, 7, 29))
    #   #=> Fri Oct 24 07:30:00 UTC 2008
    #
    #   Allora::CronLine.new('30 7 * * *').next_time(
    #     Time.utc(2008, 10, 24, 7, 29)).localtime
    #   #=> Fri Oct 24 02:30:00 -0500 2008
    #
    # @param [Time] time
    #   the time from which to compute the next time
    #
    # @return [Time]
    #   the next time after the given Time
    def next_time(time)
      # little adjustment before starting
      time = time + 1

      loop do
        unless date_match?(time)
          time += (24 - time.hour) * 3600 - time.min * 60 - time.sec
          next
        end
        unless sub_match?(time.hour, @hours)
          time += (60 - time.min) * 60 - time.sec
          next
        end
        unless sub_match?(time.min, @minutes)
          time += 60 - time.sec
          next
        end
        unless sub_match?(time.sec, @seconds)
          time += 1
          next
        end

        break
      end

      time
    end

    def to_array
      [
        @seconds,
        @minutes,
        @hours,
        @days,
        @months,
        @weekdays,
        @monthdays
      ]
    end

    private

    WEEKDAYS = %w[ sun mon tue wed thu fri sat ]

    def parse_weekdays(item)
      return nil if item == '*'

      items = item.downcase.split(',')

      weekdays = nil
      monthdays = nil

      items.each do |it|
        if it.match(/#[12345]$/)
          raise ArgumentError.new(
            "ranges are not supported for monthdays (#{it})"
          ) if it.index('-')

          (monthdays ||= []) << it
        else
          WEEKDAYS.each_with_index { |a, i| it.gsub!(/#{a}/, i.to_s) }

          its = it.index('-') ? parse_range(it, 0, 7) : [Integer(it)]
          its = its.collect { |i| i == 7 ? 0 : i }

          (weekdays ||= []).concat(its)
        end
      end

      weekdays = weekdays.uniq if weekdays

      [weekdays, monthdays]
    end

    def parse_item(item, min, max)
      return nil                         if item == '*'
      return parse_list(item, min, max)  if item.index(',')
      return parse_range(item, min, max) if item.index('*') or item.index('-')

      i = item.to_i

      i = min if i < min
      i = max if i > max

      [i]
    end

    def parse_list(item, min, max)
      item.split(',').inject([]) { |r, i|
        r.push(parse_range(i, min, max))
      }.flatten
    end

    def parse_range(item, min, max)
      i = item.index('-')
      j = item.index('/')

      return item.to_i if (not i and not j)

      inc = j ? item[j + 1..-1].to_i : 1

      istart = -1
      iend = -1

      if i
        istart = item[0..i - 1].to_i
        iend   = if j
          item[i + 1..j - 1].to_i
        else
          item[i + 1..-1].to_i
        end
      else # case */x
        istart = min
        iend = max
      end

      istart = min if istart < min
      iend   = max if iend > max

      result = []

      value = istart
      loop do
        result << value
        value = value + inc
        break if value > iend
      end

      result
    end

    def sub_match?(value, values)
      values.nil? || values.include?(value)
    end

    def monthday_match(monthday, monthdays)
      return true if monthdays == nil
      return true if monthdays.include?(monthday)
    end

    def date_match?(date)
      return false unless sub_match?(date.day, @days)
      return false unless sub_match?(date.month, @months)
      return false unless sub_match?(date.wday, @weekdays)
      return false unless sub_match?(CronLine.monthday(date), @monthdays)
      true
    end

    DAY_IN_SECONDS = 7 * 24 * 3600

    def self.monthday(date)
      count = 1
      date2 = date.dup

      loop do
        date2 = date2 - DAY_IN_SECONDS
        break if date2.month != date.month
        count = count + 1
      end

      "#{WEEKDAYS[date.wday]}##{count}"
    end
  end
end
