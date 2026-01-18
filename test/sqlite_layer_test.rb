#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sapis/sqlite_layer'

# Simple test framework for SQLiteLayer
class SQLiteLayerTest
  attr_reader :passed, :failed, :errors

  def initialize
    @passed = 0
    @failed = 0
    @errors = []
    @db = nil
  end

  def setup
    @db = SQLiteLayer.new(':memory:')
    @db.execute('CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER)')
    @db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT, age INTEGER)')
  end

  def teardown
    @db.close if @db
    @db = nil
  end

  def assert(condition, message)
    if condition
      @passed += 1
      puts "  ✓ #{message}"
    else
      @failed += 1
      @errors << message
      puts "  ✗ #{message}"
    end
  end

  def assert_equal(expected, actual, message)
    if expected == actual
      @passed += 1
      puts "  ✓ #{message}"
    else
      @failed += 1
      error = "#{message} (expected: #{expected.inspect}, got: #{actual.inspect})"
      @errors << error
      puts "  ✗ #{error}"
    end
  end

  def test_database_initialization
    puts "\nTest: Database Initialization"
    db = SQLiteLayer.new(':memory:')
    assert(db.db.is_a?(SQLite3::Database), "Database instance created")
    db.close
  end

  def test_pragma_foreign_keys_enabled
    puts "\nTest: Foreign Keys Enabled"
    result = @db.select_value('PRAGMA foreign_keys')
    assert_equal(1, result, "Foreign keys should be enabled")
  end

  def test_insert_values_with_hash
    puts "\nTest: Insert Values (Hash)"
    row_id = @db.insert_values('test', {name: 'foo', value: 42})
    assert_equal(1, row_id, "First insert should return row ID 1")

    result = @db.select('SELECT name, value FROM test WHERE id = ?', row_id)
    assert_equal([['foo', 42]], result, "Inserted data should match")
  end

  def test_insert_values_with_array
    puts "\nTest: Insert Values (Array)"
    # Note: Array insert without column names assumes all columns are provided in order
    # For table with (id, name, value) where id is autoincrement, we skip it
    # So we need to test this with a table designed for positional inserts
    @db.execute('CREATE TABLE simple (name TEXT, value INTEGER)')
    row_id = @db.insert_values('simple', ['bar', 99])
    assert(row_id > 0, "Insert should return a valid row ID")

    result = @db.select('SELECT name, value FROM simple WHERE rowid = ?', row_id)
    assert_equal([['bar', 99]], result, "Inserted data should match")
  end

  def test_insert_multiple_rows
    puts "\nTest: Insert Multiple Rows"
    id1 = @db.insert_values('users', {name: 'Alice', email: 'alice@example.com', age: 30})
    id2 = @db.insert_values('users', {name: 'Bob', email: 'bob@example.com', age: 25})
    id3 = @db.insert_values('users', {name: 'Charlie', email: 'charlie@example.com', age: 35})

    assert_equal(1, id1, "First insert ID should be 1")
    assert_equal(2, id2, "Second insert ID should be 2")
    assert_equal(3, id3, "Third insert ID should be 3")
  end

  def test_update_values
    puts "\nTest: Update Values"
    row_id = @db.insert_values('test', {name: 'original', value: 100})

    @db.update_values('test', {name: 'updated', value: 200, where: "id = #{row_id}"})

    result = @db.select('SELECT name, value FROM test WHERE id = ?', row_id)
    assert_equal([['updated', 200]], result, "Updated data should match")
  end

  def test_select
    puts "\nTest: Select"
    @db.insert_values('test', {name: 'foo', value: 1})
    @db.insert_values('test', {name: 'bar', value: 2})
    @db.insert_values('test', {name: 'baz', value: 3})

    results = @db.select('SELECT name FROM test WHERE value > ?', 1)
    assert_equal(2, results.size, "Should return 2 rows")
    assert_equal([['bar'], ['baz']], results, "Results should match")
  end

  def test_select_value
    puts "\nTest: Select Value"
    @db.insert_values('test', {name: 'foo', value: 42})

    value = @db.select_value('SELECT value FROM test WHERE name = ?', 'foo')
    assert_equal(42, value, "Select value should return the first column of first row")
  end

  def test_select_value_with_force
    puts "\nTest: Select Value (Force)"
    begin
      @db.select_value('SELECT value FROM test WHERE name = ?', 'nonexistent', {force: true})
      assert(false, "Should raise error when value not found with :force option")
    rescue RuntimeError => e
      assert(e.message == "Value not found!", "Should raise 'Value not found!' error")
    end
  end

  def test_select_all
    puts "\nTest: Select All"
    @db.insert_values('users', {name: 'Alice', email: 'alice@example.com', age: 30})
    @db.insert_values('users', {name: 'Bob', email: 'bob@example.com', age: 25})

    results = @db.select_all('SELECT name, age FROM users ORDER BY age')

    assert_equal(2, results.size, "Should return 2 rows")
    assert_equal('Bob', results[0]['name'], "First result should be Bob")
    assert_equal(25, results[0]['age'], "Bob's age should be 25")
    assert_equal('Alice', results[1]['name'], "Second result should be Alice")
    assert_equal(30, results[1]['age'], "Alice's age should be 30")
  end

  def test_select_with_headers
    puts "\nTest: Select With Headers"
    @db.insert_values('test', {name: 'foo', value: 42})

    results = @db.select_with_headers('SELECT name, value FROM test')

    assert_equal(2, results.size, "Should return headers + 1 data row")
    assert_equal(['name', 'value'], results[0], "First row should be headers")
    assert_equal(['foo', 42], results[1], "Second row should be data")
  end

  def test_transaction_commit
    puts "\nTest: Transaction (Commit)"
    initial_count = @db.select_value('SELECT COUNT(*) FROM test')

    @db.transaction(true) do
      @db.insert_values('test', {name: 'inside_transaction', value: 1})
      @db.insert_values('test', {name: 'also_inside', value: 2})
    end

    final_count = @db.select_value('SELECT COUNT(*) FROM test')
    assert_equal(initial_count + 2, final_count, "Transaction should commit both inserts")
  end

  def test_transaction_rollback
    puts "\nTest: Transaction (Rollback)"
    initial_count = @db.select_value('SELECT COUNT(*) FROM test')

    @db.transaction(false) do
      @db.insert_values('test', {name: 'should_rollback', value: 999})
      @db.insert_values('test', {name: 'also_rollback', value: 888})
    end

    final_count = @db.select_value('SELECT COUNT(*) FROM test')
    assert_equal(initial_count, final_count, "Transaction should rollback, count unchanged")
  end

  def test_transaction_rollback_on_exception
    puts "\nTest: Transaction (Rollback on Exception)"
    initial_count = @db.select_value('SELECT COUNT(*) FROM test')

    begin
      @db.transaction(true) do
        @db.insert_values('test', {name: 'before_error', value: 1})
        raise Rollback.new
      end
    rescue Rollback
      # Expected
    end

    final_count = @db.select_value('SELECT COUNT(*) FROM test')
    assert_equal(initial_count, final_count, "Raising Rollback should rollback transaction")
  end

  def test_nested_transaction
    puts "\nTest: Nested Transaction"
    @db.insert_values('test', {name: 'initial', value: 1})
    initial_count = @db.select_value('SELECT COUNT(*) FROM test')

    @db.transaction(true) do
      @db.insert_values('test', {name: 'outer', value: 2})

      # Nested transaction should be ignored
      @db.transaction(true) do
        @db.insert_values('test', {name: 'inner', value: 3})
      end
    end

    final_count = @db.select_value('SELECT COUNT(*) FROM test')
    assert_equal(initial_count + 2, final_count, "Nested transaction should work correctly")
  end

  def test_blob_handling
    puts "\nTest: BLOB Handling"
    @db.execute('CREATE TABLE blobs (id INTEGER PRIMARY KEY, data BLOB)')

    binary_data = "\x00\x01\x02\x03\xFF".b
    row_id = @db.insert_values('blobs', {data: [binary_data]})

    result = @db.select_value('SELECT data FROM blobs WHERE id = ?', row_id)
    assert_equal(binary_data, result, "BLOB data should be preserved")
  end

  def test_execute_with_no_params
    puts "\nTest: Execute (No Parameters)"
    result = @db.execute('SELECT 1 + 1 AS result')
    assert_equal([[2]], result, "Should execute SQL without parameters")
  end

  def test_execute_with_params
    puts "\nTest: Execute (With Parameters)"
    @db.insert_values('test', {name: 'test', value: 100})
    result = @db.execute('SELECT name FROM test WHERE value = ?', 100)
    assert_equal([['test']], result, "Should execute SQL with parameters")
  end

  def run_all_tests
    puts "=" * 70
    puts "SQLiteLayer Test Suite"
    puts "Testing with sqlite3 gem version: #{SQLite3::VERSION}"
    puts "=" * 70

    test_methods = methods.grep(/^test_/).sort

    test_methods.each do |test_method|
      begin
        setup
        send(test_method)
        teardown
      rescue => e
        @failed += 1
        error = "#{test_method}: #{e.class} - #{e.message}"
        @errors << error
        puts "  ✗ ERROR: #{error}"
        teardown rescue nil
      end
    end

    puts "\n" + "=" * 70
    puts "Test Summary"
    puts "=" * 70
    puts "Total Tests: #{@passed + @failed}"
    puts "Passed: #{@passed}"
    puts "Failed: #{@failed}"

    if @failed > 0
      puts "\nFailed Tests:"
      @errors.each { |error| puts "  - #{error}" }
      exit(1)
    else
      puts "\n✓ All tests passed!"
      exit(0)
    end
  end
end

# Run the tests if this file is executed directly
if __FILE__ == $0
  test_suite = SQLiteLayerTest.new
  test_suite.run_all_tests
end
