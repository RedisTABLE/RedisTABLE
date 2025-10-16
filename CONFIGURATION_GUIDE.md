# RedisTABLE - Configuration Guide

**Version**: 1.0.0  
**Last Updated**: 2025-10-16

Complete guide to configuring RedisTABLE module.

---

## Overview

RedisTABLE supports configuration through:
1. **Module load-time parameters** - Set when loading the module
2. **module.conf file** - Configuration file (planned for future releases)

---

## Module Load-Time Configuration

### Syntax

```bash
redis-server --loadmodule /path/to/redistable.so [parameter value] [parameter value] ...
```

### Available Parameters

#### max_scan_limit

**Description**: Maximum number of rows to scan in a single query operation

**Type**: Integer  
**Range**: 1,000 to 10,000,000  
**Default**: 100,000

**Usage**:
```bash
# Default (100K rows)
redis-server --loadmodule ./redistable.so

# Custom limit (200K rows)
redis-server --loadmodule ./redistable.so max_scan_limit 200000

# High limit for analytics (1M rows)
redis-server --loadmodule ./redistable.so max_scan_limit 1000000
```

**When to adjust**:
- **Increase** for analytics workloads with large datasets
- **Decrease** for OLTP workloads to prevent blocking
- **Monitor** query performance and adjust accordingly

---

## Configuration by Workload

### OLTP Workload

**Characteristics**:
- Small, fast queries
- High concurrency
- Low latency requirements

**Recommended Configuration**:
```bash
redis-server \
  --loadmodule ./redistable.so max_scan_limit 50000 \
  --maxmemory 2gb \
  --maxmemory-policy allkeys-lru
```

### Analytics Workload

**Characteristics**:
- Large scans
- Complex queries
- Can tolerate higher latency

**Recommended Configuration**:
```bash
redis-server \
  --loadmodule ./redistable.so max_scan_limit 1000000 \
  --maxmemory 8gb \
  --maxmemory-policy noeviction
```

### Mixed Workload

**Characteristics**:
- Both OLTP and analytics
- Varied query patterns

**Recommended Configuration**:
```bash
redis-server \
  --loadmodule ./redistable.so max_scan_limit 200000 \
  --maxmemory 4gb \
  --maxmemory-policy allkeys-lru
```

### Batch Processing

**Characteristics**:
- Large batch operations
- Dedicated instance
- Can afford blocking

**Recommended Configuration**:
```bash
redis-server \
  --loadmodule ./redistable.so max_scan_limit 5000000 \
  --maxmemory 16gb \
  --maxmemory-policy noeviction
```

---

## Redis Configuration

### Memory Settings

```conf
# Maximum memory
maxmemory 4gb

# Eviction policy
maxmemory-policy allkeys-lru  # For cache-like workloads
# OR
maxmemory-policy noeviction   # For persistent data
```

### Persistence Settings

```conf
# RDB snapshots
save 900 1      # Save after 900 sec if 1 key changed
save 300 10     # Save after 300 sec if 10 keys changed
save 60 10000   # Save after 60 sec if 10000 keys changed

# AOF persistence
appendonly yes
appendfsync everysec
```

### Logging

```conf
# Log level
loglevel notice

# Log file
logfile /var/log/redis/redis-server.log
```

---

## module.conf File

The `module.conf` file documents planned configuration options for future releases.

### Location

```
RedisTABLE/
  └── module.conf
```

### Format

```conf
# RedisTABLE Module Configuration
# Version: 1.0.0

# Maximum Scan Limit
# Maximum number of rows to scan in a single query operation.
# integer, valid range: [1000 .. 10000000], default: 100000
#
# max_scan_limit 100000

# Default Index Type (PLANNED)
# Default indexing strategy for new columns when index type is not specified.
# string, valid values: [hash, btree, none], default: none
#
# default_index_type none
```

### Current Status

**Implemented**:
- ✅ max_scan_limit - Available via module load parameter

