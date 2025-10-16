# RedisTABLE - Makefile Guide

**Version**: 1.0.0  
**Last Updated**: 2025-10-16

Complete guide to the RedisTABLE build system.

---

## Quick Reference

```bash
# Build
make build              # Build module
make clean              # Clean build artifacts
make rebuild            # Clean + build

# Test
make test               # Run all tests
make unit-tests         # Run unit tests only
make memory-tests       # Run memory leak tests
make client-tests       # Run client compatibility tests

# Development
make help               # Show all targets
make debug              # Build with debug symbols
```

---

## Build Targets

### make build

**Description**: Build the RedisTABLE module

**Usage**:
```bash
make build
```

**Output**: `redistable.so`

**Options**:
```bash
# Debug build
make build DEBUG=1

# Verbose output
make build VERBOSE=1

# Custom Redis source
make build REDIS_SRC=/path/to/redis/src
```

**What it does**:
1. Compiles `redis_table.c`
2. Links into shared library `redistable.so`
3. Uses bundled Redis SDK (no external dependencies)

### make clean

**Description**: Remove build artifacts

**Usage**:
```bash
make clean
```

**Removes**:
- `redistable.so`
- `*.o` object files
- Temporary files

**Options**:
```bash
# Clean everything including test artifacts
make clean ALL=1
```

### make rebuild

**Description**: Clean and build

**Usage**:
```bash
make rebuild
```

**Equivalent to**:
```bash
make clean && make build
```

---

## Test Targets

### make test

**Description**: Run all test suites

**Usage**:
```bash
make test
```

**Runs**:
1. Unit tests (93 tests)
2. Memory leak tests
3. Client compatibility tests (if dependencies available)

**Output**:
```
Running unit tests...
========================================
Passed: 93
Failed: 0
Total:  93
========================================
All tests passed!
```

### make unit-tests

**Description**: Run core functionality tests

**Usage**:
```bash
make unit-tests
```

**Tests**:
- Namespace management
- Table creation
- Data insertion
- Query operations
- Index management
- Edge cases

**Requirements**: None (self-contained)

### make memory-tests

**Description**: Run memory leak detection tests

**Usage**:
```bash
make memory-tests
```

**Tests**:
- Memory allocation
- Memory leaks
- Fragmentation
- Growth patterns

**Requirements**: None (self-contained)

### make client-tests

**Description**: Run client compatibility tests

**Usage**:
```bash
make client-tests
```

**Tests**:
- Python client (redis-py)
- Node.js client (node-redis)

**Requirements**:
- Python 3 with redis package
- Node.js with redis package

**Note**: Skips gracefully if dependencies not available

### make test-all

**Description**: Run all tests including optional ones

**Usage**:
```bash
make test-all
```

**Equivalent to**:
```bash
make test
```

---

## Build Options

### DEBUG

**Description**: Build with debug symbols

**Usage**:
```bash
make build DEBUG=1
```

**Effect**:
- Adds `-g` flag
- Includes debug symbols
- Enables debugging with gdb

**Example**:
```bash
# Build with debug
make build DEBUG=1

# Debug with gdb
gdb redis-server
(gdb) run --loadmodule ./redistable.so
```

### VERBOSE

**Description**: Show detailed build output

**Usage**:
```bash
make build VERBOSE=1
```

**Effect**:
- Shows full compiler commands
- Displays all flags
- Useful for troubleshooting

### REDIS_SRC

**Description**: Use custom Redis source

**Usage**:
```bash
make build REDIS_SRC=/path/to/redis/src
```

**Effect**:
- Uses specified `redismodule.h`
- Overrides bundled SDK
- Useful for testing compatibility

**Example**:
```bash
# Use Redis 7.2 headers
make build REDIS_SRC=/usr/local/redis-7.2/src

# Use development Redis
make build REDIS_SRC=~/redis/src
```

---

## Common Workflows

### Development Workflow

```bash
# 1. Make changes to redis_table.c
vim redis_table.c

# 2. Rebuild
make rebuild

# 3. Run tests
make test

# 4. Test manually
redis-server --loadmodule ./redistable.so
redis-cli TABLE.HELP
```

### Testing Workflow

```bash
# Run specific test suite
make unit-tests

# Run with verbose output
cd tests && ./run_tests.sh

# Run single test
cd tests && bash -x test_redis_table.sh
```

### Release Workflow

```bash
# 1. Clean build
make clean

# 2. Build release version
make build

# 3. Run all tests
make test

# 4. Verify module
file redistable.so
ls -lh redistable.so

# 5. Test loading
redis-server --loadmodule ./redistable.so --loglevel debug
```

### Debug Workflow

```bash
# 1. Build with debug symbols
make build DEBUG=1

# 2. Run Redis under gdb
gdb redis-server

# 3. Set breakpoints
(gdb) break RedisModule_OnLoad
(gdb) break TableInsert_RedisCommand

# 4. Run with module
(gdb) run --loadmodule ./redistable.so

# 5. Debug
(gdb) continue
(gdb) print variable
(gdb) backtrace
```

---

## Build System Details

### Compiler Flags

**Default**:
```makefile
CFLAGS = -fPIC -std=c99 -Wall -Wextra -O2
```

**With DEBUG=1**:
```makefile
CFLAGS = -fPIC -std=c99 -Wall -Wextra -g
```

**Flags explained**:
- `-fPIC`: Position-independent code (required for shared library)
- `-std=c99`: C99 standard
- `-Wall -Wextra`: Enable warnings
- `-O2`: Optimization level 2
- `-g`: Debug symbols

### Linker Flags

