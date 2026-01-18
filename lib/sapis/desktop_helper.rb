=begin

<desktop_helper.rb> - Part of Sav's APIs.
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

require_relative 'system_helper'
require 'shellwords'

module DesktopHelper
  CLIPBOARD_COMMAND = "xi"

  def set_clipboard_text( text )
    IO.popen(CLIPBOARD_COMMAND, 'w' ) { | io | io << text }
  end

  # Displays an OK/Cancel dialog.
  #
  # Returns true for OK, false for Cancel/Esc.
  #
  def display_dialog( text )
    quoted_text = '"' + text.gsub( '"', '\"' ).gsub( "'", "'\\\\''" ) + '"'

    if SystemHelper.mac?
      `osascript -e 'tell app "System Events" to display dialog #{ quoted_text }'`.strip == 'button returned:OK'
    else
      system( "zenity --question --text=#{ quoted_text }" )
    end
  end

  def desktop_notification(text)
    `notify-send #{text.shellescape}`
  end

end