**Planned** (future releases):
- ⏳ default_index_type - Default index type for columns
- ⏳ enable_query_cache - Query result caching
- ⏳ query_cache_size - Cache size limit
- ⏳ enable_statistics - Table statistics collection
- ⏳ max_table_size - Maximum rows per table

---

## Configuration Examples

### Example 1: Development Environment

```bash
# Minimal configuration for development
redis-server \
  --loadmodule ./redistable.so \
  --port 6379 \
  --loglevel debug
```

### Example 2: Production OLTP

```bash
# Production OLTP configuration
redis-server \
  --loadmodule ./redistable.so max_scan_limit 100000 \
  --port 6379 \
  --bind 0.0.0.0 \
  --maxmemory 4gb \
  --maxmemory-policy allkeys-lru \
  --save 900 1 \
  --save 300 10 \
  --save 60 10000 \
  --appendonly yes \
  --appendfsync everysec \
  --loglevel notice \
  --logfile /var/log/redis/redis-server.log
```

### Example 3: Analytics Instance

```bash
# Analytics-focused configuration
redis-server \
  --loadmodule ./redistable.so max_scan_limit 2000000 \
  --port 6380 \
  --bind 127.0.0.1 \
  --maxmemory 16gb \
  --maxmemory-policy noeviction \
  --save "" \
  --appendonly no \
  --loglevel notice
```

### Example 4: redis.conf File

```conf
# redis.conf

# Basic settings
port 6379
bind 0.0.0.0
daemonize yes
pidfile /var/run/redis/redis-server.pid

# Load RedisTABLE module
loadmodule /usr/lib/redis/modules/redistable.so max_scan_limit 200000

# Memory
maxmemory 4gb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfsync everysec
dir /var/lib/redis

# Logging
loglevel notice
logfile /var/log/redis/redis-server.log

# Security
requirepass your_strong_password

# Limits
maxclients 10000
```

---

## Validation and Defaults

### max_scan_limit Validation

```bash
# Valid values
redis-server --loadmodule ./redistable.so max_scan_limit 1000      # Minimum
redis-server --loadmodule ./redistable.so max_scan_limit 100000    # Default
redis-server --loadmodule ./redistable.so max_scan_limit 10000000  # Maximum

# Invalid values (uses default)
redis-server --loadmodule ./redistable.so max_scan_limit 500       # Too low → 100000
redis-server --loadmodule ./redistable.so max_scan_limit 20000000  # Too high → 100000
redis-server --loadmodule ./redistable.so max_scan_limit abc       # Invalid → 100000
```

### Default Behavior

If no configuration is provided:
- max_scan_limit: 100,000 rows
- Suitable for most OLTP workloads
- Can be adjusted based on monitoring

---

## Monitoring Configuration

### Check Current Configuration

```bash
# Module is loaded
redis-cli MODULE LIST

# Check Redis memory settings
redis-cli CONFIG GET maxmemory
redis-cli CONFIG GET maxmemory-policy

# Check persistence settings
redis-cli CONFIG GET save
redis-cli CONFIG GET appendonly
```

### Runtime Monitoring

```bash
# Memory usage
redis-cli INFO memory | grep used_memory_human

# Query performance
redis-cli SLOWLOG GET 10

# Module status
redis-cli MODULE LIST | grep table
```

---

## Tuning Guidelines

### When to Increase max_scan_limit

**Symptoms**:
- Frequent "query scan limit exceeded" errors
- Legitimate queries failing
- Analytics queries incomplete

**Action**:
```bash
# Increase limit gradually
redis-server --loadmodule ./redistable.so max_scan_limit 200000

# Monitor performance
# If acceptable, increase further if needed
```

### When to Decrease max_scan_limit

**Symptoms**:
- Redis blocking during queries
- High latency for other operations
- Timeout errors

**Action**:
```bash
# Decrease limit
redis-server --loadmodule ./redistable.so max_scan_limit 50000

# Add more indexes to avoid full scans
redis-cli TABLE.SCHEMA.ALTER users ADD INDEX age:hash
```

