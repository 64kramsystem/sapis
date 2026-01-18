=begin

<graphing_helper.rb> - Part of Sav's APIs.
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

module GraphingHelper

  require 'gruff'
  require 'tempfile'

  # Transpose from format:
  #
  #   label1, labelN, <ignored>
  #   value,  value,  day1
  #   value,  value,  day2
  #
  # <source_data> is destroyed.
  # Labels must be unique.
  # Days can be either a string or a Date.
  #
  def self.transpose_data_top_headers( source_data, options={} )
    fill_missing_days = ! options.has_key?( :fill_missing_days ) || !! options[ :fill_missing_days ]

    labels = source_data.shift[ 0...-1 ]

    source_data.each { | row | row[ row.size - 1 ] = Date.strptime( row.last ) unless row.last.is_a?( Date ) }

    min_day = source_data.map { | row | row.last }.min
    max_day = source_data.map { | row | row.last }.max

    # Pre-fill the output matrix (hash)

    output_data = labels.inject( {} ) do | current_output_data, label |
      current_output_data[ label ] = [ nil ] * ( max_day - min_day )
      current_output_data
    end

    # Fill the values

    source_data.each do | row |
      day = row.last

      labels.each_with_index do | label, i |
        output_data[ label ][ day - min_day ] = row[ i ]
      end
    end

    # Apply final manipulations and convert output data to array

    output_data.each { | label, values | values.compact! } if ! fill_missing_days

    output_data = output_data.map { | label, values | [ label, values ] }
    days        = ( min_day..max_day ).to_a

    [ output_data, days ]
  end

  # Transpose from format:
  #
  #   label1, value,  day1
  #   labelM, value,  day2
  #   label1, value,  day3
  #   labelN, value,  day3
  #
  def self.transpose_data_left_headers( source_data )
    source_data.each { | row | row[ row.size - 1 ] = Date.strptime( row.last ) unless row.last.is_a?( Date ) }

    # Fill a map day => { label => value, ... }

    data_by_day_by_label = {}

    source_data.each do | label, value, day |
      day = Date.strptime( day ) unless day.is_a?( Date )

      data_by_day_by_label[ day ] ||= {}
      data_by_day_by_label[ day ][ label ] = value
    end

    # Convert to tabular form by label

    labels = source_data.map { | row | row.first }.uniq

    output_data = labels.inject( {} ) do | current_output_data, label |
      current_output_data[ label ] = []
      current_output_data
    end

    days = data_by_day_by_label.keys.sort

    days.each do | day |
      labels_values = data_by_day_by_label[ day ]

      labels.each do | label |
        value = labels_values[ label ]
        output_data[ label ] << value
      end
    end

    # Apply final manipulations and convert output data to array

    output_data = output_data.map { | label, values | [ label, values ] }

    [ output_data, days ]
  end

  # Ouput a line graph, optionally to a file.
  #
  # Assumes that the row contains the headers.
  #
  # options:
  #  :out_file               output file. if not passed, the graph is displayed live
  #
  def self.format_as_line_graph( data, days, options={} )
    out_file = options[ :out_file     ]

    graph = Gruff::Line.new

    data.each { | label_data | graph.data( *label_data ) }

    graph.labels = {
      0             => days.first.to_s,
      days.size - 1 => days.last.to_s,
    }

    if out_file
      graph.write( out_file )
    else
      Tempfile.open( 'tracking_graph' ) do | f |
        # Base#write doesn't work because the tempfile doesn't have any extension
        #
        rendered_data = graph.to_blob
        f << rendered_data

        images_display_app = get_images_display_app
        `#{ images_display_app } #{ f.path }`
      end
    end
  end

  # Assumes that the number of fields for each row is constant.
  #
  # options:
  #  :separator    default: '|'
  #  :align        hash { <field> => :left }. makes sense only if the first row is the headers.
  #
  def self.format_as_table( rows, options={} )
    return "" if rows.empty?

    separator = options[ :separator ] || '|'
    align     = options[ :align     ] || {}

    max_field_sizes   = nil
    alignment_symbols = nil

    rows.each_with_index do | row, row_num |
      if row_num == 0
        max_field_sizes   = row.map { | value | value.to_s.size }
        alignment_symbols = row.map { | value | '-' if align[ value ] == :left }
      else
        row.each_with_index do | value, value_pos |
          max_field_sizes[ value_pos ] = value.to_s.size if value.to_s.size > max_field_sizes[ value_pos ]
        end
      end
    end

    template = separator + max_field_sizes.zip( alignment_symbols ).map { | size, alignment_symbol | " %#{ alignment_symbol }#{ size }s #{ separator }" }.join

    rows.inject( "" ) do | buffer, row |
      buffer << template % row << "\n"
    end
  end

  private

  def self.get_images_display_app
    case RUBY_PLATFORM
    when /linux/
      'eog'
    when /darwin/
      'open -W'
    else
      raise "Unsupported platform: #{ RUBY_PLATFORM }"
    end
  end

end

