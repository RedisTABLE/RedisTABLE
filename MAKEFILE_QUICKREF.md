# RedisTABLE Makefile Quick Reference

## Essential Commands

### Build
```bash
# Default build (optimized, no debug symbols)
make

# Debug build (with symbols, no optimization)
make DEBUG=1

# Verbose build (show full commands)
make VERBOSE=1

# With custom Redis source path
make REDIS_SRC=/path/to/redis/src
```

### Clean
```bash
# Clean build artifacts
make clean

# Clean everything (including coverage)
make clean ALL=1
```

### Test
```bash
# Run unit tests
make test

# Run all tests (unit + client + memory)
make test-all

# Run specific test suites
make unit-tests
make test-clients
make test-memory
```

### Run
```bash
# Start Redis with module
make run

# Start with GDB debugger
make run GDB=1

# Start with Valgrind
make run VALGRIND=1
```

### Development
```bash
# Show help
make help

# Build with debug info and show instructions
make debug

# Format code (requires clang-format)
make format

# Run linter (requires cppcheck)
make lint
```

### Coverage
```bash
# Generate coverage report
make coverage

# View coverage in browser
make show-cov
```

### Install
```bash
# Install to /usr/local/lib/redis/modules/
sudo make install

# Install to custom location
sudo make install PREFIX=/opt/redis
```

## Build Flags

| Flag | Description | Example |
|------|-------------|---------|
| `DEBUG=1` | Build with debug symbols, no optimization | `make DEBUG=1` |
| `PROFILE=1` | Build with profiling support | `make PROFILE=1` |
| `COV=1` | Build with coverage instrumentation | `make COV=1` |
| `VERBOSE=1` | Show full compiler commands | `make VERBOSE=1` |

## Path Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_SRC` | `../../src` | Path to Redis source directory |
| `REDIS_SERVER` | `redis-server` | Redis server binary |
| `PREFIX` | `/usr/local` | Installation prefix |

## Common Workflows

### Development Workflow
```bash
# 1. Build with debug symbols
make clean
make DEBUG=1 REDIS_SRC=/path/to/redis/src

# 2. Run tests
make test

# 3. Run Redis with module
make run
```

### Debug Workflow
```bash
# 1. Build with debug
make DEBUG=1 REDIS_SRC=/path/to/redis/src

# 2. Run with GDB
make run GDB=1
```

### Coverage Workflow
```bash
# 1. Generate coverage
make coverage REDIS_SRC=/path/to/redis/src

# 2. View report
make show-cov
```

### Release Workflow
```bash
# 1. Clean everything
make clean ALL=1

# 2. Build optimized
make REDIS_SRC=/path/to/redis/src

# 3. Run all tests
make test-all

# 4. Install
sudo make install
```

## Targets Reference

### Build Targets
- `build` - Build the module (default)
- `all` - Same as build
- `clean` - Remove build artifacts

### Test Targets
- `test` - Run unit tests
- `unit-tests` - Run unit tests (alias)
- `flow-tests` - Run flow tests (alias for unit-tests)
- `test-clients` - Run client compatibility tests
- `test-memory` - Run memory leak detection
- `test-memory-profiler` - Run memory profiler
- `test-all` - Run all tests

### Development Targets
- `run` - Run Redis with module
- `debug` - Show debug instructions
- `setup` - Install build dependencies

### Quality Targets
- `format` - Format source code
- `lint` - Run static analysis
- `coverage` - Generate coverage report
- `show-cov` - View coverage in browser

### Installation Targets
- `install` - Install module to system

### Help Target
- `help` - Show detailed help

## Output Files

| File | Description |
|------|-------------|
| `redistable.so` | Module shared library |
| `redis_table.o` | Object file |
| `*.gcda`, `*.gcno` | Coverage data files (when COV=1) |
| `coverage/` | Coverage reports directory |

## Examples

### Example 1: Quick Build and Test
```bash
cd /home/ubuntu/Projects/REDIS/RedisTABLE
make REDIS_SRC=/home/ubuntu/Projects/REDIS/redis/src
make test
```

### Example 2: Debug a Crash
```bash
make clean
make DEBUG=1 REDIS_SRC=/home/ubuntu/Projects/REDIS/redis/src
make run GDB=1
```

### Example 3: Check Code Coverage
```bash
make coverage REDIS_SRC=/home/ubuntu/Projects/REDIS/redis/src
make show-cov
```

### Example 4: Memory Leak Detection
```bash
make REDIS_SRC=/home/ubuntu/Projects/REDIS/redis/src
make test-memory
```

### Example 5: Production Build
```bash
make clean ALL=1
make REDIS_SRC=/home/ubuntu/Projects/REDIS/redis/src
make test-all
sudo make install PREFIX=/usr/local
```

## Troubleshooting

### Error: "redismodule.h: No such file or directory"
**Solution**: Specify correct Redis source path
```bash
make REDIS_SRC=/path/to/redis/src
```

### Error: Module fails to load
**Solution**: Check Redis version compatibility
```bash
redis-server --version
```

### Error: Tests fail with "Address already in use"
**Solution**: Stop existing Redis instances
```bash
pkill redis-server
make test
```

### Error: Permission denied during install
**Solution**: Use sudo
```bash
sudo make install
```

## Tips

1. **Set REDIS_SRC once**: Export it in your shell
   ```bash
   export REDIS_SRC=/home/ubuntu/Projects/REDIS/redis/src
   make
   ```

2. **Use DEBUG=1 during development**: Better error messages
   ```bash
   make DEBUG=1
   ```

3. **Run test-all before commits**: Ensure everything works
   ```bash
   make test-all
   ```

4. **Check coverage regularly**: Maintain code quality
   ```bash
   make coverage
   ```

5. **Use VERBOSE=1 for build issues**: See full commands
   ```bash
   make VERBOSE=1
   ```

## Getting Help

```bash
# Show detailed help
make help

# Show this quick reference
cat MAKEFILE_QUICKREF.md

# Show full guide
cat MAKEFILE_GUIDE.md

# Show changes from old Makefile
cat MAKEFILE_CHANGES.md
```
