=begin

<generic_helper.rb> - Part of Sav's APIs.
Copyright (C) 2011 Saverio Miroddi

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=end

require 'date'

module GenericHelper
  def self.do_retry(options={}, &block)
    max_retries    = options[:max_retries] || 3
    sleep_interval = options[:sleep] || 0

    current_retries = 0

    begin
      yield
    rescue
      current_retries += 1

      if current_retries <= max_retries
        sleep sleep_interval
        retry
      end

      raise
    end
  end

  # Trivial version. Can easily be done with a regex.
  #
  def self.camelize(string)
    buffer          = ""
    capitalize_next = true

    string.chars.each do |char|
      if char == '_'
        capitalize_next = true
      elsif capitalize_next
        buffer << char.upcase
        capitalize_next = false
      else
        buffer << char
      end
    end

    buffer
  end

  # options:
  #
  # :past: [false] the date can be future (supported only by some cases)
  #
  # Format:
  #
  #   'YYYY-MM-DD', 'YYYYMMDD', 'MMM/DD/YYYY', 'MMM/D(D)', 'D(D)/MMM' (curr. year), 'MMDD' (curr. year)
  #   'to[day]', 'ye[sterday]', 'mon' (monday), 'tue-' (last tuesday),
  #   '+3' (today+3), '-2' (today-2)
  #
  # Note that the easiest way to pass '-<value>' in bash, is to use '--' (end of options).
  #
  def decode_date(encoded_date, future: true)
    case encoded_date.downcase
    # YYYY-MM-DD
    when %r{^(\d\d\d\d)-(\d\d)-(\d\d)$}
      Date.new($1.to_i, $2.to_i, $3.to_i)
    # YYYYMMDD
    when /^(\d\d\d\d)(\d\d)(\d\d)$/
      Date.new($1.to_i, $2.to_i, $3.to_i)
    # MMM/DD/YYYY
    when %r{^(\w{3})/(\d\d)/(\d\d\d\d)$}
      month_index_for_time = Date.strptime($1, "%b").month
      Date.new($3.to_i, month_index_for_time, $2.to_i)
    # MMM/D(D) (+future)
    when %r{^(\w{3})\/(\d{1,2})$}
      month_index_for_time = Date.strptime($1, "%b").month
      Date.new(Date.today.year, month_index_for_time, $2.to_i)
        .then { !future && it > Date.today ? it << 12 : it }
    # D(D)/MMM/YYYY
    when %r{^(\d{1,2})/(\w{3})/(\d\d\d\d)$}
      month_index_for_time = Date.strptime($2, "%b").month
      Date.new($3.to_i, month_index_for_time, $1.to_i)
    # D(D)/MMM
    when %r{^(\d{1,2})\/(\w{3})$}
      month_index_for_time = Date.strptime($2, "%b").month
      Date.new(Date.today.year, month_index_for_time, $1.to_i)
    # MMDD
    when /^(\d\d)(\d\d)$/
      Date.new(Time.now.year, $1.to_i, $2.to_i)
    when 'to', 'today'
      Date.today
    when 'ye', 'yesterday'
      Date.today - 1
    when /^(sun|mon|tue|wed|thu|fri|sat)$/
      diff = (Date.strptime($1, "%a") - Date.today).to_i
      diff += 7 if diff <= 0
      Date.today + diff
    when /^(sun|mon|tue|wed|thu|fri|sat)-$/
      diff = (Date.strptime($1, "%a") - Date.today).to_i
      diff -= 7 if diff >= 0
      Date.today + diff
    when /^\+(\d+)$/
      Date.today + $1.to_i
    when /^-(\d+)$/
      Date.today - $1.to_i
    else
      raise "Unrecognized date: #{encoded_date}"
    end
 end

  # Params:
  #
  #   day, start, end
  #
  # Format:
  #
  #  * DAY:   'YYYY-MM-DD', 'YYYYMMDD', 'MMDD', 'to[day]', 'ye[sterday]', 'thu' (thursday of the current week), 'mon-' (last monday), 'tue+' (next tuesday), 'MMM/DD'
  #  * START: 'HH', 'HH:MM'
  #  * END:   '3d', '2h', '45m', 'HH', 'HH:MM'
  #
  # Possible combinations:
  #
  #  * (nothing)          all today
  #  * DAY                on the day, for all day
  #  * DAY,END            from day to end, for all day
  #  * DAY,START,END      on the day, from start to end
  #  * START,END          today, from start to end
  #
  # Note that the 'current week' starts on Sunday.
  #==
  # In the regexes, numbered repetitions ('{n}') are not used for consistency.
  #
  # The Date class pretty much sucks. Between the other things, it doesn't accept string
  # values when instantiating.
  #
  def decode_interval(*daytime)
    current_token = daytime.shift

    if current_token
      base_day = decode_date(current_token)

      if base_day.nil?
        base_day = Date.today
        daytime.unshift(current_token)
      end
    else
      base_day = Date.today
      daytime.unshift(current_token)
    end

    raise "Wrong start year format. Non-consumed tokens: #{daytime}" if base_day.nil?

    current_token = daytime.shift

    # The next token could be both a start (e.g. DAY,START,END) or an END (e.g. DAY,END).
    # Since we can't rely on character patterns because of the HH:MM case, we rely on the
    # number of tokens: START can be present only if at this point there are two tokens.
    #
    if daytime.size == 1
      case current_token
      when /^(\d{1,2})$/
        start_daytime = Time.local(base_day.year, base_day.month, base_day.day, $1)
      when /^(\d{1,2}):(\d\d)$/
        start_daytime = Time.local(base_day.year, base_day.month, base_day.day, $1, $2)
      else
        daytime.unshift(current_token)
      end

      all_day = false
    else
      start_daytime = Time.local(base_day.year, base_day.month, base_day.day)
      all_day = true
      daytime.unshift(current_token)
    end

    raise "Wrong start daytime format. Non-consumed tokens: #{daytime}" if start_daytime.nil?

    current_token = daytime.shift

    if current_token
      if all_day
        # Only full days allowed in case of all-day timespan
        #
        if current_token =~ /^(\d+)d$/
          end_daytime = add_days(start_daytime, $1.to_i)
        else
          daytime.unshift(current_token)
        end
      else
        case current_token.downcase
        when /^(\d+)d$/
          end_daytime = start_daytime + $1.to_i * 24 * 60 * 60
        when /^(\d+)h$/
          end_daytime = start_daytime + $1.to_i * 60 * 60
        when /^(\d+)m$/
          end_daytime = start_daytime + $1.to_i * 60
        when /^(\d{1,2})$/
          end_daytime = Time.local(start_daytime.year, start_daytime.month, start_daytime.day, $1)
        when /^(\d{1,2}):(\d\d)$/
          end_daytime = Time.local(start_daytime.year, start_daytime.month, start_daytime.day, $1, $2)
        else
          daytime.unshift(current_token)
        end
      end
    else
      # We're here if none of START/END have been passed; we default to +1 day.
      # At this point, there are no tokens to unshift
      #
      end_daytime = add_days(start_daytime, 1)
    end

    raise "Wrong end daytime format. Non-consumed tokens: #{daytime}" if end_daytime.nil?

    raise "Non-consumed tokens found: #{daytime}" if daytime.size > 0

    [start_daytime, end_daytime, all_day]
  end

  private

  # Add the given days, ignoring the daylight saving.
  #
  def add_days(base_time, days)
    result_date = Date.new(base_time.year, base_time.month, base_time.day) + days
    Time.local(result_date.year, result_date.month, result_date.day)
  end
end
