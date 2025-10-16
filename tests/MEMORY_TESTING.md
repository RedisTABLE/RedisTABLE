# RedisTABLE - Memory Testing Guide

**Version**: 1.0.0  
**Last Updated**: 2025-10-16

Comprehensive guide to memory leak testing and validation for RedisTABLE.

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Test Suites](#test-suites)
4. [Memory Profiling](#memory-profiling)
5. [Interpreting Results](#interpreting-results)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)

---

## Overview

RedisTABLE uses `RedisModule_AutoMemory` for automatic memory management. This guide documents comprehensive memory testing procedures, tools, and best practices.

### Why Memory Testing?

- **Detect leaks** - Find memory that's allocated but never freed
- **Verify cleanup** - Ensure proper resource management
- **Monitor growth** - Track memory usage patterns
- **Prevent issues** - Catch problems before production

---

## Quick Start

### Run Memory Tests

```bash
# Using Makefile
make memory-tests

# Or directly
cd tests
./test_memory_leaks.sh
```

### Expected Output

```
========================================
Redis Table Module - Memory Leak Tests
========================================

Starting Redis server with table module...
Redis server started (PID: 12345)

Running memory leak tests...

Test 1: Namespace creation memory
  Before: 1.5 MB
  After:  1.6 MB
  Growth: 100 KB
✓ PASS: Memory growth acceptable (< 1 KB per namespace)

Test 2: Table creation memory
  Before: 1.6 MB
  After:  1.8 MB
  Growth: 200 KB
✓ PASS: Memory growth acceptable (< 2 KB per table)

... (10 tests total)

========================================
Memory Test Summary
========================================
Passed: 10
Failed: 0
Total:  10
========================================
All memory tests passed!

Stopping Redis server...
Redis server stopped
```

---

## Test Suites

### Suite 1: Basic Operations

#### Test 1: Namespace Creation

**Purpose**: Verify namespace creation doesn't leak memory

**Operations**:
```bash
for i in {1..100}; do
    redis-cli TABLE.NAMESPACE.CREATE ns_$i
done
```

**Expected**:
- Memory growth: < 1 KB per namespace
- Linear growth pattern
- No accumulation after deletion

**Pass Criteria**:
- Growth < 100 KB for 100 namespaces
- Memory freed after DROP NAMESPACE

#### Test 2: Table Creation

**Purpose**: Verify table schema creation doesn't leak

**Operations**:
```bash
for i in {1..100}; do
    redis-cli TABLE.SCHEMA.CREATE test.table_$i \
        id:integer:hash \
        name:string:none \
        age:integer:none
done
```

**Expected**:
- Memory growth: < 2 KB per table
- Proportional to schema complexity
- Freed on DROP TABLE

**Pass Criteria**:
- Growth < 200 KB for 100 tables
- Memory decreases after cleanup

#### Test 3: Data Insertion

**Purpose**: Verify INSERT operations don't leak

**Operations**:
```bash
for i in {1..1000}; do
    redis-cli TABLE.INSERT test.data \
        id=$i \
        name=user_$i \
        age=$((20 + i % 50))
done
```

**Expected**:
- Memory growth: ~100-200 bytes per row
- Linear with data size
- Includes index overhead

**Pass Criteria**:
- Growth ~100-200 KB for 1000 rows
- Consistent per-row overhead

### Suite 2: Query Operations

#### Test 4: SELECT Queries

**Purpose**: Verify queries don't leak memory

**Operations**:
```bash
for i in {1..1000}; do
    redis-cli TABLE.SELECT test.data WHERE id=$i
done
```

**Expected**:
- Minimal memory growth (< 100 bytes per 1000 queries)
- Memory stable after queries
- No accumulation

**Pass Criteria**:
- Growth < 1 KB for 1000 queries
- Memory returns to baseline

#### Test 5: Complex Queries

**Purpose**: Verify complex WHERE clauses don't leak

**Operations**:
```bash
for i in {1..500}; do
    redis-cli TABLE.SELECT test.data WHERE age>$((20 + i % 50)) AND name=user_$i
done
```

**Expected**:
- Similar to simple queries
- No additional leaks from complex conditions

**Pass Criteria**:
- Growth < 1 KB for 500 queries
- Stable memory

### Suite 3: Update Operations

#### Test 6: UPDATE Operations

**Purpose**: Verify updates properly free old values

**Operations**:
```bash
for i in {1..1000}; do
    redis-cli TABLE.UPDATE test.data WHERE id=$i SET age=$((30 + i % 50))
done
```

**Expected**:
- Minimal growth (old values freed)
- < 1 KB per 1000 updates
- Index updates handled correctly

**Pass Criteria**:
- Growth < 2 KB for 1000 updates
- Old values freed

### Suite 4: Delete Operations

#### Test 7: DELETE Operations

**Purpose**: Verify deletes free memory

**Operations**:
```bash
for i in {1..1000}; do
    redis-cli TABLE.DELETE test.data WHERE id=$i
done
```

**Expected**:
- Memory decreases
- Rows and indexes freed
- Proportional to deleted data

**Pass Criteria**:
- Memory decreases by ~80-90% of insertion growth
- Indexes cleaned up

### Suite 5: Index Operations

#### Test 8: Index Creation

**Purpose**: Verify index creation memory usage

**Operations**:
```bash
redis-cli TABLE.SCHEMA.ALTER test.data ADD INDEX age:hash
```

**Expected**:
- Growth proportional to unique values
- ~100 bytes per unique value
- One-time cost

**Pass Criteria**:
- Growth matches expected (unique_values * 100 bytes)
- Stable after creation

#### Test 9: Index Deletion

**Purpose**: Verify index deletion frees memory

**Operations**:
```bash
redis-cli TABLE.SCHEMA.ALTER test.data DROP INDEX age
```

**Expected**:
- Memory decreases
- Index keys deleted
- Proportional to index size

**Pass Criteria**:
- Memory decreases by ~80-90% of index creation growth
- All index keys removed

### Suite 6: Stress Testing

#### Test 10: Mixed Operations Stress Test

**Purpose**: Verify no leaks under mixed workload

**Operations**:
```bash
for i in {1..5000}; do
    redis-cli TABLE.INSERT test.stress id=$i value=data_$i
    redis-cli TABLE.SELECT test.stress WHERE id=$i
    redis-cli TABLE.UPDATE test.stress WHERE id=$i SET value=updated_$i
    redis-cli TABLE.DELETE test.stress WHERE id=$i
done
```

**Expected**:
- Stable memory (no net growth)
- Allocations balanced by frees
- No accumulation

**Pass Criteria**:
- Net growth < 5 KB for 5000 cycles
- Memory stable throughout

---

## Memory Profiling

### Using Redis INFO

```bash
# Get memory snapshot
redis-cli INFO memory > memory_snapshot.txt

# Key metrics
redis-cli INFO memory | grep used_memory_human
redis-cli INFO memory | grep used_memory_peak_human
redis-cli INFO memory | grep mem_fragmentation_ratio
redis-cli INFO memory | grep used_memory_rss_human
```

### Using MEMORY Commands

```bash
# Memory statistics
redis-cli MEMORY STATS

# Memory usage of specific key
redis-cli MEMORY USAGE "schema:myapp.users"

# Memory doctor (diagnostics)
redis-cli MEMORY DOCTOR

# Memory purge (defragment)
redis-cli MEMORY PURGE
```

### Using Valgrind

```bash
# Install valgrind
sudo apt-get install valgrind

# Run Redis under valgrind
valgrind \
    --leak-check=full \
    --show-leak-kinds=all \
    --track-origins=yes \
    --verbose \
    --log-file=valgrind-out.txt \
    redis-server --loadmodule ./redistable.so

# Run operations
redis-cli TABLE.NAMESPACE.CREATE test
redis-cli TABLE.SCHEMA.CREATE test.users id:integer:hash
redis-cli TABLE.INSERT test.users id=1 name=Test
redis-cli TABLE.SELECT test.users
redis-cli TABLE.DELETE test.users WHERE id=1
redis-cli TABLE.SCHEMA.DROP test.users FORCE
redis-cli TABLE.NAMESPACE.DROP test FORCE

# Shutdown and check report
redis-cli SHUTDOWN
cat valgrind-out.txt
```

### Using Massif (Heap Profiler)

```bash
# Run with massif
valgrind --tool=massif redis-server --loadmodule ./redistable.so

# Run workload
redis-cli < workload.txt

# Shutdown
redis-cli SHUTDOWN

# Analyze results
ms_print massif.out.<pid>
```

---

## Interpreting Results

### Memory Growth Patterns

#### Acceptable Growth

✅ **Linear growth** - Proportional to data
```
Rows: 1K   → Memory: 10 MB
Rows: 10K  → Memory: 100 MB
Rows: 100K → Memory: 1 GB
```

✅ **Stable queries** - No growth from queries
```
Before queries: 100 MB
After 10K queries: 100 MB
Growth: 0 MB ✓
```

✅ **Decreasing deletes** - Memory freed
```
Before deletes: 100 MB
After deleting 50%: 50 MB
Freed: 50 MB ✓
```

#### Problematic Growth

❌ **Continuous growth** - Possible leak
```
Iteration 1: 100 MB
Iteration 2: 110 MB
Iteration 3: 120 MB
Iteration 4: 130 MB
Growth: 10 MB per iteration ✗
```

❌ **Query accumulation** - Memory leak
```
Before queries: 100 MB
After 1K queries: 105 MB
After 2K queries: 110 MB
After 3K queries: 115 MB
Growth: 5 MB per 1K queries ✗
```

❌ **No cleanup** - Memory not freed
```
Before deletes: 100 MB
After deleting all: 95 MB
Freed: 5 MB (expected 90+ MB) ✗
```

### Fragmentation Ratio

```bash
# Check fragmentation
redis-cli INFO memory | grep mem_fragmentation_ratio
```

**Interpretation**:
- **< 1.0**: Memory swapping (bad)
- **1.0 - 1.5**: Healthy (good)
- **1.5 - 2.0**: Acceptable (monitor)
- **2.0 - 5.0**: High fragmentation (consider MEMORY PURGE)
- **> 5.0**: Critical (investigate)

### Valgrind Output

**Look for**:
```
==12345== LEAK SUMMARY:
==12345==    definitely lost: 0 bytes in 0 blocks
==12345==    indirectly lost: 0 bytes in 0 blocks
==12345==      possibly lost: 0 bytes in 0 blocks
==12345==    still reachable: X bytes in Y blocks
==12345==         suppressed: 0 bytes in 0 blocks
```

✅ **Good**: definitely/indirectly lost = 0  
⚠️ **Warning**: possibly lost > 0  
❌ **Bad**: definitely lost > 0

---

## Troubleshooting

### Issue: High Memory Growth

**Symptoms**:
- Memory grows faster than expected
- Growth doesn't stabilize

**Diagnosis**:
```bash
# Check what's using memory
redis-cli --bigkeys

# Check key count
redis-cli DBSIZE

# Check memory breakdown
redis-cli MEMORY STATS
```

**Solutions**:
1. Check for index explosion (too many unique values)
2. Verify data is being deleted
3. Check for fragmentation
4. Run MEMORY PURGE

### Issue: Memory Not Freed

**Symptoms**:
- DELETE doesn't reduce memory
- Memory stays high after cleanup

**Diagnosis**:
```bash
# Check if keys still exist
redis-cli KEYS "row:*" | wc -l
redis-cli KEYS "idx:*" | wc -l

# Check fragmentation
redis-cli INFO memory | grep mem_fragmentation_ratio
```

**Solutions**:
1. Force memory reclaim: `redis-cli MEMORY PURGE`
2. Restart Redis (last resort)
3. Check for dangling references

### Issue: Fragmentation

**Symptoms**:
- High mem_fragmentation_ratio (> 2.0)
- RSS memory much higher than used_memory

**Diagnosis**:
```bash
# Check fragmentation
redis-cli INFO memory | grep fragmentation

# Check allocator
redis-cli INFO memory | grep mem_allocator
```

**Solutions**:
```bash
# Defragment
redis-cli MEMORY PURGE

# Or enable active defrag (Redis 4.0+)
redis-cli CONFIG SET activedefrag yes
```

### Issue: Valgrind Reports Leaks

**Symptoms**:
- "definitely lost" > 0
- "indirectly lost" > 0

**Diagnosis**:
```bash
# Run with full details
valgrind --leak-check=full --show-leak-kinds=all \
    redis-server --loadmodule ./redistable.so

# Check backtrace in valgrind output
```

**Solutions**:
1. Review code for manual allocations
2. Ensure RedisModule_AutoMemory is used
3. Check for missing frees in error paths
4. Report bug if leak is in module code

---

## Best Practices

### 1. Test Regularly

```bash
# Before each commit
make memory-tests

# Before each release
make memory-tests && echo "Memory tests passed"
```

### 2. Monitor Production

```bash
#!/bin/bash
# monitor_memory.sh

while true; do
    MEMORY=$(redis-cli INFO memory | grep used_memory_human | cut -d: -f2)
    FRAG=$(redis-cli INFO memory | grep mem_fragmentation_ratio | cut -d: -f2)
    PEAK=$(redis-cli INFO memory | grep used_memory_peak_human | cut -d: -f2)
    
    echo "$(date): Memory=$MEMORY, Peak=$PEAK, Frag=$FRAG"
    
    # Alert if high
    if (( $(echo "$FRAG > 2.0" | bc -l) )); then
        echo "WARNING: High fragmentation!"
    fi
    
    sleep 60
done
```

### 3. Set Limits

```bash
# Set maxmemory
redis-server --maxmemory 4gb --maxmemory-policy allkeys-lru

# Monitor against limit
redis-cli INFO memory | grep maxmemory
```

### 4. Profile Before Optimizing

```bash
# Baseline
redis-cli INFO memory > baseline.txt

# Run workload
# ...

# Compare
redis-cli INFO memory > after.txt
diff baseline.txt after.txt
```

### 5. Use Appropriate Tools

| Tool | Use Case |
|------|----------|
| `INFO memory` | Quick checks, monitoring |
| `MEMORY STATS` | Detailed breakdown |
| `Valgrind` | Leak detection |
| `Massif` | Heap profiling |
| `--bigkeys` | Find large keys |

---

## Summary

### Test Coverage

- ✅ Namespace operations
- ✅ Table operations
- ✅ Data operations (INSERT, SELECT, UPDATE, DELETE)
- ✅ Index operations
- ✅ Query operations
- ✅ Stress testing

### Memory Safety

- ✅ Uses RedisModule_AutoMemory
- ✅ No manual memory management
- ✅ Automatic cleanup on errors
- ✅ No known memory leaks

### Recommendations

1. **Run tests before release** - Catch regressions early
2. **Monitor production** - Track memory usage
3. **Set appropriate limits** - Use maxmemory
4. **Profile regularly** - Understand patterns
5. **Use valgrind** - Verify no leaks

---

**Version**: 1.0.0  
**Last Updated**: 2025-10-16  
**Test Coverage**: 10 memory leak scenarios, 5 profiler tests  
**Status**: Production-ready with monitoring recommendations
