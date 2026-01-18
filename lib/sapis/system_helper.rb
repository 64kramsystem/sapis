=begin

<system_helper.rb> - Part of Sav's APIs.
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

require File.expand_path( '../bash_helper.rb', __FILE__ )

module SystemHelper

  require 'shellwords'

  SystemHelper::SEARCH_FILES       = 'f'
  SystemHelper::SEARCH_DIRECTORIES = 'd'

  include BashHelper

  def self.mac?
    `uname`.strip == 'Darwin'
  end

  def self.current_timezone
    if mac?
      `systemsetup -gettimezone`.strip.sub( 'Time Zone: ', '' )
    else
      IO.read( '/etc/timezone' ).chomp
    end
  end

  def self.symlink( source, destination )
    # Doesn't work! At least one bug in the library:
    # - File.exists? returns false if a symlink exists, but points to a non-existent file
    # - symlink causes an abrupt exit if the destination exists
    #
#    File.delete( wine_drive_link ) if File.exists?( wine_drive_link )
#    File.symlink( entry, wine_drive_link )
    BashHelper.simple_bash_execute "ln -sf", source, destination
  end

  # REFACTOR: decide not/self for all the following
  #
  # 'mountpoint' has inconsistent exit behavior, because if the path is not a mountpoint,
  # it returns 1, but prints the message to stdout.
  #
  def unmount_base_mountpoint( filename )
    while filename != '/'
      is_mountpoint = `mountpoint #{ encode_bash_filenames( filename ) }` =~ /is a mountpoint\n$/

      if is_mountpoint
        simple_bash_execute "umount", filename
        return
      end

      filename = File.dirname( filename )
    end

    raise "Couldn't find base mount point for file: #{ filename }"
  end

  def system_cores_number
    if RUBY_PLATFORM =~ /darwin/i
      raw_result = safe_execute "system_profiler SPHardwareDataType | grep 'Total Number Of Cores'"
      raw_result[ /: (\d+)/, 1 ].to_i
    else
      # See https://www.ibm.com/developerworks/community/blogs/brian/entry/linux_show_the_number_of_cpu_cores_on_your_system17?lang=en
      # Bash form:
      #
      #   cat /proc/cpuinfo | egrep "core id|physical id" | tr -d "\n" | sed s/physical/\\nphysical/g | grep -v ^$ | sort | uniq | wc -l
      #
      IO.readlines( '/proc/cpuinfo' ).grep( /core id|physical id/ ).each_slice( 2 ).to_a.uniq.size
    end
  end

  def unrar( file, options={} )
    delete = !! options[ :delete ]

    original_dir    = Dir.pwd
    destination_dir = File.dirname( file )

    Dir.chdir( destination_dir )

    simple_bash_execute "unrar x", file

    File.delete( file ) if delete
  ensure
    Dir.chdir( original_dir )
  end

  # Opens :filename using the default executable.
  #
  def self.open_file( filename )
    `xdg-open #{ filename.shellescape }`
  end

  # Case insensitive search
  #
  # options:
  #   :file_type:  [nil] either SEARCH_FILES or SEARCH_DIRECTORIES, or nil for both.
  #   :skip_paths: [nil] array of (full) paths to skip
  #
  def self.find_files( raw_pattern, raw_search_paths, options={} )
    search_paths = raw_search_paths.map { | path | path.shellescape }.join( ' ' )
    pattern      = raw_pattern.shellescape

    case options[ :file_type ]
    when SEARCH_FILES
      file_type = '-type f'
    when SEARCH_DIRECTORIES
      file_type = '-type d'
    when nil
      # nothing
    else
      raise "Unrecognized :file_type option for find_files: #{ options[ :file_type ] }"
    end

    skip_paths = options[ :skip_paths ].to_a.map do | path |
      path_with_pattern = File.join( path, '*' )
      " -not -path " + path_with_pattern.shellescape
    end.join( ' ' )

    raw_result = `find #{ search_paths } -iname #{ pattern } #{ file_type } #{ skip_paths }`.chomp

    raw_result.split( "\n" )
  end

end

