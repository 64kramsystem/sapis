=begin

<concurrency_helper.rb> - Part of Sav's APIs.
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

module ConcurrencyHelper

  require 'thread'

  # Parallel working, constrained on the number of threads.
  # Sets Thread.abort_on_exception to true as default.
  #
  # Usage:
  #
  #   ConcurrencyHelper.with_parallel_queue( <slots> ) do | queue, semaphore |
  #     queue.push { <operation_1> }
  #     queue.push { <operation_2> }
  #   end
  #
  # or:
  #
  #   ConcurrencyHelper.with_parallel_queue( <slots>, :instances => <Enumerable> ) do | instance, semaphore |
  #     -> { <operation>( <instance> ) }
  #   end
  #
  # or:
  #
  #   queue = ParallelWorkersQueue.new( <threads> )
  #   queue.push { <operation_1> }
  #   queue.push { <operation_2> }
  #   queue.join
  #
  # The semaphore is a generic semaphore; it can be used for example to lock when printing information to stdout.
  #
  class ParallelWorkersQueue

    def initialize( slots, options={} )
      abort_on_exception = ! options.has_key?( :abort_on_exception ) || options[ :abort_on_exception ]

      @queue = SizedQueue.new( slots )

      @threads = slots.times.map do
        Thread.new do
          while ( data = @queue.pop ) != :stop
            data[]
          end
        end
      end

      Thread.abort_on_exception = abort_on_exception
    end

    def push( &task )
      @queue.push( task )
    end

    def join
      @threads.each do
        @queue.push( :stop )
      end

      @threads.each( &:join )
    end

  end

  def self.with_parallel_queue( slots, options={} )
    instances          = options[ :instances          ]
    abort_on_exception = options[ :abort_on_exception ]

    queue     = ParallelWorkersQueue.new( slots, :abort_on_exception => abort_on_exception )
    semaphore = Mutex.new

    if instances
      instances.each do | instance |
        proc = yield( instance, semaphore )

        raise "The value returned is not a Proc!" unless proc.is_a?( Proc )

        queue.push( &proc )
      end
    else
      yield( queue, semaphore )
    end

    queue.join
  end

end
