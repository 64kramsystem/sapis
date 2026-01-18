=begin

<gnome_helper.rb> - Part of Sav's APIs.
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

require_relative 'bash_helper'

module GnomeHelper

  include BashHelper

  def set_gnome_background( pic_path )
    simple_bash_execute "gconftool -t string -s /desktop/gnome/background/picture_filename", pic_path
  end

  def get_gnome_background_filename
    simple_bash_execute "gconftool -g /desktop/gnome/background/picture_filename"
  end

end

