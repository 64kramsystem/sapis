# Sapis

Sav's APIs - A collection of Ruby utility helpers for various tasks including graphing, configuration management, concurrency, system operations, multimedia handling, and more.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sapis'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install sapis
```

## Usage

Require the gem in your Ruby code:

```ruby
require 'sapis'
```

### Available Modules

#### GraphingHelper

Provides functionality for creating and formatting graphs using Gruff.

```ruby
# Transpose data and create line graphs
data, days = GraphingHelper.transpose_data_top_headers( source_data )
GraphingHelper.format_as_line_graph( data, days, out_file: 'graph.png' )

# Format data as tables
table = GraphingHelper.format_as_table( rows, separator: '|', align: { 'Header' => :left } )
```

#### ConfigurationHelper

Load configuration from files with optional encryption support.

```ruby
config = ConfigurationHelper.load_configuration( group: 'myapp', sym_keys: true )
value = config[ :some_key ]
```

#### ConcurrencyHelper

Parallel processing with thread pooling.

```ruby
ConcurrencyHelper.with_parallel_queue( 4 ) do | queue, semaphore |
  queue.push { task_1 }
  queue.push { task_2 }
end
```

#### GenericHelper

General utility functions including date decoding and retry logic.

```ruby
date = GenericHelper.decode_date( 'today' )
GenericHelper.do_retry( max_retries: 3, sleep: 1 ) { risky_operation }
```

#### BashHelper

Safe execution of bash commands.

```ruby
result = BashHelper.safe_execute( 'ls -la' )
BashHelper.simple_bash_execute( 'rm', file1, file2, file3 )
```

#### ComputationsHelper

Data manipulation and smoothing functions.

```ruby
ComputationsHelper.convert_to_incremental_values!( values )
ComputationsHelper.smooth_line!( values, 5 )
```

#### DesktopHelper

Desktop integration utilities.

```ruby
DesktopHelper.set_clipboard_text( 'Hello, World!' )
result = DesktopHelper.display_dialog( 'Are you sure?' )
DesktopHelper.desktop_notification( 'Task completed' )
```

#### InteractionsHelper

Command-line user interaction helpers.

```ruby
password = InteractionsHelper.secure_ask( 'Enter password: ' )
answer = InteractionsHelper.ask_entry( 'Name', 'default_name' )
choice = InteractionsHelper.ask_entries_with_points( 'Select option', options )
```

#### MultimediaHelper

Audio and multimedia file operations.

```ruby
MultimediaHelper.play_audio_file( 'song.mp3' )
MultimediaHelper.normalize_songs( file1, file2 )
MultimediaHelper.create_m3u_playlist( files, basedir, 'playlist.m3u' )
```

#### GnomeHelper

GNOME desktop environment helpers.

```ruby
GnomeHelper.set_gnome_background( '/path/to/image.jpg' )
current = GnomeHelper.get_gnome_background_filename
```

#### SystemHelper

System-level utilities.

```ruby
cores = SystemHelper.system_cores_number
files = SystemHelper.find_files( '*.rb', [ '/path' ], file_type: SystemHelper::SEARCH_FILES )
SystemHelper.open_file( 'document.pdf' )
```

#### SQLiteLayer

Simplified SQLite database operations.

```ruby
db = SQLiteLayer.new( 'database.db' )
id = db.insert_values( 'users', { name: 'John', email: 'john@example.com' } )
results = db.select_all( 'SELECT * FROM users WHERE active = ?', true )
db.transaction do
  # database operations
end
db.close
```

## Dependencies

- gruff (~> 0.7) - For graphing functionality
- parseconfig (~> 1.0) - For configuration file parsing
- highline (~> 2.0) - For secure command-line input
- sqlite3 (~> 1.4) - For SQLite database operations

## Development

After checking out the repo, run `bundle install` to install dependencies.

## License

This project is licensed under the GNU General Public License v3.0. See the source files for full license text.

## Author

Saverio Miroddi

## Contributing

Bug reports and pull requests are welcome on GitHub.
