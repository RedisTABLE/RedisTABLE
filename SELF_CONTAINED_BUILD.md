# Self-Contained Build System

## Overview

RedisTABLE now uses a **self-contained build system** following the RedisBloom approach. The module bundles `redismodule.h` in the repository, eliminating the need for external Redis source dependencies.

## What Changed?

### Before (Traditional Approach)
```bash
# Required specifying Redis source path every time
make build REDIS_SRC=/path/to/redis/src
```

**Problems:**
- ❌ Required Redis source to be available
- ❌ Had to specify path every build
- ❌ Different paths on different machines
- ❌ CI/CD configuration complexity

### After (Self-Contained Approach)
```bash
# Just works - no path needed!
make build
```

**Benefits:**
- ✅ No external Redis source required
- ✅ Works out of the box
- ✅ Portable across machines
- ✅ Simplified CI/CD
- ✅ Version-controlled API compatibility

## How It Works

### Directory Structure
```
RedisTABLE/
├── deps/
│   └── RedisModulesSDK/
│       ├── redismodule.h      ← Bundled Redis Module API
│       └── README.md
├── redis_table.c
├── Makefile
└── ...
```

### Makefile Configuration
```makefile
# Bundled SDK location
REDIS_MODULE_SDK := $(ROOT)/deps/RedisModulesSDK

# Use bundled SDK by default
REDIS_SRC ?= $(REDIS_MODULE_SDK)

# Compiler includes bundled header
CFLAGS += -I$(REDIS_SRC)
```

### Build Flow
```
1. make build
     ↓
2. Makefile sets: REDIS_SRC = deps/RedisModulesSDK
     ↓
3. Compiler flag: -I/path/to/RedisTABLE/deps/RedisModulesSDK
     ↓
4. redis_table.c: #include "redismodule.h"
     ↓
5. Compiler finds: deps/RedisModulesSDK/redismodule.h
     ↓
6. Build succeeds!
```

## Usage Examples

### Basic Build (No Configuration Needed!)
```bash
cd RedisTABLE
make build
```

That's it! No `REDIS_SRC` needed.

### Debug Build
```bash
make build DEBUG=1
```

### Verbose Build
```bash
make build VERBOSE=1
```

### Override with Custom Redis Source (Optional)
```bash
# Use a different redismodule.h if needed
make build REDIS_SRC=/path/to/redis/src
```

## Comparison with Other Redis Modules

| Module | Build System | SDK Bundled | Self-Contained |
|--------|--------------|-------------|----------------|
| **RedisBloom** | Makefile | ✅ Yes | ✅ Yes |
| **RedisJSON** | Cargo/Rust | ✅ Yes | ✅ Yes |
| **RedisTABLE** | Makefile | ✅ Yes | ✅ Yes |

RedisTABLE now follows the same pattern as official Redis modules!

## Advantages

### 1. **Developer Experience**
```bash
# Clone and build - that's it!
git clone <repo>
cd RedisTABLE
make build
```

No configuration, no hunting for Redis source paths.

### 2. **CI/CD Simplification**
```yaml
# GitHub Actions example
- name: Build module
  run: make build

# No need to:
# - Install Redis source
# - Configure paths
# - Set environment variables
```

### 3. **Portability**
The same command works on:
- ✅ Developer laptops
- ✅ CI/CD servers
- ✅ Docker containers
- ✅ Different Linux distributions
- ✅ macOS

### 4. **Version Control**
The bundled `redismodule.h` ensures:
- Consistent API version across builds
- No surprises from Redis version changes
- Reproducible builds

### 5. **Offline Builds**
Build without internet or external dependencies:
```bash
# Works even offline!
make build
```

## Updating the Bundled SDK

If you need to update to a newer Redis API version:

### Option 1: Copy from Local Redis
```bash
cp /path/to/redis/src/redismodule.h deps/RedisModulesSDK/
```

### Option 2: Download from GitHub
```bash
# Latest stable
wget https://raw.githubusercontent.com/redis/redis/7.2/src/redismodule.h \
     -O deps/RedisModulesSDK/redismodule.h

# Unstable (bleeding edge)
wget https://raw.githubusercontent.com/redis/redis/unstable/src/redismodule.h \
     -O deps/RedisModulesSDK/redismodule.h
```

