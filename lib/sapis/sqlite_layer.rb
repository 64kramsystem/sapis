=begin

<sqlite_layer.rb> - Part of Sav's APIs.
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

require 'sqlite3'

# In block form, transaction don't accept the :rollback call, so we need to use an exception.
#
class Rollback < StandardError; end

class SQLiteLayer
  attr_reader :db

  def initialize( filename, options={} )
    absolute_db_filename = options[ :relative ] ? File.expand_path( filename, '~' ) : filename

    @db = SQLite3::Database.new( absolute_db_filename )

    @db.execute( 'PRAGMA foreign_keys = ON' )
  end

  # values: Can be either an array of values, or a hash field=>value.
  #         In order to insert BLOBs, pass a value enclosed in an array, e.g. ['mydata']
  #
  # Doesn't try to be clever.
  #
  # options:
  #   :straight_insert        hash of values (position => value) to insert straight, without placeholders.
  #                           values are not automatically escaped or quoted.
  #                           this makes sense for some edge cases.
  #
  def insert_values( table, values, options={} )
    straight_insert = options[ :straight_insert ] || {}

    sql_fields       = []
    sql_placeholders = []
    sql_values       = []

    case values
    when Hash
      values.each do | field, value |
        sql_fields       << field.to_s
        sql_placeholders << '?'
        sql_values       <<  value
      end
    when Array
      values.each do | value |
        sql_placeholders << '?'
        sql_values       <<  value
      end
    else
      raise "Invalid values class: #{ values.class }"
    end

    straight_insert.each do | field, value |
      sql_fields       << field.to_s
      sql_placeholders << value
    end

    sql_values.each_with_index do | value, i |
      sql_values[ i ] = SQLite3::Blob.new( value.first ) if value.is_a?( Array )
    end

    sql = "INSERT INTO #{ table }"
    sql << "( #{ sql_fields.join(', ') } )" if sql_fields.size > 0
    sql << " VALUES( #{ sql_placeholders.join(', ') } )"

    @db.execute( sql, sql_values )

    @db.last_insert_row_id
  end

  # values:   the :where key is the where condition
  #
  def update_values( table, values )
    where_sql = values.delete( :where ) || 'TRUE'

    set_sql, set_values = values.inject( [ "", [] ] ) do | ( current_set_sql, current_set_values ), ( column, value ) |
      current_set_sql << ', ' if current_set_sql != ''
      current_set_sql << "#{ column } = ?"
      current_set_values << value
      [ current_set_sql, current_set_values ]
    end

    @db.execute( "UPDATE #{ table } SET #{ set_sql } WHERE #{ where_sql }", set_values )
  end

  def execute( sql, *params )
    @db.execute( sql, params )
  end

  def select( sql, *params )
    options = params.last.is_a?( Hash ) ? params.pop : {}
    execute( sql, *params )
  end

  # params:    the last can be :options
  # options:
  #   :force:  force finding a value
  #
  def select_value( sql, *params )
    options = params.last.is_a?( Hash ) ? params.pop : {}

    row = execute( sql, *params ).first

    value = row && row.first

    if value
      value
    elsif options[ :force ]
      raise "Value not found!"
    end
  end

  def select_all( sql, *params )
    column_names, *raw_data = select_with_headers( sql, *params )

    raw_data.map do | row |
      Hash[ column_names.zip( row ) ]
    end
  end

  # This is a :select_row with headers as first row.
  #
  def select_with_headers( sql, *params )
    @db.execute2( sql, params )
  end

  # Can be nested - only the outer call with start a transaction.
  #
  def transaction( commit=true, &block )
    if @db.transaction_active?
      yield
    else
      begin
        @db.transaction do
          yield
          raise Rollback.new if !commit
        end
      rescue Rollback
        # do nothing
      end
    end
  end

  def close
    @db.close
  end

end
