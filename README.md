# RedisTABLE - SQL-like Tables for Redis

**Version**: 1.0.0  
**Status**: Production-Ready  
**License**: MIT

A Redis module that implements SQL-like tables with full CRUD operations, indexing, and query capabilities.

---

## Features

### Core Functionality
- ✅ **Full CRUD Operations** - CREATE, SELECT, UPDATE, DELETE
- ✅ **Namespace Management** - Organize tables into namespaces
- ✅ **Schema Management** - Define and alter table schemas
- ✅ **Multiple Data Types** - string, integer, float, date
- ✅ **Indexing** - Hash indexes for fast equality searches
- ✅ **Query Operators** - Comparison (=, >, <, >=, <=) and logical (AND, OR)
- ✅ **Configurable Limits** - Tune scan limits for your workload

### Production Features
- ✅ **Non-blocking Operations** - Uses SCAN instead of KEYS
- ✅ **Memory Safe** - Automatic memory management
- ✅ **Comprehensive Testing** - 93 tests, 100% passing
- ✅ **Client Compatible** - Works with all Redis clients

---

## Quick Start

### Installation

```bash
# Clone repository
git clone <repository-url>
cd RedisTABLE

# Build module
make build

# Run tests
make test
```

### Load Module

```bash
# Start Redis with module
redis-server --loadmodule ./redistable.so

# Or add to redis.conf
loadmodule /path/to/redistable.so
```

### Basic Usage

```bash
# Create namespace
redis-cli TABLE.NAMESPACE.CREATE myapp

# Create table
redis-cli TABLE.SCHEMA.CREATE myapp.users \
  user_id:integer:hash \
  email:string:hash \
  name:string:none \
  age:integer:none

# Insert data
redis-cli TABLE.INSERT myapp.users \
  user_id=1 email=john@example.com name=John age=30

# Query data
redis-cli TABLE.SELECT myapp.users WHERE email=john@example.com

# Update data
redis-cli TABLE.UPDATE myapp.users WHERE user_id=1 SET age=31

# Delete data
redis-cli TABLE.DELETE myapp.users WHERE user_id=1
```

---

## Command Reference

### Namespace Commands

```bash
# Create namespace
TABLE.NAMESPACE.CREATE <namespace>

# List all namespaces
TABLE.NAMESPACE.VIEW

# Drop namespace (removes all tables)
TABLE.NAMESPACE.DROP <namespace> FORCE
```

### Schema Commands

```bash
# Create table
TABLE.SCHEMA.CREATE <namespace.table> col1:type[:index] col2:type[:index] ...

# View table schema
TABLE.SCHEMA.VIEW <namespace.table>

# Alter table
TABLE.SCHEMA.ALTER <namespace.table> ADD COLUMN col:type[:index]
TABLE.SCHEMA.ALTER <namespace.table> DROP COLUMN col
TABLE.SCHEMA.ALTER <namespace.table> ADD INDEX col[:type]
TABLE.SCHEMA.ALTER <namespace.table> DROP INDEX col

# Drop table
TABLE.SCHEMA.DROP <namespace.table> FORCE
```

### Data Commands

```bash
# Insert row
TABLE.INSERT <namespace.table> col1=val1 col2=val2 ...

# Select rows
TABLE.SELECT <namespace.table> [WHERE conditions]

# Update rows
TABLE.UPDATE <namespace.table> WHERE conditions SET col1=val1 col2=val2 ...

# Delete rows
TABLE.DELETE <namespace.table> WHERE conditions
```

### Help Command

```bash
# Show all commands
TABLE.HELP
```

---

## Data Types

| Type | Description | Example |
|------|-------------|---------|
| **string** | Text data | `name:string` |
| **integer** | Whole numbers | `age:integer` |
| **float** | Decimal numbers | `price:float` |
| **date** | Date (YYYY-MM-DD) | `created:date` |

---

## Index Types

| Type | Description | Use Case |
|------|-------------|----------|
| **hash** | Hash index | Fast equality searches (=) |
| **none** | No index | Columns not used in WHERE clauses |
| **btree** | BTree index | Accepted but treated as hash (future: range queries) |

### Index Syntax

```bash
# With index
col:type:hash    # Create hash index
col:type:none    # No index (default)

# Without index specification (defaults to none)
col:type         # No index created
```

### Backward Compatibility

```bash
# Old syntax still works (deprecated)
col:type:true    # Converts to :hash
col:type:false   # Converts to :none
```

---

## Query Operators

### Comparison Operators

```bash
WHERE col=value      # Equality (uses index if available)
WHERE col>value      # Greater than (full scan)
WHERE col<value      # Less than (full scan)
WHERE col>=value     # Greater or equal (full scan)
WHERE col<=value     # Less or equal (full scan)
```

### Logical Operators

```bash
WHERE col1=val1 AND col2=val2    # Both conditions must match
WHERE col1=val1 OR col2=val2     # Either condition matches
```

---

## Configuration

### Module Load Options

```bash
# Default (100K row scan limit)
redis-server --loadmodule ./redistable.so

# Custom scan limit
redis-server --loadmodule ./redistable.so max_scan_limit 200000

# Range: 1,000 to 10,000,000
```

See [CONFIGURATION_GUIDE.md](CONFIGURATION_GUIDE.md) for details.

---

## Performance Considerations

### Indexing Strategy

```bash
# Index columns used in WHERE clauses
TABLE.SCHEMA.CREATE users \
  user_id:integer:hash    # Indexed (used in queries)
  email:string:hash       # Indexed (used in queries)
  bio:string:none         # Not indexed (rarely queried)
```

### Scan Limits