### Option 3: Use curl
```bash
curl -o deps/RedisModulesSDK/redismodule.h \
     https://raw.githubusercontent.com/redis/redis/7.2/src/redismodule.h
```

## Backward Compatibility

The self-contained build maintains **full backward compatibility**:

### Old Way (Still Works)
```bash
make build REDIS_SRC=/path/to/redis/src
```

### New Way (Recommended)
```bash
make build
```

Both produce identical results!

## Testing Different Redis Versions

You can test compatibility with different Redis versions:

```bash
# Test with Redis 7.0
make build REDIS_SRC=/path/to/redis-7.0/src
make test

# Test with Redis 7.2
make build REDIS_SRC=/path/to/redis-7.2/src
make test

# Test with bundled version
make build
make test
```

## Troubleshooting

### Issue: "redismodule.h: No such file or directory"

**Cause**: The bundled SDK is missing.

**Solution**:
```bash
# Check if SDK exists
ls -la deps/RedisModulesSDK/redismodule.h

# If missing, copy it
mkdir -p deps/RedisModulesSDK
cp /path/to/redis/src/redismodule.h deps/RedisModulesSDK/
```

### Issue: Build works but module fails to load

**Cause**: API version mismatch between bundled header and Redis server.

**Solution**:
```bash
# Check Redis version
redis-server --version

# Update bundled header to match
wget https://raw.githubusercontent.com/redis/redis/7.2/src/redismodule.h \
     -O deps/RedisModulesSDK/redismodule.h

# Rebuild
make clean
make build
```

### Issue: Want to use latest Redis features

**Solution**: Override with unstable Redis source
```bash
make build REDIS_SRC=/path/to/redis-unstable/src
```

## Git Configuration

The bundled SDK should be committed to version control:

```gitignore
# .gitignore
# DO NOT ignore deps/RedisModulesSDK/
# It should be committed!

# But do ignore build artifacts
*.o
*.so
*.gcda
*.gcno
coverage/
```

## Docker Support

The self-contained build works perfectly in Docker:

```dockerfile
FROM ubuntu:22.04

# Install only build tools (no Redis source needed!)
RUN apt-get update && apt-get install -y \
    gcc \
    make \
    && rm -rf /var/lib/apt/lists/*

# Copy project
COPY . /app
WORKDIR /app

# Build (no configuration needed!)
RUN make build

# Done!
```

## Performance Impact

**None!** The bundled SDK approach:
- ✅ Same compilation speed
- ✅ Same binary size
- ✅ Same runtime performance
- ✅ Identical output to traditional build

The only difference is **convenience**.

## Migration Guide

### For Existing Builds

If you have existing build scripts:

**Before:**
```bash
#!/bin/bash
export REDIS_SRC=/usr/local/src/redis/src
make build REDIS_SRC=$REDIS_SRC
```

**After:**
```bash
#!/bin/bash
# Just this!
make build
```

### For CI/CD Pipelines

**Before:**
```yaml
- name: Setup Redis source
  run: |
    git clone https://github.com/redis/redis.git
    export REDIS_SRC=$(pwd)/redis/src
    
- name: Build module
  run: make build REDIS_SRC=$REDIS_SRC
```

**After:**
```yaml
- name: Build module
  run: make build
```

## Best Practices

1. **Keep SDK Updated**: Periodically update the bundled `redismodule.h` to latest stable Redis
2. **Test Compatibility**: Test with multiple Redis versions before release
3. **Document Version**: Note which Redis version the SDK is from in release notes
4. **Commit SDK**: Always commit `deps/RedisModulesSDK/` to git

## References

- [RedisBloom Build System](https://github.com/redisbloom/redisbloom)
- [Redis Modules Documentation](https://redis.io/docs/reference/modules/)
- [Redis Module API](https://redis.io/docs/reference/modules/modules-api-ref/)

## Summary

The self-contained build system makes RedisTABLE:
- ✅ **Easier to build** - No configuration needed
- ✅ **More portable** - Works anywhere
- ✅ **CI/CD friendly** - Simplified pipelines
- ✅ **Professional** - Follows Redis module best practices
- ✅ **Backward compatible** - Old build methods still work

Just run `make build` and it works! 🚀
