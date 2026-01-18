# SQLiteLayer Test Suite

This directory contains tests for the SQLiteLayer database abstraction class.

## Running the Tests

```bash
# From the project root
ruby test/sqlite_layer_test.rb

# Or make it executable and run directly
chmod +x test/sqlite_layer_test.rb
./test/sqlite_layer_test.rb
```

## Test Coverage

The test suite covers the following SQLiteLayer functionality:

### Core Database Operations
- **Database Initialization**: Tests database connection and setup
- **Foreign Keys**: Verifies PRAGMA foreign_keys is enabled

### Insert Operations
- **Insert with Hash**: Tests inserting records with named columns
- **Insert with Array**: Tests positional insertion without column names
- **Multiple Inserts**: Verifies sequential row ID generation
- **BLOB Handling**: Tests binary data insertion and retrieval

### Select Operations
- **Basic Select**: Tests SELECT queries with bind parameters
- **Select Value**: Tests retrieving a single value from a query
- **Select Value (Force)**: Tests error handling for missing values
- **Select All**: Tests returning results as array of hashes
- **Select With Headers**: Tests execute2 method with column headers

### Update Operations
- **Update Values**: Tests UPDATE queries with WHERE conditions

### Execute Operations
- **Execute (No Parameters)**: Tests raw SQL execution
- **Execute (With Parameters)**: Tests parameterized queries

### Transaction Management
- **Transaction Commit**: Tests successful transaction commits
- **Transaction Rollback**: Tests explicit transaction rollbacks
- **Transaction Rollback on Exception**: Tests automatic rollback on errors
- **Nested Transactions**: Tests that inner transactions are properly handled

## Test Output

The test suite provides clear output with:
- ✓ marks for passing tests
- ✗ marks for failing tests
- Summary statistics (total, passed, failed)
- Detailed error messages for failures

Example output:
```
======================================================================
SQLiteLayer Test Suite
Testing with sqlite3 gem version: 2.9.0
======================================================================

Test: Database Initialization
  ✓ Database instance created

Test: Foreign Keys Enabled
  ✓ Foreign keys should be enabled

...

======================================================================
Test Summary
======================================================================
Total Tests: 29
Passed: 29
Failed: 0

✓ All tests passed!
```

## Dependencies

- Ruby 3.2 or greater (required by sqlite3 gem 2.9.0)
- sqlite3 gem ~> 2.9.0

## Notes

- Tests use in-memory databases (`:memory:`) for isolation
- Each test has its own setup/teardown cycle
- No external test framework required (uses built-in assertions)