- **Default**: 100,000 rows per query
- **Configurable**: 1,000 to 10,000,000
- **Applies to**: Non-indexed comparisons (>, <, >=, <=)

### Best Practices

1. **Index frequently queried columns** - Use `:hash` for columns in WHERE clauses
2. **Don't over-index** - Indexes consume memory and slow down writes
3. **Use equality searches** - Indexed equality (=) is O(1), comparisons are O(n)
4. **Monitor memory** - Use `INFO memory` to track usage
5. **Tune scan limits** - Adjust based on dataset size and query patterns

---

## Limitations

### Known Limitations

#### DROP INDEX Race Condition ⚠️

**Issue**: Concurrent `DROP INDEX` and query operations may cause incorrect results.

**Mitigation**:
- Run schema changes during maintenance windows
- Avoid concurrent schema modifications
- Monitor for unexpected empty query results

**Planned Fix**: Future release will reverse deletion order or implement soft-delete.

### Query Limitations

- Comparison operators (>, <, >=, <=) require full table scan
- Equality (=) requires indexed columns
- No compound indexes (one index per column)
- Scan limit applies to non-indexed queries

### Data Constraints

- Maximum 64 characters for namespace and table names
- Date format: YYYY-MM-DD only (no time component)
- Float precision limited by string conversion

---

## Testing

```bash
# Run all tests
make test

# Run specific test suites
make unit-tests          # Core functionality (93 tests)
make memory-tests        # Memory leak detection
make client-tests        # Client compatibility (Python, Node.js)

# Clean and rebuild
make clean && make build
```

See [tests/TESTING.md](tests/TESTING.md) for comprehensive testing guide.

---

## Production Deployment

### Recommended Configuration

```bash
# Production settings
redis-server \
  --loadmodule ./redistable.so max_scan_limit 200000 \
  --maxmemory 4gb \
  --maxmemory-policy allkeys-lru
```

### Monitoring

```bash
# Check module status
redis-cli MODULE LIST

# Monitor memory
redis-cli INFO memory

# Check table statistics
redis-cli TABLE.NAMESPACE.VIEW
redis-cli TABLE.SCHEMA.VIEW <namespace.table>
```

### Best Practices

1. **Maintenance Windows** - Run schema changes during low-traffic periods
2. **Backups** - Use Redis persistence (RDB/AOF)
3. **Monitoring** - Track memory usage and query performance
4. **Testing** - Test schema changes in staging first
5. **Documentation** - Document your table schemas

See [PRODUCTION_NOTES.md](PRODUCTION_NOTES.md) for detailed deployment guide.

---

## Documentation

- [USER_GUIDE.md](USER_GUIDE.md) - Comprehensive user guide with examples
- [PRODUCTION_NOTES.md](PRODUCTION_NOTES.md) - Production deployment guide
- [CONFIGURATION_GUIDE.md](CONFIGURATION_GUIDE.md) - Configuration options
- [INDEX_TYPES_GUIDE.md](INDEX_TYPES_GUIDE.md) - Index types and performance
- [MAKEFILE_GUIDE.md](MAKEFILE_GUIDE.md) - Build system documentation
- [tests/TESTING.md](tests/TESTING.md) - Testing guide
- [tests/CLIENT_COMPATIBILITY.md](tests/CLIENT_COMPATIBILITY.md) - Client usage examples

---

## Examples

### E-commerce Application

```bash
# Create namespace
TABLE.NAMESPACE.CREATE ecommerce

# Products table
TABLE.SCHEMA.CREATE ecommerce.products \
  product_id:integer:hash \
  name:string:hash \
  price:float:none \
  stock:integer:none \
  category:string:hash

# Insert products
TABLE.INSERT ecommerce.products \
  product_id=1 name=Laptop price=999.99 stock=50 category=Electronics

# Query by category
TABLE.SELECT ecommerce.products WHERE category=Electronics

# Update stock
TABLE.UPDATE ecommerce.products WHERE product_id=1 SET stock=45

# Find expensive products
TABLE.SELECT ecommerce.products WHERE price>500
```

### User Management

```bash
# Users table
TABLE.SCHEMA.CREATE myapp.users \
  user_id:integer:hash \
  email:string:hash \
  username:string:hash \
  created_date:date:none

# Insert user
TABLE.INSERT myapp.users \
  user_id=1 email=alice@example.com username=alice created_date=2024-01-15

# Find user by email
TABLE.SELECT myapp.users WHERE email=alice@example.com

# Find recent users
TABLE.SELECT myapp.users WHERE created_date>2024-01-01
```

---

## Troubleshooting

### Module Won't Load

```bash
# Check Redis version (requires 6.0+)
redis-server --version

# Check module file exists
ls -lh redistable.so

# Check Redis logs
tail -f /var/log/redis/redis-server.log
```

### Tests Failing

```bash
# Rebuild clean
make clean && make build

# Check Redis is running
redis-cli PING

# Run tests with verbose output
cd tests && ./run_tests.sh
```

### Performance Issues

```bash
# Check memory usage
redis-cli INFO memory

# Check scan limit
redis-cli CONFIG GET max_scan_limit

# Increase scan limit if needed
redis-server --loadmodule ./redistable.so max_scan_limit 500000
```

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Ensure all tests pass (`make test`)
5. Submit a pull request

---

## License

MIT License - See LICENSE file for details

---

## Support

- **Documentation**: See docs/ directory
- **Issues**: Report bugs via issue tracker
- **Testing**: Run `make test` before reporting issues

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

**Version**: 1.0.0  
**Release Date**: 2025-10-16  
**Status**: Production-Ready  
**Build**: `make build && make test`
