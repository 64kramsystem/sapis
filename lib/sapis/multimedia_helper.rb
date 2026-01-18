=begin

<multimedia_helper.rb> - Part of Sav's APIs.
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
require_relative 'bash_helper'

module MultimediaHelper
  include SystemHelper, BashHelper

  RHYTHMBOX_PLAYLISTS_FILE = File.expand_path('.local/share/rhythmbox/playlists.xml', '~')
  BANSHEE_DATA_FILE        = File.expand_path('.config/banshee-1/banshee.db', '~')
  AUDIO_FILES_EXTENSIONS   = ['m4a', 'mp3']

  def image_format(image_data)
    if image_data.start_with?('GIF8')
      'gif'
    elsif image_data.start_with?("\xFF\xD8\xFF\xE0")
      'jpg'
    else
      raise "Unrecognized picture format."
    end
  end

  def play_audio_file(filename)
    filename = File.expand_path(filename)

    if SystemHelper.mac?
      simple_bash_execute 'afplay', filename
    else
      simple_bash_execute "gst-launch-1.0 playbin -q", "uri=file://#{filename}"
    end
  end

  def normalize_songs(*files)
    files.flatten!

    mp3_files = files.select { |file| file =~ /\.mp3$/i }
    mp4_files = files.select { |file| file =~ /\.m4a$/i }

    raise "xxx!" if mp3_files.size + mp4_files.size != files.size

    if mp3_files.size != 0
      simple_bash_execute "mp3gain -r", mp3_files
    end

    if mp4_files.size != 0
      simple_bash_execute "aacgain -r", mp4_files
    end
  end

  # Works on a single folder - no recursion.
  #
  def normalize_album(directory, extension)
    case extension
    when 'm4a'
      program   = 'aacgain'
    when 'mp3'
      program   = 'mp3gain'
    else
      raise "Unsupported extension: #{extension}"
    end

    files         = Dir.glob(File.join(directory, "*.#{extension}"))
    encoded_files = encode_bash_filenames(*files)

    # The m.f. popen3 hangs when normalizing, possibly because aacgain rewrites to screen because of the counter
    # F**K F**K
    #
    # Regardless, aacgain appears to be broken, as if an error happens, it still exits successfully.
    #
    safe_execute "#{program} -a -k " + encoded_files + " 2> /dev/null"
  end

  def encode_alac_to_m4a(file)
    temp_file = file + ".wav"

    simple_bash_execute "ffmpeg -i", file, temp_file

    File.delete(file)

    simple_bash_execute "neroAacEnc -q 0.5", "-if", temp_file, "-of", file

    File.delete(temp_file)
  end

  # Sorts files by name
  #
  def create_m3u_playlist(files_or_pattern, basedir, output)
    case files_or_pattern
    when Array
      files = files_or_pattern
      # do nothing
    when String
      files = Dir.glob(files_or_pattern)
    else
      raise "ziokann!! #{files_or_pattern}"
    end

    buffer = "#EXTM3U" << "\n"

    files.sort.each do |file|
      duration = get_audio_file_duration(file)
      song_name = File.basename(file).sub(/\.\w+$/, '')

      buffer << "#EXTINF:#{duration},#{song_name}" << "\n"

      file_relative_path = File.join(basedir, File.basename(file))

      buffer << file_relative_path << "\n"
    end

    IO.write(output, buffer)
  end

  def get_audio_file_duration(file)
    case file
    when /.mp3$/
      duration = safe_execute("mp3info -p '%S' " + encode_bash_filenames(file))
    when /.m4a$/
     # f#!$ing faad writes only to stderr
     #
      raw_result = safe_execute('faad -i ' + encode_bash_filenames(file) + " 2>&1")

      duration = raw_result[/(\d+)\.\d+ secs/, 1] || raise("z.k.!!")
    else
      raise "ziokann!!! #{file}"
    end

    duration.to_i
  end

  # :directories           single entry or array
  #
  def add_playlists_to_rhythmbox(directories, options={})
    require 'rexml/document'
    require 'uri'

    directories = [directories] if !directories.is_a?(Array)

    raw_xml  = IO.read(RHYTHMBOX_PLAYLISTS_FILE)
    xml_doc  = REXML::Document.new(raw_xml)
    xml_root = xml_doc.elements.first

    directories.each do |directory|
      puts "Adding #{directory}..."

      playlist_name = File.basename(directory)
      filenames     = AUDIO_FILES_EXTENSIONS.map { |extension| Dir.glob(File.join(directory, "*.#{extension}")) }.flatten.sort

      if xml_root.elements.any? { |xml_element| xml_element.attributes['name'] == playlist_name }
        puts ">>> playlist already existent!"
      else
        playlist_node = xml_root.add_element('playlist', 'name' => playlist_name, 'type' => 'static')

        filenames.sort!

        filenames.each do |filename|
          entry_node       = playlist_node.add_element('location')
          encoded_filename = URI.encode(File.expand_path(filename))
          entry_node.text  = "file://" + encoded_filename
        end
      end
    end

    buffer = format_xml_playlist_for_rhythmbox(xml_doc)

    IO.write(RHYTHMBOX_PLAYLISTS_FILE, buffer)
  end

  # :directories           single entry or array
  #
  def add_playlists_to_banshee(directories, options={})
    require 'uri'

    directories = [directories] if !directories.is_a?(Array)

    db_layer = SQLiteLayer.new(BANSHEE_DATA_FILE)

    primary_source_id_music = 1

    db_layer.transaction do
      directories.each do |directory|
        puts "Adding #{directory}..."

        playlist_name = File.basename(directory)

        insertion_values = {
          :PrimarySourceID => primary_source_id_music,
          :Name            => playlist_name,
        }

        playlist_id = db_layer.insert_values('CorePlaylists', insertion_values)

        filenames = AUDIO_FILES_EXTENSIONS.map { |extension| Dir.glob(File.join(directory, "*.#{extension}")) }.flatten.sort

        filenames.each do |filename|
          puts " - #{filename}"

          track_id = banshee_find_track_id(filename, db_layer) || banshee_add_playlist_entry(filename, db_layer, primary_source_id_music)

          insertion_values = {
            :PlaylistID => playlist_id,
            :TrackID    => track_id,
          }

          db_layer.insert_values('CorePlaylistEntries', insertion_values)
        end
      end
    end
  end

  private

  def banshee_find_track_id(filename, db_layer)
    uri_filename   = "file://" + URI.encode(File.expand_path(filename))

    db_layer.select_value("SELECT TrackID FROM CoreTracks WHERE Uri = ?", uri_filename)
  end

  def banshee_add_playlist_entry(filename, db_layer, primary_source_id_music)
    uri_filename   = "file://" + URI.encode(File.expand_path(filename))
    title          = File.basename(filename).sub(/\.\w+$/, '')
    straight_title = "'" + title.gsub("'", "''") + "'"
    timestamp      = Time.now.to_i

    insertion_values = {
      :PrimarySourceID => primary_source_id_music,
      :ArtistID             => 1,
      :AlbumID              => 1,
      :TagSetID             => 0,

      :Uri                  => uri_filename,

      :DateAddedStamp       => timestamp,
      :LastSyncedStamp      => timestamp,
    }

    # when the titles are inserted with placeholders, they're inserted as BLOBs, because the columns are
    # defined as TEXT. this causes problems with banshee, and is not noticeable when querying the db via
    # cmdline client, or via ruby driver (translation: it's a m.f. pain in the back), but only via dump.
    #
    straight_insert_values = {
      :Title           => straight_title,
      :TitleLowered    => straight_title.downcase,
    }

    db_layer.insert_values('CoreTracks', insertion_values, :straight_insert => straight_insert_values)
  end

  def format_xml_playlist_for_rhythmbox(xml_doc)
    buffer        = ""
    xml_formatter = REXML::Formatters::Pretty.new

    xml_formatter.compact = true
    xml_formatter.width   = 16384   # avoid introducing f*ing spaces inside <location> elements, which are not compatible with RhythmBox

    xml_formatter.write(xml_doc, buffer)

    buffer
   end
end
