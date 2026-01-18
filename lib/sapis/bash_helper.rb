=begin

<bash_helper.rb> - Part of Sav's APIs.
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

module BashHelper

  require 'open3'
  require 'shellwords'

  # REFACTOR: default :out to STDOUT
  #
  def self.safe_execute( cmd, options={} )
    out = options[ :out ]

    Open3.popen3( cmd ) do | stdin, stdout, stderr, wait_thr |
      exit_status = wait_thr.value.exitstatus

      output = stdout.read

      out << output if out

      if exit_status == 0
        output.chomp unless out
      else
        raise stderr.read.chomp
      end
    end
  end

  def safe_execute( cmd, options={} )
    BashHelper.safe_execute( cmd, options )
  end

  # Encode as single-quoted, space-separated series of filenames.
  # Encoding a slash apparently requires four slashes.
  #

  def simple_bash_execute( command, *files_and_options )
    BashHelper.simple_bash_execute( command, *files_and_options )
  end

  def BashHelper.simple_bash_execute( command, *files_and_options )
    options = files_and_options.last.is_a?( Hash ) ? files_and_options.pop : {}
    files   = files_and_options

    output = options.has_key?( :out ) ? options[ :out ] : STDOUT

    files = files.flatten
    command = "#{ command } #{ encode_bash_filenames( *files ) }"

    safe_execute( command, out: output )
  end

  def encode_bash_filenames( *files )
    BashHelper.encode_bash_filenames( *files )
  end

  def BashHelper.encode_bash_filenames( *files )
    quoted_filenames = files.map { | file | file.shellescape }
    quoted_filenames.join( ' ' )
  end

end

