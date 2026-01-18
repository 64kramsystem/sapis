=begin

<interactions_helper.rb> - Part of Sav's APIs.
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

module InteractionsHelper

  require 'highline/import'

  def self.secure_ask( question='Insert password: ' )
    HighLine.new.ask( question ) { | q | q.echo = '*' }
  end

  # Asks a question, optionally using a default.
  #
  # Format:
  #
  #  <header> [default]?
  #
  def self.ask_entry( header, default=nil )
    while true
      print "#{ header }"
      print " [#{ default }]" if default
      print "? "

      answer = STDIN.gets.chomp

      if answer = '' && default
        return default
      elsif answer != ''
        return answer
      end
    end
  end

  # Displays a numbered (or user-choosen) list of entries, in the format:
  #
  #   entry_a) value_a
  #   entry_b) value_b
  #
  # or
  #
  #   0) value_a
  #   1) value_b
  #
  # depending on <entries> being respectively a Hash or an Array.
  #
  # options:
  #   :default:            default entry, if the user doesn't choose
  #   :autochoose_if_one:  [false] automatically choose the entry if it's only one
  #   :filter_by:          [nil] String (for simplicity), which is matched case-insensitively.
  #                        If there are more matches and the pattern matches exactly one of
  #                        them, it's automatically chosen.
  #
  def self.ask_entries_with_points( header, entries, options={} )
    raise ArgumentError.new("No entries passed! [#{header}]") if entries.empty?

    default           = options[ :default ]
    autochoose_if_one = options[ :autochoose_if_one ]
    filtering_pattern = options[ :filter_by ]

    raise "Pattern must be a String, Regexp is not supported" if filtering_pattern.is_a?( Regexp )

    # Convert to Hash if it's an array
    #
    if entries.is_a?( Array )
      entries = ( 0 ... entries.size ).zip( entries )

      entries = entries.inject( {} ) do | current_entries, ( i, entry ) |
        current_entries[ i.to_s ] = entry
        current_entries
      end
    end

    if filtering_pattern
      exact_matches = entries.select { | _, entry_value | entry_value.downcase == filtering_pattern.downcase }

      return exact_matches.values.first if exact_matches.size == 1

      entries = entries.select { | _, entry_value | entry_value.downcase.include?( filtering_pattern.downcase ) }

      raise ArgumentError.new("No entries after filtering! [#{header}, #{filtering_pattern}]") if entries.empty?
    end

    if entries.size == 1 && (autochoose_if_one || filtering_pattern)
      return entries.values.first
    end

    while true
      puts "#{ header }:"

      entries.each do | point, entry |
        print " #{ point }"
        print default.to_s == entry ? '*' : ')'
        puts " #{ entry }"
      end

      answer = STDIN.gets.chomp

      if answer == '' && default
        break default
      elsif entries.has_key?( answer )
        break entries[ answer ]
      end
    end
  end

  # Displays a list of entries, in the format:
  #
  #   header: entry_a,entry_b [default]?
  #
  def self.ask_entries_in_line( header, entries, default=nil )
    while true
      print "#{ header }: "

      print entries.join( ',' )

      print " [#{ default }]" if default

      print "? "

      answer = STDIN.gets.chomp

      if answer == '' && default
        break default
      elsif entries.include?( answer )
        break answer
      end
    end
  end

end

