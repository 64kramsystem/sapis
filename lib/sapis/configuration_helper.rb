=begin

<configuration_helper.rb> - Part of Sav's APIs.
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

module ConfigurationHelper

  require 'rubygems'
  require 'parseconfig'
  require 'openssl'
  require 'base64'

  CONFIGURATION_FILE = File.expand_path( '.sav_scripts',     '~' )
  PASSWORD_KEY_FILE  = File.expand_path( '.sav_scripts_key', '~' )

  # The encryption is intentionally weak.
  #
  PASSWORD_CIPHER = 'des'
  PASSWORD_KEY    = IO.read( PASSWORD_KEY_FILE ).chomp

  # Loads the configuration from a file, for a given group.
  #
  # Returns a Hash with an extra method: :path(key), which interprets the value as an absolute path if it starts with
  # a slash (/), and as a relative to home if it doesn't.
  #
  # options:
  #   :group       manually specify the group; defaults to the calling script.
  #   :sym_keys    keys as symbols
  #   :file        configuration filename
  #
  def self.load_configuration( options={} )
    $stderr.puts ">>> MIGRATE TO SIMPLE_SCRIPTING::CONFIG!"

    raise "Change argument to :group if needed (when the filename is different from the group)" if options.is_a?( String )

    group              = options[ :group    ] || File.basename( $0 ).chomp( '.rb' )
    sym_keys           = options[ :sym_keys ]
    configuration_file = options[ :file     ] || CONFIGURATION_FILE

    configuration = ParseConfig.new( configuration_file )[ group ]

    raise "Group not found in configuration: #{ group }" if configuration.nil?

    if configuration[ 'password' ]
      configuration[ 'password' ] = decrypt( configuration[ 'password' ], PASSWORD_KEY, PASSWORD_CIPHER, :base_64_decoding => true )
    end


    configuration = Hash[ configuration.map{ | key, value | [ key.to_sym, value ] } ] if sym_keys

    def configuration.path( key )
      raw_value = self[ key ]
      raw_value.start_with?( '/' ) ? raw_value : File.expand_path( raw_value, '~' )
    end

    configuration
  end

  # Shortcut for the previous method.
  #
  # Returns a String when querying only one key, otherwise an Array.
  #
  def self.load_configuration_values( *keys )
    configuration = load_configuration

    values = keys.inject( [] ) do | current_values, key |
      current_values << configuration[ key ]
    end

    if values.size == 1
      values.first
    else
      values
    end
  end

  def self.encrypt( plaintext, key, algo, options={} )
    base_64_encoding = !! options[ :base_64_encoding ]

    cipher = OpenSSL::Cipher::Cipher.new( algo )
    cipher.encrypt

    iv = cipher.random_iv

    cipher.key = key
    cipher.iv  = iv

    ciphertext = iv + cipher.update( plaintext ) + cipher.final

    ciphertext = Base64.encode64( ciphertext ) if base_64_encoding

    ciphertext
  end

  def self.decrypt( ciphertext, key, algo, options={} )
    puts ">>> ConfigurationHelper.decrypt should have key and algo as options"

    base_64_decoding = !! options[ :base_64_decoding ]

    ciphertext = Base64.decode64( ciphertext ) if base_64_decoding

    cipher = OpenSSL::Cipher::Cipher.new( algo )
    cipher.decrypt

    cipher.key = key

    cipher.iv = ciphertext.slice!( 0, cipher.iv_len )
    plaintext = cipher.update( ciphertext ) + cipher.final

    plaintext
  end

end