```makefile
LDFLAGS = -shared
```

**Flags explained**:
- `-shared`: Create shared library

### Dependencies

**Build Dependencies**:
- GCC or compatible C compiler
- Make
- Standard C library

**Runtime Dependencies**:
- Redis server (6.0+)

**Test Dependencies** (optional):
- Python 3 with redis package
- Node.js with redis package

---

## Makefile Structure

```makefile
# Variables
CC = gcc
CFLAGS = -fPIC -std=c99 -Wall -Wextra -O2
LDFLAGS = -shared
TARGET = redistable.so
SOURCE = redis_table.c

# Build targets
build: $(TARGET)

$(TARGET): $(SOURCE)
    $(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<

clean:
    rm -f $(TARGET) *.o

# Test targets
test: unit-tests memory-tests client-tests

unit-tests: build
    cd tests && ./run_tests.sh

memory-tests: build
    cd tests && ./test_memory_leaks.sh

client-tests: build
    cd tests && ./run_client_tests.sh

# Convenience targets
rebuild: clean build

help:
    @echo "Available targets:"
    @echo "  make build         - Build module"
    @echo "  make test          - Run all tests"
    @echo "  make clean         - Clean build"
```

---

## Troubleshooting

### Issue: Build Fails

```bash
# Check compiler
gcc --version

# Check make
make --version

# Try verbose build
make build VERBOSE=1

# Check for errors
make clean && make build 2>&1 | tee build.log
```

### Issue: Tests Fail

```bash
# Rebuild clean
make rebuild

# Run tests individually
make unit-tests
make memory-tests

# Check Redis is running
redis-cli PING

# Check module loads
redis-server --loadmodule ./redistable.so --loglevel debug
```

### Issue: Module Won't Load

```bash
# Check file exists
ls -lh redistable.so

# Check file type
file redistable.so
# Should show: ELF 64-bit LSO

# Check Redis version
redis-server --version
# Requires 6.0+

# Check Redis logs
tail -f /var/log/redis/redis-server.log
```

### Issue: Permission Denied

```bash
# Make executable
chmod +x redistable.so

# Check ownership
ls -l redistable.so

# Run as correct user
sudo redis-server --loadmodule ./redistable.so
```

---

## Advanced Usage

### Cross-Compilation

```bash
# For ARM
make build CC=arm-linux-gnueabihf-gcc

# For 32-bit
make build CFLAGS="-m32 -fPIC -std=c99 -Wall -Wextra -O2"
```

### Custom Optimization

```bash
# Maximum optimization
make build CFLAGS="-fPIC -std=c99 -O3 -march=native"

# Size optimization
make build CFLAGS="-fPIC -std=c99 -Os"

# No optimization (debug)
make build CFLAGS="-fPIC -std=c99 -O0 -g"
```

### Static Analysis

```bash
# With clang static analyzer
scan-build make build

# With cppcheck
cppcheck redis_table.c

# With valgrind (runtime)
valgrind redis-server --loadmodule ./redistable.so
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build module
        run: make build
      
      - name: Run tests
        run: make test
      
      - name: Upload artifact
        uses: actions/upload-artifact@v2
        with:
          name: redistable.so
          path: redistable.so
```

### GitLab CI

```yaml
build:
  stage: build
  script:
    - make build
  artifacts:
    paths:
      - redistable.so

test:
  stage: test
  script:
    - make test
  dependencies:
    - build
```

### Jenkins

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'make clean'
                sh 'make build'
            }
        }
        stage('Test') {
            steps {
                sh 'make test'
            }
        }
        stage('Archive') {
            steps {
                archiveArtifacts 'redistable.so'
            }
        }
    }
}
```

---

## Performance Optimization

### Build for Production

```bash
# Optimized build
make build CFLAGS="-fPIC -std=c99 -O3 -march=native -DNDEBUG"

# Strip symbols (smaller file)
strip redistable.so

# Check size
ls -lh redistable.so
```

### Profile-Guided Optimization

```bash
# 1. Build with profiling
make build CFLAGS="-fPIC -std=c99 -O2 -fprofile-generate"

# 2. Run representative workload
redis-server --loadmodule ./redistable.so
# ... run typical operations ...

# 3. Rebuild with profile data
make rebuild CFLAGS="-fPIC -std=c99 -O2 -fprofile-use"
```

---

## Best Practices

### 1. Always Clean Before Release

```bash
# Ensure clean build
make clean && make build
```

### 2. Run Tests Before Commit

```bash
# Verify changes
make rebuild && make test
```

### 3. Use Debug Build for Development

```bash
# Development
make build DEBUG=1

# Production
make build
```

### 4. Check Build Warnings

```bash
# Enable all warnings
make build CFLAGS="-fPIC -std=c99 -Wall -Wextra -Werror"
```

### 5. Verify Module After Build

```bash
# Check file
file redistable.so
ls -lh redistable.so

# Test load
redis-server --loadmodule ./redistable.so --loglevel debug
redis-cli MODULE LIST
```

---

## Summary

### Essential Commands

```bash
# Build
make build              # Build module
make rebuild            # Clean + build

# Test
make test               # Run all tests
make unit-tests         # Core tests only

# Clean
make clean              # Remove artifacts
```

### Build Options

```bash
DEBUG=1                 # Debug symbols
VERBOSE=1               # Verbose output
REDIS_SRC=/path         # Custom Redis headers
```

### Requirements

- GCC or compatible compiler
- Make
- Redis 6.0+ (runtime)

---

**Version**: 1.0.0  
**Last Updated**: 2025-10-16  
**Build System**: GNU Make