### Memory Tuning

```bash
# Calculate memory needs
# Rough estimate: (rows * columns * avg_value_size) + (indexes * unique_values * 100 bytes)

# Example: 1M rows, 5 columns, 50 bytes avg, 2 indexes, 100K unique values
# Data: 1M * 5 * 50 = 250 MB
# Indexes: 2 * 100K * 100 = 20 MB
# Total: ~270 MB + overhead = ~400 MB

# Set maxmemory with headroom
maxmemory 800mb
```

---

## Best Practices

### 1. Start Conservative

```bash
# Start with default or lower
redis-server --loadmodule ./redistable.so max_scan_limit 100000

# Monitor and adjust based on actual usage
```

### 2. Monitor Performance

```bash
# Track query performance
redis-cli SLOWLOG GET 10

# Monitor memory usage
redis-cli INFO memory

# Watch for scan limit errors
tail -f /var/log/redis/redis-server.log | grep "scan limit"
```

### 3. Document Configuration

```bash
# Document your configuration
# Example: production_redis.conf

# Why this limit?
# - 200K limit for analytics queries
# - Tested with 2M row tables
# - Average query time: 50ms
loadmodule ./redistable.so max_scan_limit 200000
```

### 4. Test Before Production

```bash
# Test configuration in staging
# 1. Load module with config
# 2. Run representative queries
# 3. Monitor performance
# 4. Adjust if needed
# 5. Deploy to production
```

### 5. Use Appropriate Limits

| Environment | Recommended Limit |
|-------------|-------------------|
| Development | 50,000 - 100,000 |
| Staging | Match production |
| Production OLTP | 50,000 - 200,000 |
| Production Analytics | 500,000 - 2,000,000 |
| Batch Processing | 1,000,000 - 5,000,000 |

---

## Troubleshooting

### Issue: Module Won't Load

```bash
# Check syntax
redis-server --loadmodule ./redistable.so max_scan_limit 100000

# Check file exists
ls -lh redistable.so

# Check Redis logs
tail -f /var/log/redis/redis-server.log
```

### Issue: Configuration Not Applied

```bash
# Verify module loaded with parameters
redis-cli MODULE LIST

# Check Redis configuration
redis-cli CONFIG GET *

# Restart Redis if needed
redis-cli SHUTDOWN
redis-server --loadmodule ./redistable.so max_scan_limit 200000
```

### Issue: Scan Limit Errors

```bash
# Error: "query scan limit exceeded (max 100000 rows)"

# Solution 1: Increase limit
redis-server --loadmodule ./redistable.so max_scan_limit 200000

# Solution 2: Add indexes
redis-cli TABLE.SCHEMA.ALTER users ADD INDEX age:hash

# Solution 3: Refine query
# Use indexed columns in WHERE clause
```

---

## Future Configuration Options

The following options are planned for future releases:

### default_index_type

```conf
# Default index type when not specified
# Values: hash, btree, none
# Default: none
default_index_type none
```

### enable_query_cache

```conf
# Enable query result caching
# Values: yes, no
# Default: no
enable_query_cache no
```

### query_cache_size

```conf
# Maximum cached queries
# Range: 10 - 10000
# Default: 100
query_cache_size 100
```

### enable_statistics

```conf
# Collect table statistics
# Values: yes, no
# Default: yes
enable_statistics yes
```

### max_table_size

```conf
# Maximum rows per table
# Range: 1000 - 100000000
# Default: 10000000
max_table_size 10000000
```

---

## Summary

### Current Configuration (v1.0.0)

**Available**:
- ✅ max_scan_limit - Module load parameter

**Syntax**:
```bash
redis-server --loadmodule ./redistable.so max_scan_limit <value>
```

**Recommended**:
- OLTP: 50,000 - 100,000
- Analytics: 500,000 - 1,000,000
- Mixed: 100,000 - 200,000

### Future Configuration

See `module.conf` for planned options in future releases.

---

**Version**: 1.0.0  
**Last Updated**: 2025-10-16
